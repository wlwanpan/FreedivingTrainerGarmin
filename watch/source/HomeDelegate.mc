import Toybox.Lang;
import Toybox.WatchUi;

class HomeDelegate extends WatchUi.BehaviorDelegate {
    var session as SessionController;

    function initialize(owner as SessionController) {
        BehaviorDelegate.initialize();
        session = owner;
    }

    function onSelect() as Boolean {
        return startCurrent();
    }

    function onMenu() as Boolean {
        return startCurrent();
    }

    function onNextPage() as Boolean {
        session.page = (session.page + 1) % 3;
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() as Boolean {
        session.page = session.page == 0 ? 2 : session.page - 1;
        WatchUi.requestUpdate();
        return true;
    }

    function startCurrent() as Boolean {
        if (session.page == PAGE_CO2) {
            return session.startCo2();
        }
        if (session.page == PAGE_O2) {
            return session.startO2();
        }
        if (session.startPlan()) {
            return true;
        }
        return session.startCo2();
    }
}
