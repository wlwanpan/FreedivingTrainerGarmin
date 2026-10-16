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
        var y = height / 8;

        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        if (session.pendingSync) {
            dc.drawText(cx, y, Graphics.FONT_XTINY, tr("waitingPhone"), Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(Graphics.FONT_XTINY) + 2;
        }

        if (session.phoneTraining && session.phoneConnected()) {
            dc.setColor(COLOR_ALERT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_TINY, tr("trainingOnPhone"), Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(Graphics.FONT_TINY) + 4;
        } else if (session.lostNotice.length() > 0) {
            dc.setColor(COLOR_ALERT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_XTINY, session.lostNotice, Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(Graphics.FONT_XTINY) + 4;
        }

        var title = pageTitle();
        var detail = pageDetail();
        var canStart = session.canStart() && session.currentPageTable() != null;

        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(Graphics.FONT_SMALL) + 6;

        if (session.locked && session.page == PAGE_PLAN) {
            dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_TINY, tr("unlockLifetime"), Graphics.TEXT_JUSTIFY_CENTER);
        } else if (session.planComplete && session.page == PAGE_PLAN) {
            dc.setColor(COLOR_BREATHE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_TINY, tr("weekComplete"), Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(Graphics.FONT_TINY) + 4;
            dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_XTINY, tr("savedOnPhone"), Graphics.TEXT_JUSTIFY_CENTER);
        } else if (detail.length() == 0 && session.page == PAGE_PLAN) {
            dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_TINY, tr("choosePlan"), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_TINY, detail, Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(Graphics.FONT_TINY) + 10;
            if (canStart) {
                dc.setColor(COLOR_HOLD, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, y, Graphics.FONT_SMALL, tr("start"), Graphics.TEXT_JUSTIFY_CENTER);
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

    function drawDots(dc as Dc, width as Number, height as Number) as Void {
        var y = (height * 7) / 8;
        var startX = width / 2 - 16;
        for (var i = 0; i < 3; i++) {
            if (i == session.page) {
                dc.setColor(COLOR_HOLD, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillCircle(startX + i * 16, y, 3);
        }
    }
}
