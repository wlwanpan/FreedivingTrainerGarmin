import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class DoneView extends WatchUi.View {
    var session as SessionController;
    var spinner as SyncSpinner;

    function initialize(owner as SessionController) {
        View.initialize();
        session = owner;
        spinner = new SyncSpinner();
    }

    function onShow() as Void {
        spinner.setActive(session.syncInProgress());
    }

    function onHide() as Void {
        spinner.stop();
    }

    function onUpdate(dc as Dc) as Void {
        var syncing = session.syncInProgress();
        spinner.setActive(syncing);
        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var compact = height < 200;
        var y = compact ? height / 4 : height / 3;
        var titleFont = compact ? Graphics.FONT_TINY : Graphics.FONT_SMALL;
        var bodyFont = compact ? Graphics.FONT_XTINY : Graphics.FONT_TINY;
        if (syncing) {
            drawSyncSpinner(dc, width, height, spinner.angle);
        }
        dc.setColor(COLOR_HOLD, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, titleFont, tr("saved"), Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(titleFont) + 8;
        if (!session.pendingSync) {
            dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, bodyFont, tr("sentToPhone"), Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(bodyFont) + 16;
        } else {
            y += 16;
        }
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, bodyFont, tr("okay"), Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class DoneDelegate extends WatchUi.BehaviorDelegate {
    var session as SessionController;

    function initialize(owner as SessionController) {
        BehaviorDelegate.initialize();
        session = owner;
    }

    function onSelect() as Boolean {
        session.dismissSaved();
        return true;
    }

    function onBack() as Boolean {
        session.dismissSaved();
        return true;
    }
}
