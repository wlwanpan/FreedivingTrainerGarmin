import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class FreedivingTrainerApp extends Application.AppBase {
    var session as SessionController?;
    var comm as CommLink?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        var controller = new SessionController();
        var link = new CommLink(controller);
        controller.setComm(link);
        controller.restore();
        link.start();
        controller.flushPending();
        session = controller;
        comm = link;
    }

    function onStop(state as Dictionary?) as Void {
        if (session != null) {
            var controller = session as SessionController;
            if (controller.running) {
                controller.abort(false);
            }
            controller.persist();
        }
        if (comm != null) {
            (comm as CommLink).stop();
        }
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var controller = session;
        if (controller == null) {
            controller = new SessionController();
            session = controller;
        }
        return [new HomeView(controller as SessionController), new HomeDelegate(controller as SessionController)];
    }
}

function getApp() as FreedivingTrainerApp {
    return Application.getApp() as FreedivingTrainerApp;
}
