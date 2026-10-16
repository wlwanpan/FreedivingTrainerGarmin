import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class HomeView extends WatchUi.View {
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
        var compact = height < 200;
        var y = compact ? height / 4 : height / 8;
        var bodyFont = compact ? Graphics.FONT_XTINY : Graphics.FONT_TINY;
        var titleFont = compact ? Graphics.FONT_TINY : Graphics.FONT_SMALL;
        var maxLine = compact ? (width * 5) / 8 : width;

        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        if (session.pendingSync) {
            dc.drawText(cx, y, Graphics.FONT_XTINY, tr("waitingPhone"), Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(Graphics.FONT_XTINY) + 2;
        }

        if (session.phoneTraining && session.phoneConnected()) {
            dc.setColor(COLOR_ALERT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, bodyFont, tr("trainingOnPhone"), Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(bodyFont) + 4;
        } else if (session.lostNotice.length() > 0) {
            dc.setColor(COLOR_ALERT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_XTINY, session.lostNotice, Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(Graphics.FONT_XTINY) + 4;
        }

        var title = pageTitle();
        var detail = pageDetail();
        var canStart = session.canStart() && session.currentPageTable() != null;

        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, titleFont, title, Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(titleFont) + 6;

        if (session.locked && session.page == PAGE_PLAN) {
            dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, bodyFont, tr("unlockLifetime"), Graphics.TEXT_JUSTIFY_CENTER);
        } else if (session.planComplete && session.page == PAGE_PLAN) {
            dc.setColor(COLOR_BREATHE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, bodyFont, tr("weekComplete"), Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(bodyFont) + 4;
            dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_XTINY, tr("savedOnPhone"), Graphics.TEXT_JUSTIFY_CENTER);
        } else if (detail.length() == 0 && session.page == PAGE_PLAN) {
            dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
            drawFitted(dc, cx, y, bodyFont, tr("choosePlan"), maxLine);
        } else {
            dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
            y = drawFitted(dc, cx, y, bodyFont, detail, maxLine);
            y += 8;
            if (canStart) {
                dc.setColor(COLOR_HOLD, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, y, titleFont, tr("start"), Graphics.TEXT_JUSTIFY_CENTER);
            }
        }

        drawDots(dc, width, height);
    }

    function pageTitle() as String {
        if (session.page == PAGE_CO2) {
            return tr("co2");
        }
        if (session.page == PAGE_O2) {
            return tr("o2");
        }
        if (session.plan != null) {
            return asTextOr((session.plan as Dictionary).get("name"), tr("plan"));
        }
        return tr("plan");
    }

    function pageDetail() as String {
        var table = session.currentPageTable();
        if (table == null) {
            return "";
        }
        return holdDetail(
            asTextOr((table as Dictionary).get("tableType"), "co2"),
            formatClock(asInt((table as Dictionary).get("holdSeconds"), 0)),
            roundCount(table as Dictionary)
        );
    }

    function drawFitted(dc as Dc, cx as Number, y as Number, font as FontDefinition, text as String, maxW as Number) as Number {
        if (dc.getTextWidthInPixels(text, font) <= maxW) {
            dc.drawText(cx, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
            return y + dc.getFontHeight(font);
        }
        var best = -1;
        var i = 0;
        var n = text.length();
        while (i < n) {
            if (text.substring(i, i + 1).equals(" ")) {
                if (dc.getTextWidthInPixels(text.substring(0, i), font) <= maxW) {
                    best = i;
                }
            }
            i += 1;
        }
        if (best < 1) {
            dc.drawText(cx, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
            return y + dc.getFontHeight(font);
        }
        dc.drawText(cx, y, font, text.substring(0, best), Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(font) + 1;
        dc.drawText(cx, y, font, text.substring(best + 1, n), Graphics.TEXT_JUSTIFY_CENTER);
        return y + dc.getFontHeight(font);
    }

    function drawDots(dc as Dc, width as Number, height as Number) as Void {
        var y = (height * 7) / 8;
        var startX = width / 2 - 16;
        var radius = height < 200 ? 3 : 4;
        for (var i = 0; i < 3; i++) {
            dc.setColor(COLOR_HOLD, Graphics.COLOR_TRANSPARENT);
            var x = startX + i * 16;
            if (i == session.page) {
                dc.fillCircle(x, y, radius);
            } else {
                dc.drawCircle(x, y, radius);
            }
        }
    }
}
