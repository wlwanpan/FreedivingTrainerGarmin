import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

class TransmitListener extends Communications.ConnectionListener {
    var link as CommLink;

    function initialize(owner as CommLink) {
        Communications.ConnectionListener.initialize();
        link = owner;
    }

    function onComplete() as Void {
        link.onSent(true);
    }

    function onError() as Void {
        link.onSent(false);
    }
}

class CommLink {
    var session as SessionController;
    var queue as Array<Dictionary>;
    var inFlight as Dictionary?;
    var busy as Boolean;
    var lastOk as Boolean;
    var listener as TransmitListener;

    function initialize(owner as SessionController) {
        session = owner;
        queue = [] as Array<Dictionary>;
        inFlight = null;
        busy = false;
        lastOk = false;
        listener = new TransmitListener(self);
    }

    function start() as Void {
        if (Communications has :registerForPhoneAppMessages) {
            Communications.registerForPhoneAppMessages(method(:onPhone));
        }
    }

    function stop() as Void {
        if (Communications has :registerForPhoneAppMessages) {
            Communications.registerForPhoneAppMessages(null);
        }
    }

    function onPhone(msg as Communications.PhoneAppMessage) as Void {
        var data = msg.data;
        if (data instanceof Dictionary) {
            session.handlePhone(data as Dictionary);
        }
    }

    function send(payload as Dictionary) as Void {
        if (stage(payload)) {
            flush();
        }
    }

    // Drop a watchReady that is already queued or transmitting. Replace a
    // queued watchTraining snapshot. Leave sessionComplete and the in-flight
    // packet untouched.
    function stage(payload as Dictionary) as Boolean {
        var type = asTextOr(payload.get("type"), "");
        if (type.equals(TYPE_WATCH_READY)) {
            if (queueHas(TYPE_WATCH_READY) || inFlightType().equals(TYPE_WATCH_READY)) {
                return false;
            }
        } else if (type.equals(TYPE_WATCH_TRAINING)) {
            if (replaceQueued(TYPE_WATCH_TRAINING, payload)) {
                return true;
            }
        }
        if (queue.size() >= 8 && type.equals(TYPE_HEART_RATE)) {
            return false;
        }
        queue.add(payload);
        return true;
    }

    function queueHas(type as String) as Boolean {
        for (var i = 0; i < queue.size(); i++) {
            if (asTextOr((queue[i] as Dictionary).get("type"), "").equals(type)) {
                return true;
            }
        }
        return false;
    }

    function inFlightType() as String {
        if (inFlight == null) {
            return "";
        }
        return asTextOr((inFlight as Dictionary).get("type"), "");
    }

    function replaceQueued(type as String, payload as Dictionary) as Boolean {
        var found = false;
        var next = [] as Array<Dictionary>;
        for (var i = 0; i < queue.size(); i++) {
            var item = queue[i] as Dictionary;
            if (asTextOr(item.get("type"), "").equals(type)) {
                if (!found) {
                    next.add(payload);
                    found = true;
                }
            } else {
                next.add(item);
            }
        }
        if (!found) {
            return false;
        }
        queue = next;
        return true;
    }

    function sendNow(payload as Dictionary) as Void {
        var next = [] as Array<Dictionary>;
        next.add(payload);
        for (var i = 0; i < queue.size(); i++) {
            next.add(queue[i]);
        }
        queue = next;
        flush();
    }

    function onSent(ok as Boolean) as Void {
        var sent as Dictionary? = inFlight;
        inFlight = null;
        busy = false;
        lastOk = ok;
        flush();
        session.onTransmitFinished(ok, sent);
    }

    function flush() as Void {
        if (busy || queue.size() == 0) {
            return;
        }
        if (!(Communications has :transmit)) {
            return;
        }
        var payload = queue[0] as Dictionary;
        queue = dropFirst(queue);
        inFlight = payload;
        busy = true;
        Communications.transmit(payload, null, listener);
        session.onTransmitOk();
    }

    function phoneLikelyReachable() as Boolean {
        var settings = System.getDeviceSettings();
        return lastOk || settings.phoneConnected;
    }
}

(:test)
class QuietComm extends CommLink {
    function initialize(owner as SessionController) {
        CommLink.initialize(owner);
    }

    function flush() as Void {
        if (busy || queue.size() == 0) {
            return;
        }
        var payload = queue[0] as Dictionary;
        queue = dropFirst(queue);
        inFlight = payload;
        busy = true;
    }
}

(:test)
function testStageCoalescesReadyAndTraining(logger as Test.Logger) as Boolean {
    var session = new SessionController();
    var link = new CommLink(session);
    var ready = {
        "type" => TYPE_WATCH_READY,
        "updatedAt" => 10
    } as Dictionary;
    var readyAgain = {
        "type" => TYPE_WATCH_READY,
        "updatedAt" => 20
    } as Dictionary;
    if (!link.stage(ready) || link.stage(readyAgain) || link.queue.size() != 1) {
        return false;
    }
    if (asInt((link.queue[0] as Dictionary).get("updatedAt"), 0) != 10) {
        return false;
    }
    link.inFlight = ready;
    link.queue = [] as Array<Dictionary>;
    if (link.stage(readyAgain) || link.queue.size() != 0) {
        return false;
    }
    if (asInt((link.inFlight as Dictionary).get("updatedAt"), 0) != 10) {
        return false;
    }

    link.inFlight = null;
    link.queue = [] as Array<Dictionary>;
    var older = {
        "type" => TYPE_WATCH_TRAINING,
        "name" => "A",
        "updatedAt" => 1
    } as Dictionary;
    var latest = {
        "type" => TYPE_WATCH_TRAINING,
        "name" => "B",
        "updatedAt" => 2
    } as Dictionary;
    var beat = {
        "type" => TYPE_HEART_RATE,
        "bpm" => 60,
        "at" => 3
    } as Dictionary;
    var done = {
        "type" => TYPE_SESSION_COMPLETE,
        "completedAt" => 4
    } as Dictionary;
    var doneAgain = {
        "type" => TYPE_SESSION_COMPLETE,
        "completedAt" => 5
    } as Dictionary;
    if (!link.stage(older) || !link.stage(beat) || !link.stage(done) || !link.stage(latest)) {
        return false;
    }
    if (link.queue.size() != 3) {
        return false;
    }
    if (!asTextOr((link.queue[0] as Dictionary).get("name"), "").equals("B")) {
        return false;
    }
    if (!asTextOr((link.queue[1] as Dictionary).get("type"), "").equals(TYPE_HEART_RATE)) {
        return false;
    }
    if (asInt((link.queue[2] as Dictionary).get("completedAt"), 0) != 4) {
        return false;
    }
    if (!link.stage(doneAgain) || link.queue.size() != 4) {
        return false;
    }

    var flying = {
        "type" => TYPE_WATCH_TRAINING,
        "name" => "fly",
        "updatedAt" => 8
    } as Dictionary;
    var queued = {
        "type" => TYPE_WATCH_TRAINING,
        "name" => "queued",
        "updatedAt" => 9
    } as Dictionary;
    var newer = {
        "type" => TYPE_WATCH_TRAINING,
        "name" => "new",
        "updatedAt" => 10
    } as Dictionary;
    link.inFlight = flying;
    link.queue = [] as Array<Dictionary>;
    link.queue.add(queued);
    if (!link.stage(newer)) {
        return false;
    }
    if (!asTextOr((link.inFlight as Dictionary).get("name"), "").equals("fly")) {
        return false;
    }
    return link.queue.size() == 1
        && asTextOr((link.queue[0] as Dictionary).get("name"), "").equals("new");
}

function dropFirst(items as Array<Dictionary>) as Array<Dictionary> {
    var next = [] as Array<Dictionary>;
    for (var i = 1; i < items.size(); i++) {
        next.add(items[i]);
    }
    return next;
}
