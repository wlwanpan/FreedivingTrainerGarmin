import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
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
        var bubble = hasTopRightBubble();

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
        var labelX = cx;
        if (bubble) {
            labelX = labelCenterLeftOfBubble(dc, label, labelFont, width);
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(labelX, labelY, labelFont, label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, clockY, clockFont, formatClock(session.remaining), Graphics.TEXT_JUSTIFY_CENTER);

        var y = clockY + dc.getFontHeight(clockFont) + 4;
        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        if (session.roundText.length() > 0) {
            dc.drawText(cx, y, Graphics.FONT_XTINY, session.roundText, Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(Graphics.FONT_XTINY) + 2;
        }
        if (bubble) {
            drawBubbleBpm(dc, width, height);
        } else if (session.bpm > 0) {
            dc.drawText(cx, y, Graphics.FONT_XTINY, session.bpm.toString() + " bpm", Graphics.TEXT_JUSTIFY_CENTER);
        }

        var action = session.paused ? tr("resume") : tr("pause");
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (height * 13) / 16, labelFont, action, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawBubbleBpm(dc as Dc, width as Number, height as Number) as Void {
        var text = session.bpm > 0 ? session.bpm.toString() : "--";
        var font = Graphics.FONT_XTINY;
        var lineHeight = dc.getFontHeight(font);
        var top = bubbleCenterY(height) - lineHeight;
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(bubbleCenterX(width), top, font, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(bubbleCenterX(width), top + lineHeight, font, "bpm", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

// Descent G1 and Instinct 2 share a 176 semi-octagon screen. The top-right
// lobe is a circle centered at (142, 42) with radius 27 in that framebuffer.
function hasTopRightBubble() as Boolean {
    if (!(System has :SCREEN_SHAPE_SEMI_OCTAGON)) {
        return false;
    }
    return System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_SEMI_OCTAGON;
}

function bubbleCenterX(width as Number) as Number {
    return (142 * width) / 176;
}

function bubbleCenterY(height as Number) as Number {
    return (42 * height) / 176;
}

function labelCenterLeftOfBubble(dc as Dc, label as String, font as Graphics.FontType, width as Number) as Number {
    var labelWidth = dc.getTextWidthInPixels(label, font);
    var limit = (110 * width) / 176;
    var labelX = limit - labelWidth / 2;
    if (labelX < labelWidth / 2) {
        return labelWidth / 2;
    }
    return labelX;
}

function drawBubbleText(dc as Dc, width as Number, height as Number, text as String, color as Number) as Void {
    var font = Graphics.FONT_TINY;
    if (dc.getTextWidthInPixels(text, font) > 50) {
        font = Graphics.FONT_XTINY;
    }
    var lineHeight = dc.getFontHeight(font);
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawText(bubbleCenterX(width), bubbleCenterY(height) - lineHeight / 2, font, text, Graphics.TEXT_JUSTIFY_CENTER);
}
