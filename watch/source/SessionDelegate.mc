import Toybox.Lang;
import Toybox.WatchUi;

class SessionDelegate extends WatchUi.BehaviorDelegate {
    var session as SessionController;

    function initialize(owner as SessionController) {
        BehaviorDelegate.initialize();
        session = owner;
    }

    function onSelect() as Boolean {
        session.togglePause();
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        if (!session.running) {
            return false;
        }
        if (!session.paused) {
            session.togglePause();
            WatchUi.requestUpdate();
            return true;
        }
        var dialog = new WatchUi.Confirmation(tr("exitTitle"));
        WatchUi.pushView(dialog, new ExitConfirmDelegate(session), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}

class ExitConfirmDelegate extends WatchUi.ConfirmationDelegate {
    var session as SessionController;

    function initialize(owner as SessionController) {
        ConfirmationDelegate.initialize();
        session = owner;
    }

    function onResponse(value as Confirm) as Boolean {
        if (value == WatchUi.CONFIRM_YES) {
            session.exitSession();
        } else if (session.paused) {
            session.togglePause();
        }
        return true;
    }
}
