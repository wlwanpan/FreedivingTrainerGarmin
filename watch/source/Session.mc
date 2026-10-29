import Toybox.Application.Storage;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.Test;
import Toybox.Timer;
import Toybox.WatchUi;

class SessionController {
    var comm as CommLink?;
    var running as Boolean = false;
    var paused as Boolean = false;
    var finished as Boolean = false;
    var finishing as Boolean = false;
    var locked as Boolean = false;
    var planComplete as Boolean = false;
    var phoneTraining as Boolean = false;
    var phoneTrainingName as String = "";
    var pendingSync as Boolean = false;
    var awaitingPhone as Boolean = false;
    var lostNotice as String = "";
    var page as Number = PAGE_PLAN;
    var screen as Number = 0;

    var plan as Dictionary?;
    var co2Table as Dictionary?;
    var o2Table as Dictionary?;
    var active as Dictionary?;
    var phases as Array<Dictionary>;
    var samples as Array<Dictionary>;
    var pending as Array<Dictionary>;

    var phaseTitle as String = "";
    var remaining as Number = 0;
    var bpm as Number = 0;
    var roundText as String = "";
    var planKey as String = "";
    var loggedCount as Number = -1;

    var startedAt as Number = 0;
    var wallStartedAt as Number = 0;
    var pausedAt as Number = 0;
    var lastHrAt as Number = 0;
    var lastHrBpm as Number = 0;
    var lastPulseAt as Number = 0;
    var captureSamples as Boolean = false;
    var hapticEnabled as Boolean = true;
    var soundEnabled as Boolean = true;

    var ticker as Timer.Timer?;
    var readyTicker as Timer.Timer?;
    var readyUpdatedAt as Number = 0;
    var readyDelivered as Boolean = false;
    var viewKind as Number = 0;

    function initialize() {
        phases = [] as Array<Dictionary>;
        samples = [] as Array<Dictionary>;
        pending = [] as Array<Dictionary>;
        co2Table = defaultCo2Table();
        o2Table = defaultO2Table();
    }

    function setComm(link as CommLink) as Void {
        comm = link;
    }

    function restore() as Void {
        var language = Storage.getValue(STORAGE_LANGUAGE);
        if (language instanceof String) {
            setLanguage(language as String);
        }
        var haptic = Storage.getValue(STORAGE_HAPTIC);
        if (haptic instanceof Boolean) {
            hapticEnabled = haptic as Boolean;
        }
        var sound = Storage.getValue(STORAGE_SOUND);
        if (sound instanceof Boolean) {
            soundEnabled = sound as Boolean;
        }
        var storedKey = Storage.getValue(STORAGE_PLAN_KEY);
        if (storedKey instanceof String) {
            planKey = storedKey as String;
        }
        var storedLocked = Storage.getValue(STORAGE_LOCKED);
        if (storedLocked instanceof Boolean) {
            locked = storedLocked as Boolean;
        }
        var storedComplete = Storage.getValue(STORAGE_PLAN_COMPLETE);
        if (storedComplete instanceof Boolean) {
            planComplete = storedComplete as Boolean;
        }
        var storedCount = Storage.getValue(STORAGE_LOGGED_COUNT);
        if (storedCount instanceof Number) {
            loggedCount = storedCount as Number;
        }
        var storedPlan = Storage.getValue(STORAGE_PLAN);
        if (storedPlan instanceof Dictionary) {
            var loaded = storedPlan as Dictionary;
            if (roundCount(loaded) > 0) {
                plan = loaded;
            }
        }
        loadPending();
    }

    function persist() as Void {
        Storage.setValue(STORAGE_LANGUAGE, gLanguage);
        Storage.setValue(STORAGE_HAPTIC, hapticEnabled);
        Storage.setValue(STORAGE_SOUND, soundEnabled);
        savePlanSnapshot();
        savePending();
    }

    function savePlanSnapshot() as Void {
        Storage.setValue(STORAGE_PLAN_KEY, planKey);
        Storage.setValue(STORAGE_LOCKED, locked);
        Storage.setValue(STORAGE_PLAN_COMPLETE, planComplete);
        Storage.setValue(STORAGE_LOGGED_COUNT, loggedCount);
        if (plan != null) {
            Storage.setValue(STORAGE_PLAN, plan as Dictionary);
        } else {
            Storage.deleteValue(STORAGE_PLAN);
        }
    }

    function handlePhone(message as Dictionary) as Void {
        acknowledgeList(message.get("syncedAt"));
        var type = asTextOr(message.get("type"), "");
        if (type.equals(TYPE_ACK)) {
            var id = asInt(message.get("completedAt"), 0);
            if (id > 0) {
                removePending(id);
            }
            return;
        }

        // A live table is owned by the watch. Phone updates may refresh the
        // next-session snapshot, but they must never pause, cancel, or replace it.
        if (running) {
            if (type.equals(TYPE_PHONE_TRAINING)) {
                applyPhoneTraining(message);
                return;
            }
            if (type.equals(TYPE_NEXT_SESSION)) {
                applyPlan(message);
                flushPending();
            }
            return;
        }

        applyPhonePreferences(message);
        if (type.equals(TYPE_PHONE_TRAINING)) {
            applyPhoneTraining(message);
            return;
        }
        if (type.equals(TYPE_NEXT_SESSION)) {
            applyPlan(message);
            flushPending();
            return;
        }
        applyPhoneTraining(message);
        flushPending();
    }

    function applyPhonePreferences(message as Dictionary) as Void {
        var language = asText(message.get("language"));
        if (language != null) {
            setLanguage(language);
            Storage.setValue(STORAGE_LANGUAGE, gLanguage);
        }
        if (message.get("trainingHaptic") != null) {
            hapticEnabled = asFlag(message.get("trainingHaptic"));
            Storage.setValue(STORAGE_HAPTIC, hapticEnabled);
        }
        if (message.get("trainingSound") != null) {
            soundEnabled = asFlag(message.get("trainingSound"));
            Storage.setValue(STORAGE_SOUND, soundEnabled);
        }
    }

    function applyPhoneTraining(message as Dictionary) as Void {
        var record = asDict(message.get("phoneTraining"));
        if (record == null && asTextOr(message.get("type"), "").equals(TYPE_PHONE_TRAINING)) {
            record = message;
        }
        if (record == null) {
            return;
        }
        var active = asFlag(record.get("running"));
        phoneTraining = active;
        if (!active) {
            phoneTrainingName = "";
        } else {
            var name = asText(record.get("name"));
            if (name != null) {
                phoneTrainingName = name as String;
            }
        }
        WatchUi.requestUpdate();
    }

    function applyPlan(message as Dictionary) as Void {
        applyPhoneTraining(message);
        installTables(message);
        var key = asTextOr(message.get("planKey"), "");
        var changed = !key.equals(planKey);
        var count = asInt(message.get("loggedCount"), loggedCount);
        var logged = count != loggedCount;
        if (logged) {
            loggedCount = count;
        }
        if (running) {
            if (changed) {
                planKey = key;
            }
            installPlan(message);
            return;
        }
        if (changed) {
            planKey = key;
            finished = false;
        }
        if (logged) {
            finished = false;
        }
        installPlan(message);
        WatchUi.requestUpdate();
    }

    function installTables(message as Dictionary) as Void {
        var tables = asDict(message.get("tables"));
        if (tables == null) {
            return;
        }
        var breathe = asInt(tables.get("breatheUpSeconds"), DEFAULT_BREATHE_UP);
        var co2 = parseTable(tables.get("co2"), breathe, "CO2", "co2");
        var o2 = parseTable(tables.get("o2"), breathe, "O2", "o2");
        if (co2 != null) {
            co2Table = co2;
        }
        if (o2 != null) {
            o2Table = o2;
        }
    }

    function installPlan(message as Dictionary) as Void {
        if (asFlag(message.get("locked"))) {
            locked = true;
            planComplete = false;
            plan = null;
        } else if (asFlag(message.get("complete"))) {
            locked = false;
            planComplete = true;
            finished = false;
            plan = null;
        } else {
            locked = false;
            planComplete = false;
            plan = parsePlan(message);
        }
        savePlanSnapshot();
        // A tables-only nextSession has no slot, so plan stays null. Stop asking anyway.
        stopReadyPulse();
        readyUpdatedAt = 0;
        readyDelivered = false;
    }

    function canStart() as Boolean {
        return !running && !locked && !(phoneTraining && phoneConnected());
    }

    function phoneConnected() as Boolean {
        if (comm != null) {
            return (comm as CommLink).phoneLikelyReachable();
        }
        return false;
    }

    // Queued completions stay on the watch until the phone ACKs. That queue
    // does not block training. The corner spinner is on while a transfer is
    // in flight, or after a sessionComplete transmit until the phone ACKs.
    function syncInProgress() as Boolean {
        if (comm != null && (comm as CommLink).busy) {
            return true;
        }
        return pendingSync && awaitingPhone;
    }

    function onTransmitFinished(ok as Boolean, payload as Dictionary?) as Void {
        var type = "";
        if (payload != null) {
            type = asTextOr((payload as Dictionary).get("type"), "");
        }
        if (ok && pendingSync && type.equals(TYPE_SESSION_COMPLETE)) {
            awaitingPhone = true;
        }
        if (ok && type.equals(TYPE_WATCH_READY)) {
            readyDelivered = true;
            stopReadyPulse();
        }
        onTransmitOk();
    }

    function startPlan() as Boolean {
        if (plan == null) {
            return false;
        }
        return startTable(plan as Dictionary);
    }

    function startCo2() as Boolean {
        if (co2Table == null) {
            return false;
        }
        return startTable(co2Table as Dictionary);
    }

    function startO2() as Boolean {
        if (o2Table == null) {
            return false;
        }
        return startTable(o2Table as Dictionary);
    }

    function startTable(table as Dictionary) as Boolean {
        if (!canStart()) {
            return false;
        }
        var built = makePhases(table);
        if (built.size() == 0) {
            return false;
        }
        active = table;
        phases = built;
        wallStartedAt = nowSec();
        startedAt = wallStartedAt;
        samples = [] as Array<Dictionary>;
        captureSamples = true;
        finishing = false;
        finished = false;
        paused = false;
        pausedAt = 0;
        running = true;
        lostNotice = "";
        phaseTitle = "";
        remaining = 0;
        stopReadyPulse();
        startHeartRate();
        startClock();
        advance();
        publishTraining();
        showSession();
        return true;
    }

    function togglePause() as Void {
        if (!running || finishing) {
            return;
        }
        if (paused) {
            if (pausedAt > 0) {
                startedAt += nowSec() - pausedAt;
            }
            pausedAt = 0;
            paused = false;
            startClock();
            advance();
            publishTraining();
            return;
        }
        pausedAt = nowSec();
        paused = true;
        stopClock();
        publishTraining();
        WatchUi.requestUpdate();
    }

    function abort(notify as Boolean) as Void {
        stopClock();
        stopHeartRate();
        running = false;
        paused = false;
        finishing = false;
        finished = false;
        captureSamples = false;
        phaseTitle = "";
        roundText = "";
        remaining = 0;
        samples = [] as Array<Dictionary>;
        active = null;
        phases = [] as Array<Dictionary>;
        if (notify) {
            publishTraining();
        }
    }

    function exitSession() as Void {
        abort(true);
        showHome();
    }

    function dismissSaved() as Void {
        finished = false;
        showHome();
    }

    function onTick() as Void {
        advance();
    }

    function advance() as Void {
        if (!running || paused || finishing) {
            return;
        }
        var elapsed = nowSec() - startedAt;
        var cursor = elapsed;
        for (var i = 0; i < phases.size(); i++) {
            var phase = phases[i] as Dictionary;
            var seconds = asInt(phase.get("seconds"), 0);
            if (cursor < seconds) {
                remaining = seconds - cursor;
                var title = asTextOr(phase.get("title"), "");
                if (!title.equals(phaseTitle)) {
                    if (phaseTitle.length() > 0) {
                        playFeedback(false);
                    }
                    phaseTitle = title;
                    publishTraining();
                }
                var round = asInt(phase.get("round"), 0);
                if (round > 0 && active != null) {
                    roundText = roundOf(round, roundCount(active as Dictionary));
                } else {
                    roundText = tr("breatheUp");
                }
                WatchUi.requestUpdate();
                pulseTraining();
                return;
            }
            cursor -= seconds;
        }
        finishSession();
    }

    function finishSession() as Void {
        if (!running || finishing) {
            return;
        }
        finishing = true;
        stopClock();
        paused = false;
        running = false;
        finished = true;
        phaseTitle = "";
        roundText = "";
        remaining = 0;
        sendCompletion();
        captureSamples = false;
        stopHeartRate();
        playFeedback(true);
        publishTraining();
        showDone();
    }

    function sendCompletion() as Void {
        if (active == null) {
            return;
        }
        var payload = buildCompletion(active as Dictionary, wallStartedAt, nowSec(), samples);
        storePending(payload);
        if (comm != null) {
            (comm as CommLink).sendNow(payload);
        }
    }

    function publishTraining() as Void {
        if (comm == null) {
            return;
        }
        var name = "";
        if (active != null) {
            name = asTextOr((active as Dictionary).get("name"), "");
        }
        var payload = buildWatchTraining(running, paused, name, phaseTitle, pending.size(), wallStartedAt);
        (comm as CommLink).send(payload);
        lastPulseAt = nowSec();
    }

    function pulseTraining() as Void {
        if (!running) {
            return;
        }
        if (nowSec() - lastPulseAt >= TRAINING_PULSE_SEC) {
            publishTraining();
        }
    }

    function onTransmitOk() as Void {
        WatchUi.requestUpdate();
    }

    function startClock() as Void {
        stopClock();
        ticker = new Timer.Timer();
        (ticker as Timer.Timer).start(method(:onTick), TICK_MS, true);
    }

    function stopClock() as Void {
        if (ticker != null) {
            (ticker as Timer.Timer).stop();
            ticker = null;
        }
    }

    function startHeartRate() as Void {
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        Sensor.enableSensorEvents(method(:onSensor));
    }

    function stopHeartRate() as Void {
        Sensor.enableSensorEvents(null);
        Sensor.setEnabledSensors([]);
        bpm = 0;
    }

    function onSensor(info as Sensor.Info) as Void {
        if (info.heartRate == null) {
            return;
        }
        var value = info.heartRate as Number;
        if (value < 30 || value > 230) {
            return;
        }
        bpm = value;
        var at = nowSec();
        if (value == lastHrBpm && at - lastHrAt < 5) {
            WatchUi.requestUpdate();
            return;
        }
        if (at - lastHrAt < HR_MIN_GAP_SEC && lastHrAt > 0) {
            WatchUi.requestUpdate();
            return;
        }
        lastHrBpm = value;
        lastHrAt = at;
        if (captureSamples) {
            addSample(value, at);
        }
        if (comm != null && running) {
            (comm as CommLink).send(buildHeartRate(value, at));
        }
        WatchUi.requestUpdate();
    }

    function addSample(value as Number, at as Number) as Void {
        if (samples.size() >= MAX_HR_SAMPLES) {
            var compact = [] as Array<Dictionary>;
            for (var i = 0; i < samples.size(); i += 2) {
                compact.add(samples[i]);
            }
            samples = compact;
        }
        samples.add({
            "bpm" => value,
            "at" => at
        });
    }

    function playFeedback(complete as Boolean) as Void {
        if (!(hapticEnabled || soundEnabled)) {
            return;
        }
        if (hapticEnabled && Attention has :vibrate) {
            var strength = complete ? 100 : 50;
            var duration = complete ? 800 : 400;
            Attention.vibrate([new Attention.VibeProfile(strength, duration)]);
        }
        if (soundEnabled && Attention has :playTone) {
            if (complete) {
                Attention.playTone(Attention.TONE_SUCCESS);
            } else {
                Attention.playTone(Attention.TONE_INTERVAL_ALERT);
            }
        }
    }

    function loadPending() as Void {
        var stored = Storage.getValue(STORAGE_PENDING);
        var loaded = [] as Array<Dictionary>;
        if (stored instanceof Array) {
            var rows = stored as Array;
            for (var i = 0; i < rows.size(); i++) {
                if (rows[i] instanceof Dictionary) {
                    loaded.add(rows[i] as Dictionary);
                }
            }
        }
        pending = loaded;
        pendingSync = pending.size() > 0;
    }

    function savePending() as Void {
        Storage.setValue(STORAGE_PENDING, pending);
        pendingSync = pending.size() > 0;
        if (!pendingSync) {
            awaitingPhone = false;
        }
        WatchUi.requestUpdate();
    }

    function storePending(payload as Dictionary) as Void {
        var id = asInt(payload.get("completedAt"), 0);
        if (id <= 0) {
            return;
        }
        var next = [] as Array<Dictionary>;
        for (var i = 0; i < pending.size(); i++) {
            var item = pending[i] as Dictionary;
            if (asInt(item.get("completedAt"), 0) != id) {
                next.add(item);
            }
        }
        next.add(payload);
        while (next.size() > MAX_PENDING) {
            next = dropFirst(next);
        }
        pending = next;
        savePending();
    }

    function removePending(id as Number) as Void {
        var next = [] as Array<Dictionary>;
        for (var i = 0; i < pending.size(); i++) {
            var item = pending[i] as Dictionary;
            if (asInt(item.get("completedAt"), 0) != id) {
                next.add(item);
            }
        }
        pending = next;
        savePending();
    }

    function acknowledgeList(value as Object?) as Void {
        var ids = parseSyncedAt(value);
        if (ids.size() == 0) {
            return;
        }
        var next = [] as Array<Dictionary>;
        for (var i = 0; i < pending.size(); i++) {
            var item = pending[i] as Dictionary;
            var id = asInt(item.get("completedAt"), 0);
            var keep = true;
            for (var j = 0; j < ids.size(); j++) {
                if (id == ids[j]) {
                    keep = false;
                    break;
                }
            }
            if (keep) {
                next.add(item);
            }
        }
        if (next.size() != pending.size()) {
            pending = next;
            savePending();
        }
    }

    function flushPending() as Void {
        if (comm == null) {
            return;
        }
        for (var i = 0; i < pending.size(); i++) {
            (comm as CommLink).sendNow(pending[i] as Dictionary);
        }
    }

    function currentPageTable() as Dictionary? {
        if (page == PAGE_CO2) {
            return co2Table;
        }
        if (page == PAGE_O2) {
            return o2Table;
        }
        return plan;
    }

    function needsPhonePlan() as Boolean {
        return !running && !locked && !planComplete && plan == null;
    }

    function requestPhonePlan() as Void {
        if (!needsPhonePlan() || readyDelivered || comm == null) {
            return;
        }
        if (readyUpdatedAt <= 0) {
            readyUpdatedAt = nowSec();
        }
        (comm as CommLink).send(buildWatchReady(readyUpdatedAt));
    }

    // HomeView.onShow is the only caller. A second call while the timer is
    // running does not send another watchReady.
    function startReadyPulse() as Void {
        if (!needsPhonePlan()) {
            stopReadyPulse();
            return;
        }
        if (readyTicker != null) {
            return;
        }
        if (readyDelivered) {
            readyDelivered = false;
            readyUpdatedAt = 0;
        }
        requestPhonePlan();
        if (readyDelivered || !needsPhonePlan()) {
            return;
        }
        readyTicker = new Timer.Timer();
        (readyTicker as Timer.Timer).start(method(:onReadyPulse), READY_PULSE_MS, true);
    }

    function onReadyPulse() as Void {
        if (!needsPhonePlan() || readyDelivered) {
            stopReadyPulse();
            return;
        }
        requestPhonePlan();
    }

    function stopReadyPulse() as Void {
        if (readyTicker != null) {
            (readyTicker as Timer.Timer).stop();
            readyTicker = null;
        }
    }

    function showHome() as Void {
        viewKind = 0;
        WatchUi.switchToView(new HomeView(self), new HomeDelegate(self), WatchUi.SLIDE_RIGHT);
    }

    function showSession() as Void {
        viewKind = 1;
        WatchUi.switchToView(new SessionView(self), new SessionDelegate(self), WatchUi.SLIDE_LEFT);
    }

    function showDone() as Void {
        viewKind = 2;
        WatchUi.switchToView(new DoneView(self), new DoneDelegate(self), WatchUi.SLIDE_LEFT);
    }
}

(:test)
function testSessionStartAndFinish(logger as Test.Logger) as Boolean {
    var session = new SessionController();
    session.restore();
    if (!session.startCo2()) {
        return false;
    }
    if (!session.running) {
        return false;
    }
    if (session.phases.size() == 0) {
        return false;
    }
    session.startedAt = nowSec() - 60 - 90 - 120;
    session.advance();
    return session.finished || session.remaining >= 0;
}

(:test)
function testPhoneUpdateDoesNotAbortRunningSession(logger as Test.Logger) as Boolean {
    var session = new SessionController();
    session.restore();
    session.handlePhone({
        "type" => TYPE_NEXT_SESSION,
        "name" => "Week 1 · CO2",
        "tableType" => "co2",
        "breatheUpSeconds" => 60,
        "holdSeconds" => 90,
        "restSeconds" => 120,
        "rounds" => [{"hold" => 90, "rest" => 120}, {"hold" => 90, "rest" => 105}],
        "week" => 1,
        "sessionIndex" => 1,
        "planKey" => "beginner:1:"
    } as Dictionary);
    if (!session.startPlan()) {
        return false;
    }
    var remaining = session.remaining;
    var phases = session.phases.size();
    session.handlePhone({
        "type" => TYPE_NEXT_SESSION,
        "name" => "Week 2 · O2",
        "tableType" => "o2",
        "breatheUpSeconds" => 60,
        "holdSeconds" => 60,
        "restSeconds" => 120,
        "rounds" => [{"hold" => 60, "rest" => 120}],
        "week" => 2,
        "sessionIndex" => 1,
        "planKey" => "beginner:2:",
        "sync" => "erase",
        "trainingHaptic" => false,
        "phoneTraining" => {"running" => true}
    } as Dictionary);
    if (!session.running || session.paused || session.finishing) {
        return false;
    }
    if (session.remaining != remaining || session.phases.size() != phases) {
        return false;
    }
    if (!session.hapticEnabled) {
        return false;
    }
    session.togglePause();
    return session.running && session.paused;
}

(:test)
function testWatchExitStillCancelsAfterPhoneUpdate(logger as Test.Logger) as Boolean {
    var session = new SessionController();
    session.restore();
    if (!session.startCo2()) {
        return false;
    }
    session.handlePhone({
        "type" => TYPE_NEXT_SESSION,
        "planKey" => "beginner:1:",
        "sync" => "erase",
        "phoneTraining" => {"running" => false, "paused" => true}
    } as Dictionary);
    if (!session.running || session.paused) {
        return false;
    }
    session.exitSession();
    return !session.running && !session.paused;
}

(:test)
function testPendingSyncDoesNotBlockStart(logger as Test.Logger) as Boolean {
    var session = new SessionController();
    var link = new CommLink(session);
    session.setComm(link);
    session.pendingSync = true;
    if (session.syncInProgress() || !session.canStart()) {
        return false;
    }
    link.busy = true;
    if (!session.syncInProgress()) {
        return false;
    }
    if (!session.startCo2()) {
        return false;
    }
    if (!session.running || !session.pendingSync || !session.syncInProgress()) {
        return false;
    }
    link.busy = false;
    session.onTransmitFinished(true, {
        "type" => TYPE_WATCH_READY,
        "updatedAt" => 1700000000
    } as Dictionary);
    if (session.syncInProgress() || session.awaitingPhone) {
        return false;
    }
    session.onTransmitFinished(true, {
        "type" => TYPE_SESSION_COMPLETE,
        "completedAt" => 1700001000
    } as Dictionary);
    if (!session.syncInProgress() || !session.awaitingPhone) {
        return false;
    }
    session.onTransmitFinished(false, {
        "type" => TYPE_SESSION_COMPLETE,
        "completedAt" => 1700001000
    } as Dictionary);
    if (!session.syncInProgress()) {
        return false;
    }
    session.pendingSync = false;
    return session.running && !session.syncInProgress();
}

(:test)
function testPhonePlanInstallsWhenIdle(logger as Test.Logger) as Boolean {
    var session = new SessionController();
    session.handlePhone({
        "type" => TYPE_NEXT_SESSION,
        "name" => "Week 1 · CO2",
        "tableType" => "co2",
        "breatheUpSeconds" => 60,
        "holdSeconds" => 90,
        "restSeconds" => 120,
        "rounds" => [{"hold" => 90, "rest" => 120}, {"hold" => 90, "rest" => 105}],
        "week" => 1,
        "sessionIndex" => 1,
        "planKey" => "beginner:1:"
    } as Dictionary);
    if (session.plan == null || session.running) {
        return false;
    }
    return asTextOr((session.plan as Dictionary).get("name"), "").equals("Week 1 · CO2")
        && session.planKey.equals("beginner:1:")
        && !session.needsPhonePlan();
}

(:test)
function testPhoneTrainingKeepsName(logger as Test.Logger) as Boolean {
    var session = new SessionController();
    session.handlePhone({
        "type" => TYPE_PHONE_TRAINING,
        "running" => true,
        "name" => "CO2",
        "phase" => "hold"
    } as Dictionary);
    if (!session.phoneTraining || !session.phoneTrainingName.equals("CO2")) {
        return false;
    }
    session.handlePhone({
        "type" => TYPE_PHONE_TRAINING,
        "running" => true,
        "phase" => "rest"
    } as Dictionary);
    if (!session.phoneTraining || !session.phoneTrainingName.equals("CO2")) {
        return false;
    }
    session.handlePhone({
        "type" => TYPE_PHONE_TRAINING,
        "running" => false,
        "name" => "CO2"
    } as Dictionary);
    return !session.phoneTraining && session.phoneTrainingName.length() == 0;
}

(:test)
function testReadyPulseSkipsInstalledPlan(logger as Test.Logger) as Boolean {
    var session = new SessionController();
    var link = new QuietComm(session);
    session.setComm(link);
    session.handlePhone({
        "type" => TYPE_NEXT_SESSION,
        "name" => "Week 1 · CO2",
        "tableType" => "co2",
        "breatheUpSeconds" => 60,
        "holdSeconds" => 90,
        "restSeconds" => 120,
        "rounds" => [{"hold" => 90, "rest" => 120}],
        "week" => 1,
        "sessionIndex" => 1,
        "planKey" => "beginner:1:"
    } as Dictionary);
    session.startReadyPulse();
    return session.readyTicker == null && link.queue.size() == 0 && link.inFlight == null;
}

(:test)
function testReadyPulseReusesStampUntilDelivery(logger as Test.Logger) as Boolean {
    var session = new SessionController();
    var link = new QuietComm(session);
    session.setComm(link);
    session.startReadyPulse();
    if (session.readyTicker == null || link.inFlight == null || session.readyUpdatedAt <= 0) {
        session.stopReadyPulse();
        return false;
    }
    var stamp = session.readyUpdatedAt;
    if (asInt((link.inFlight as Dictionary).get("updatedAt"), 0) != stamp) {
        session.stopReadyPulse();
        return false;
    }
    session.startReadyPulse();
    if (link.queue.size() != 0 || asInt((link.inFlight as Dictionary).get("updatedAt"), 0) != stamp) {
        session.stopReadyPulse();
        return false;
    }
    link.onSent(false);
    session.onReadyPulse();
    if (session.readyUpdatedAt != stamp || link.inFlight == null) {
        session.stopReadyPulse();
        return false;
    }
    if (asInt((link.inFlight as Dictionary).get("updatedAt"), 0) != stamp) {
        session.stopReadyPulse();
        return false;
    }
    link.onSent(true);
    if (!session.readyDelivered || session.readyTicker != null || link.inFlight != null) {
        session.stopReadyPulse();
        return false;
    }
    session.onReadyPulse();
    if (link.inFlight != null || link.queue.size() != 0 || session.readyUpdatedAt != stamp) {
        session.stopReadyPulse();
        return false;
    }
    session.pendingSync = true;
    if (session.awaitingPhone || session.syncInProgress()) {
        session.stopReadyPulse();
        return false;
    }
    session.handlePhone({
        "type" => TYPE_NEXT_SESSION,
        "tables" => {
            "breatheUpSeconds" => 60,
            "co2" => {
                "name" => "CO2",
                "tableType" => "co2",
                "holdSeconds" => 90,
                "restSeconds" => 120,
                "rounds" => [{"hold" => 90, "rest" => 120}]
            },
            "o2" => {
                "name" => "O2",
                "tableType" => "o2",
                "holdSeconds" => 60,
                "restSeconds" => 120,
                "rounds" => [{"hold" => 60, "rest" => 120}]
            }
        }
    } as Dictionary);
    return session.readyTicker == null
        && session.plan == null
        && session.needsPhonePlan()
        && !session.readyDelivered
        && session.readyUpdatedAt == 0;
}
