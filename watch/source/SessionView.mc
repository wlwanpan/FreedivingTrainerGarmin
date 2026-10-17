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
// Descent G2 is round, so its START label uses drawRoundTopRightText instead.
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

// Descent G2 is the 390×390 round watch. START is the top-right button, the
// same corner as Descent G1, so the home label belongs there rather than
// under the page title.
function hasRoundTopRightStart() as Boolean {
    var settings = System.getDeviceSettings();
    return settings.screenShape == System.SCREEN_SHAPE_ROUND
        && settings.screenWidth == 390
        && settings.screenHeight == 390;
}

// Draw text inside the circle on the ray toward that START button, about 55°
// above 3 o'clock. Returns the y just below the glyphs.
function drawRoundTopRightText(dc as Dc, width as Number, height as Number, text as String, color as Number) as Number {
    var font = Graphics.FONT_SMALL;
    var textW = dc.getTextWidthInPixels(text, font);
    var textH = dc.getFontHeight(font);
    var pad = 8;
    var radius = width / 2 - pad;
    if (radius < 1) {
        radius = 1;
    }
    var cx = width / 2;
    var cy = height / 2;
    var hw = (textW + 1) / 2;
    var hh = (textH + 1) / 2;
    var dirX = 57;
    var dirY = 82;
    var dirLen = 100;
    var limit = radius * radius;
    var lo = 0;
    var hi = radius;
    var mid = 0;
    var ox = 0;
    var oy = 0;
    var right = 0;
    var left = 0;
    var up = 0;
    var down = 0;
    var furthest = 0;
    var corner = 0;
    while (lo < hi) {
        mid = (lo + hi + 1) / 2;
        ox = (mid * dirX) / dirLen;
        oy = (mid * dirY) / dirLen;
        right = ox + hw;
        left = ox - hw;
        up = oy + hh;
        down = oy - hh;
        furthest = right * right + up * up;
        corner = right * right + down * down;
        if (corner > furthest) {
            furthest = corner;
        }
        corner = left * left + up * up;
        if (corner > furthest) {
            furthest = corner;
        }
        if (furthest <= limit) {
            lo = mid;
        } else {
            hi = mid - 1;
        }
    }
    ox = (lo * dirX) / dirLen;
    oy = (lo * dirY) / dirLen;
    var top = cy - oy - hh;
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawText(cx + ox, top, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    return top + textH;
}
