import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
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

function fitBubbleFont(dc as Dc, text as String) as Graphics.FontType {
    var font = Graphics.FONT_TINY;
    if (dc.getTextWidthInPixels(text, font) > 50) {
        font = Graphics.FONT_XTINY;
    }
    return font;
}

function drawBubbleText(dc as Dc, width as Number, height as Number, text as String, color as Number) as Void {
    var font = fitBubbleFont(dc, text);
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
    var box = topRightTextBox(dc, width, height, text, font);
    var centerX = box[0] as Number;
    var top = box[1] as Number;
    var textH = box[2] as Number;
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawText(centerX, top, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    return top + textH;
}

// [centerX, top, textHeight] for a label tucked into the top-right of a round screen.
function topRightTextBox(dc as Dc, width as Number, height as Number, text as String, font as Graphics.FontType) as Array<Number> {
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
    return [cx + ox, cy - oy - hh, textH] as Array<Number>;
}

(:color)
function spinnerHasTrack() as Boolean {
    return true;
}

(:mono)
function spinnerHasTrack() as Boolean {
    return false;
}

function isqrt(value as Number) as Number {
    if (value <= 0) {
        return 0;
    }
    var x = value;
    var y = (x + 1) / 2;
    while (y < x) {
        x = y;
        y = (x + value / x) / 2;
    }
    return x;
}

// Radius of a circle that clears the text box, plus a few pixels of air.
function textRingRadius(textW as Number, textH as Number) as Number {
    var hw = (textW + 1) / 2;
    var hh = (textH + 1) / 2;
    var radius = isqrt(hw * hw + hh * hh) + 3;
    if (radius < 8) {
        radius = 8;
    }
    return radius;
}

function drawSpinnerArc(dc as Dc, x as Number, y as Number, radius as Number, angle as Number) as Void {
    if (radius < 2) {
        return;
    }
    var start = angle % 360;
    if (start < 0) {
        start += 360;
    }
    var end = start + 90;
    if (end >= 360) {
        end -= 360;
    }
    if (end == start) {
        end = start + 1;
    }
    if (dc has :setAntiAlias) {
        dc.setAntiAlias(true);
    }
    dc.setPenWidth(2);
    if (spinnerHasTrack()) {
        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(x, y, radius, Graphics.ARC_CLOCKWISE, 0, 0);
    }
    dc.setColor(COLOR_HOLD, Graphics.COLOR_TRANSPARENT);
    dc.drawArc(x, y, radius, Graphics.ARC_COUNTER_CLOCKWISE, start, end);
    dc.setPenWidth(1);
    if (dc has :setAntiAlias) {
        dc.setAntiAlias(false);
    }
}

// Orbit the top-right bubble Start label. The label is drawn afterwards.
function drawBubbleStartSpinner(dc as Dc, width as Number, height as Number, angle as Number) as Void {
    var text = tr("start");
    var font = fitBubbleFont(dc, text);
    var radius = textRingRadius(dc.getTextWidthInPixels(text, font), dc.getFontHeight(font));
    var limit = (27 * height) / 176 - 2;
    if (limit < 6) {
        limit = 6;
    }
    if (radius > limit) {
        radius = limit;
    }
    drawSpinnerArc(dc, bubbleCenterX(width), bubbleCenterY(height), radius, angle);
}

// Orbit the round top-right Start label. Returns the y just below the ring.
function drawRoundStartSpinner(dc as Dc, width as Number, height as Number, angle as Number) as Number {
    var text = tr("start");
    var font = Graphics.FONT_SMALL;
    var box = topRightTextBox(dc, width, height, text, font);
    var centerX = box[0] as Number;
    var textH = box[2] as Number;
    var centerY = (box[1] as Number) + textH / 2;
    var radius = textRingRadius(dc.getTextWidthInPixels(text, font), textH);
    drawSpinnerArc(dc, centerX, centerY, radius, angle);
    return centerY + radius;
}

// Orbit a Start label whose top-left of the glyphs is (x, top) with centered text.
function drawCenteredStartSpinner(dc as Dc, x as Number, top as Number, font as Graphics.FontType, angle as Number) as Void {
    var text = tr("start");
    var textH = dc.getFontHeight(font);
    var radius = textRingRadius(dc.getTextWidthInPixels(text, font), textH);
    drawSpinnerArc(dc, x, top + textH / 2, radius, angle);
}

// Small loader used where there is no Start label, such as the saved screen.
function drawSyncSpinner(dc as Dc, width as Number, height as Number, angle as Number) as Number {
    var x = 0;
    var y = 0;
    var radius = 7;
    if (height >= 360) {
        radius = 11;
    } else if (height >= 240) {
        radius = 9;
    }
    if (hasTopRightBubble()) {
        x = bubbleCenterX(width);
        y = bubbleCenterY(height);
        radius = 8;
    } else if (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND) {
        var box = topRightTextBox(dc, width, height, tr("start"), Graphics.FONT_SMALL);
        x = box[0] as Number;
        y = (box[1] as Number) + (box[2] as Number) / 2;
    } else {
        var inset = height < 200 ? 14 : 20;
        x = width - inset;
        y = inset;
    }
    drawSpinnerArc(dc, x, y, radius, angle);
    return y + radius;
}

class SyncSpinner {
    var timer as Timer.Timer?;
    var angle as Number;

    function initialize() {
        timer = null;
        angle = 0;
    }

    function setActive(active as Boolean) as Void {
        if (!active) {
            stop();
            return;
        }
        if (timer != null) {
            return;
        }
        timer = new Timer.Timer();
        (timer as Timer.Timer).start(method(:onSpin), SPINNER_TICK_MS, true);
    }

    function stop() as Void {
        if (timer != null) {
            (timer as Timer.Timer).stop();
            timer = null;
        }
    }

    function onSpin() as Void {
        angle = (angle + 30) % 360;
        WatchUi.requestUpdate();
    }
}
