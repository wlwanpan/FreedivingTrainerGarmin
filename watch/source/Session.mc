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
    var pendingSync as Boolean = false;
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
        loadPending();
    }

    function persist() as Void {
        Storage.setValue(STORAGE_LANGUAGE, gLanguage);
        Storage.setValue(STORAGE_HAPTIC, hapticEnabled);
        Storage.setValue(STORAGE_SOUND, soundEnabled);
        savePending();
    }

    function handlePhone(message as Dictionary) as Void {
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

        acknowledgeList(message.get("syncedAt"));
        var type = asTextOr(message.get("type"), "");
        if (type.equals(TYPE_ACK)) {
            var id = asInt(message.get("completedAt"), 0);
            if (id > 0) {
                removePending(id);
            }
            return;
        }
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

    function applyPhoneTraining(message as Dictionary) as Void {
        var record = asDict(message.get("phoneTraining"));
        if (record == null && asTextOr(message.get("type"), "").equals(TYPE_PHONE_TRAINING)) {
            record = message;
        }
        if (record == null) {
            return;
        }
        phoneTraining = asFlag(record.get("running"));
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
                var tableSession = active != null && asInt((active as Dictionary).get("week"), 0) == 0;
                var erased = asTextOr(message.get("sync"), "").equals("erase");
                if (erased || !tableSession) {
                    planKey = key;
                    abort(false);
                    installPlan(message);
                    lostNotice = erased ? tr("erased") : tr("planChanged");
                    showHome();
                } else {
                    planKey = key;
                }
            }
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
            return;
        }
        if (asFlag(message.get("complete"))) {
            locked = false;
            planComplete = true;
            finished = false;
            plan = null;
            return;
        }
        locked = false;
        planComplete = false;
        plan = parsePlan(message);
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
