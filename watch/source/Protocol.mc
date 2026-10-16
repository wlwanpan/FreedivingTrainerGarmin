import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;

function asInt(value as Object?, fallback as Number) as Number {
    if (value instanceof Number) {
        return value as Number;
    }
    if (value instanceof Float) {
        return (value as Float).toNumber();
    }
    if (value instanceof Boolean) {
        return (value as Boolean) ? 1 : 0;
    }
    return fallback;
}

function asFlag(value as Object?) as Boolean {
    if (value instanceof Boolean) {
        return value as Boolean;
    }
    if (value instanceof Number) {
        return (value as Number) != 0;
    }
    return false;
}

function asText(value as Object?) as String? {
    if (value instanceof String) {
        return value as String;
    }
    return null;
}

function asTextOr(value as Object?, fallback as String) as String {
    var text = asText(value);
    if (text != null) {
        return text as String;
    }
    return fallback;
}

function asDict(value as Object?) as Dictionary? {
    if (value instanceof Dictionary) {
        return value as Dictionary;
    }
    return null;
}

function nowSec() as Number {
    return Time.now().value();
}

function parseRounds(value as Object?) as Array<Dictionary> {
    var out = [] as Array<Dictionary>;
    if (!(value instanceof Array)) {
        return out;
    }
    var rows = value as Array;
    var limit = rows.size();
    if (limit > MAX_ROUNDS) {
        limit = MAX_ROUNDS;
    }
    for (var i = 0; i < limit; i++) {
        var row = rows[i];
        if (row instanceof Dictionary) {
            var hold = asInt((row as Dictionary).get("hold"), 0);
            var rest = asInt((row as Dictionary).get("rest"), 0);
            if (hold > 0) {
                if (rest < 0) {
                    rest = 0;
                }
                out.add({
                    "hold" => hold,
                    "rest" => rest
                });
            }
        }
    }
    return out;
}

function parseTable(value as Object?, breatheUp as Number, fallbackName as String, fallbackType as String) as Dictionary? {
    var record = asDict(value);
    if (record == null) {
        return null;
    }
    var name = asTextOr(record.get("name"), fallbackName);
    var tableType = asTextOr(record.get("tableType"), fallbackType);
    var hold = asInt(record.get("holdSeconds"), 0);
    var rest = asInt(record.get("restSeconds"), 0);
    var rounds = parseRounds(record.get("rounds"));
    if (rounds.size() == 0 || hold <= 0) {
        return null;
    }
    return {
        "name" => name,
        "tableType" => tableType,
        "breatheUpSeconds" => breatheUp,
        "holdSeconds" => hold,
        "restSeconds" => rest,
        "rounds" => rounds,
        "week" => 0,
        "sessionIndex" => 0,
        "planKey" => ""
    };
}

function parsePlan(message as Dictionary) as Dictionary? {
    if (asFlag(message.get("locked")) || asFlag(message.get("complete"))) {
        return null;
    }
    var name = asText(message.get("name"));
    var tableType = asText(message.get("tableType"));
    var hold = asInt(message.get("holdSeconds"), 0);
    var rest = asInt(message.get("restSeconds"), 0);
    var rounds = parseRounds(message.get("rounds"));
    if (name == null || (name as String).length() == 0 || tableType == null || hold <= 0 || rounds.size() == 0) {
        return null;
    }
    return {
        "name" => name as String,
        "tableType" => tableType as String,
        "breatheUpSeconds" => asInt(message.get("breatheUpSeconds"), 0),
        "holdSeconds" => hold,
        "restSeconds" => rest,
        "rounds" => rounds,
        "week" => asInt(message.get("week"), 0),
        "sessionIndex" => asInt(message.get("sessionIndex"), 0),
        "planKey" => asTextOr(message.get("planKey"), ""),
        "planWeek" => asInt(message.get("planWeek"), asInt(message.get("week"), 1)),
        "planWeeks" => clampNumber(asInt(message.get("planWeeks"), 1), 1, 52),
        "progress" => clampNumber(asInt(message.get("progress"), 0), 0, 100),
        "planName" => asTextOr(message.get("planName"), "")
    };
}

function parseSyncedAt(value as Object?) as Array<Number> {
    var out = [] as Array<Number>;
    if (!(value instanceof Array)) {
        return out;
    }
    var rows = value as Array;
    for (var i = 0; i < rows.size(); i++) {
        var id = asInt(rows[i], 0);
        if (id > 0) {
            out.add(id);
        }
    }
    return out;
}

function buildCompletion(plan as Dictionary, startedAt as Number, completedAt as Number, samples as Array) as Dictionary {
    var rounds = roundCount(plan);
    var payload = {
        "type" => TYPE_SESSION_COMPLETE,
        "tableType" => asTextOr(plan.get("tableType"), "co2"),
        "holdSeconds" => asInt(plan.get("holdSeconds"), 1),
        "restSeconds" => asInt(plan.get("restSeconds"), 0),
        "roundsCompleted" => rounds,
        "roundsPlanned" => rounds,
        "startedAt" => startedAt,
        "completedAt" => completedAt,
        "source" => SOURCE_WATCH,
        "watchDetail" => WATCH_DETAIL,
        "heartRates" => samples
    } as Dictionary;
    var week = asInt(plan.get("week"), 0);
    var sessionIndex = asInt(plan.get("sessionIndex"), 0);
    if (week > 0 && sessionIndex > 0) {
        payload.put("week", week);
        payload.put("sessionIndex", sessionIndex);
        payload.put("planKey", asTextOr(plan.get("planKey"), ""));
    }
    return payload;
}

function buildWatchTraining(running as Boolean, paused as Boolean, name as String, phase as String, pendingCount as Number, startedAt as Number) as Dictionary {
    var payload = {
        "type" => TYPE_WATCH_TRAINING,
        "running" => running,
        "paused" => paused,
        "name" => name,
        "phase" => phase,
        "updatedAt" => nowSec(),
        "pendingCount" => pendingCount
    } as Dictionary;
    if (running) {
        payload.put("startedAt", startedAt);
    }
    return payload;
}

function buildHeartRate(bpm as Number, at as Number) as Dictionary {
    return {
        "type" => TYPE_HEART_RATE,
        "bpm" => bpm,
        "at" => at
    };
}

function formatClock(seconds as Number) as String {
    var safe = seconds;
    if (safe < 0) {
        safe = 0;
    }
    var minutes = safe / 60;
    var rest = safe % 60;
    if (rest < 10) {
        return minutes.toString() + ":0" + rest.toString();
    }
    return minutes.toString() + ":" + rest.toString();
}

function phaseColor(title as String, paused as Boolean) as Number {
    if (paused) {
        return COLOR_PAUSED;
    }
    if (title.equals(PHASE_HOLD)) {
        return COLOR_HOLD;
    }
    if (title.equals(PHASE_REST)) {
        return COLOR_REST;
    }
    return COLOR_BREATHE;
}

(:test)
function testBuildCo2Rounds(logger as Logger) as Boolean {
    var rounds = buildCo2Rounds(90, 120, 15, 3);
    logger.debug("co2 n=" + rounds.size());
    if (rounds.size() != 3) {
        return false;
    }
    var first = rounds[0] as Dictionary;
    var last = rounds[2] as Dictionary;
    return asInt(first.get("hold"), 0) == 90
        && asInt(first.get("rest"), 0) == 120
        && asInt(last.get("rest"), 0) == 90;
}

(:test)
function testBuildO2Rounds(logger as Logger) as Boolean {
    var rounds = buildO2Rounds(60, 15, 120, 3);
    if (rounds.size() != 3) {
        return false;
    }
    var last = rounds[2] as Dictionary;
    return asInt(last.get("hold"), 0) == 90 && asInt(last.get("rest"), 0) == 120;
}

(:test)
function testMakePhasesAndCompletion(logger as Logger) as Boolean {
    var plan = defaultCo2Table();
    var phases = makePhases(plan);
    if (phases.size() != 1 + DEFAULT_CO2_ROUNDS * 2) {
        logger.debug("phase count " + phases.size());
        return false;
    }
    var payload = buildCompletion(plan, 1700000000, 1700000100, []);
    return asTextOr(payload.get("watchDetail"), "").equals(WATCH_DETAIL)
        && asInt(payload.get("roundsCompleted"), 0) == DEFAULT_CO2_ROUNDS
        && asInt(payload.get("holdSeconds"), 0) == DEFAULT_CO2_HOLD;
}

(:test)
function testParseSlimSession(logger as Logger) as Boolean {
    var message = {
        "type" => TYPE_NEXT_SESSION,
        "name" => "Week 1 · CO2",
        "tableType" => "co2",
        "breatheUpSeconds" => 60,
        "holdSeconds" => 90,
        "restSeconds" => 120,
        "rounds" => [{"hold" => 90, "rest" => 120}, {"hold" => 90, "rest" => 105}],
        "week" => 1,
        "sessionIndex" => 2,
        "planKey" => "beginner:1:"
    } as Dictionary;
    var plan = parsePlan(message);
    if (plan == null) {
        return false;
    }
    return asInt((plan as Dictionary).get("week"), 0) == 1
        && roundCount(plan as Dictionary) == 2;
}
