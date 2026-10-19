import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;

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
    var busy as Boolean;
    var lastOk as Boolean;
    var listener as TransmitListener;

    function initialize(owner as SessionController) {
        session = owner;
        queue = [] as Array<Dictionary>;
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
        if (queue.size() >= 8) {
            var type = asText(payload.get("type"));
            if (type != null && (type as String).equals(TYPE_HEART_RATE)) {
                return;
            }
        }
        queue.add(payload);
        flush();
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
        busy = false;
        lastOk = ok;
        flush();
        session.onTransmitFinished(ok);
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
        busy = true;
        Communications.transmit(payload, null, listener);
        session.onTransmitOk();
    }

    function phoneLikelyReachable() as Boolean {
        var settings = System.getDeviceSettings();
        return lastOk || settings.phoneConnected;
    }
}

function dropFirst(items as Array<Dictionary>) as Array<Dictionary> {
    var next = [] as Array<Dictionary>;
    for (var i = 1; i < items.size(); i++) {
        next.add(items[i]);
    }
    return next;
}
