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

        var clockFont = Graphics.FONT_NUMBER_MEDIUM;
        if (height >= 240) {
            clockFont = Graphics.FONT_NUMBER_HOT;
            if (dc.getFontHeight(clockFont) > height / 2) {
                clockFont = Graphics.FONT_NUMBER_MEDIUM;
            }
        } else if (dc.getFontHeight(clockFont) > height / 3) {
            clockFont = Graphics.FONT_NUMBER_MILD;
        }

        var clockY = height / 2 - dc.getFontHeight(clockFont) / 2;
        var labelFont = height < 200 ? Graphics.FONT_XTINY : Graphics.FONT_TINY;
        var labelY = height < 200 ? clockY - dc.getFontHeight(labelFont) - 4 : height / 8;
        var label = session.paused ? tr("paused") : trPhase(session.phaseTitle);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, labelY, labelFont, label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, clockY, clockFont, formatClock(session.remaining), Graphics.TEXT_JUSTIFY_CENTER);

        var y = clockY + dc.getFontHeight(clockFont) + 4;
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
        dc.drawText(cx, (height * 13) / 16, labelFont, action, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
