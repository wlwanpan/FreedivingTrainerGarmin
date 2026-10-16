import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SessionView extends WatchUi.View {
    var session as SessionController;

    function initialize(owner as SessionController) {
        View.initialize();
        session = owner;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var color = phaseColor(session.phaseTitle, session.paused);

        var label = session.paused ? tr("paused") : trPhase(session.phaseTitle);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, height / 8, Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        var clockFont = Graphics.FONT_NUMBER_HOT;
        if (dc.getFontHeight(clockFont) > height / 2) {
            clockFont = Graphics.FONT_NUMBER_MEDIUM;
        }
        dc.drawText(cx, height / 2 - dc.getFontHeight(clockFont) / 2, clockFont, formatClock(session.remaining), Graphics.TEXT_JUSTIFY_CENTER);

        var y = height / 2 + dc.getFontHeight(clockFont) / 2 + 4;
        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        if (session.roundText.length() > 0) {
            dc.drawText(cx, y, Graphics.FONT_XTINY, session.roundText, Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(Graphics.FONT_XTINY) + 2;
        }
        if (session.bpm > 0) {
            dc.drawText(cx, y, Graphics.FONT_XTINY, session.bpm.toString() + " bpm", Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(Graphics.FONT_XTINY) + 2;
        }

        var action = session.paused ? tr("resume") : tr("pause");
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (height * 13) / 16, Graphics.FONT_TINY, action, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
