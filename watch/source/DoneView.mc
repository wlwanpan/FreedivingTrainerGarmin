import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class DoneView extends WatchUi.View {
    var session as SessionController;

    function initialize(owner as SessionController) {
        View.initialize();
        session = owner;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();
        var cx = dc.getWidth() / 2;
        var compact = dc.getHeight() < 200;
        var y = compact ? dc.getHeight() / 4 : dc.getHeight() / 3;
        var titleFont = compact ? Graphics.FONT_TINY : Graphics.FONT_SMALL;
        var bodyFont = compact ? Graphics.FONT_XTINY : Graphics.FONT_TINY;
        dc.setColor(COLOR_HOLD, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, titleFont, tr("saved"), Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(titleFont) + 8;
        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        var status = session.pendingSync ? tr("waitingPhone") : tr("sentToPhone");
        dc.drawText(cx, y, bodyFont, status, Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(bodyFont) + 16;
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
