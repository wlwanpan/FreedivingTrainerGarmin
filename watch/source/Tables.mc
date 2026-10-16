import Toybox.Lang;

function clampNumber(value as Number, minValue as Number, maxValue as Number) as Number {
    if (value < minValue) {
        return minValue;
    }
    if (value > maxValue) {
        return maxValue;
    }
    return value;
}

function buildCo2Rounds(holdSeconds as Number, restStartSeconds as Number, restStepSeconds as Number, rounds as Number) as Array<Dictionary> {
    var count = clampNumber(rounds, 1, MAX_ROUNDS);
    var out = [] as Array<Dictionary>;
    for (var i = 0; i < count; i++) {
        var rest = restStartSeconds - i * restStepSeconds;
        if (rest < 0) {
            rest = 0;
        }
        out.add({
            "hold" => holdSeconds,
            "rest" => rest
        });
    }
    return out;
}

function buildO2Rounds(holdStartSeconds as Number, holdStepSeconds as Number, restSeconds as Number, rounds as Number) as Array<Dictionary> {
    var count = clampNumber(rounds, 1, MAX_ROUNDS);
    var out = [] as Array<Dictionary>;
    for (var i = 0; i < count; i++) {
        out.add({
            "hold" => holdStartSeconds + i * holdStepSeconds,
            "rest" => restSeconds
        });
    }
    return out;
}

function defaultCo2Table() as Dictionary {
    return {
        "name" => "CO2",
        "tableType" => "co2",
        "breatheUpSeconds" => DEFAULT_BREATHE_UP,
        "holdSeconds" => DEFAULT_CO2_HOLD,
        "restSeconds" => DEFAULT_CO2_REST,
        "rounds" => buildCo2Rounds(DEFAULT_CO2_HOLD, DEFAULT_CO2_REST, DEFAULT_CO2_STEP, DEFAULT_CO2_ROUNDS),
        "week" => 0,
        "sessionIndex" => 0,
        "planKey" => ""
    };
}

function defaultO2Table() as Dictionary {
    return {
        "name" => "O2",
        "tableType" => "o2",
        "breatheUpSeconds" => DEFAULT_BREATHE_UP,
        "holdSeconds" => DEFAULT_O2_HOLD,
        "restSeconds" => DEFAULT_O2_REST,
        "rounds" => buildO2Rounds(DEFAULT_O2_HOLD, DEFAULT_O2_STEP, DEFAULT_O2_REST, DEFAULT_O2_ROUNDS),
        "week" => 0,
        "sessionIndex" => 0,
        "planKey" => ""
    };
}

function makePhases(plan as Dictionary) as Array<Dictionary> {
    var built = [] as Array<Dictionary>;
    var breathe = asInt(plan.get("breatheUpSeconds"), 0);
    if (breathe > 0) {
        built.add({
            "title" => PHASE_BREATHE,
            "seconds" => breathe,
            "round" => 0
        });
    }
    var rounds = plan.get("rounds");
    if (rounds instanceof Array) {
        var rows = rounds as Array;
        for (var i = 0; i < rows.size(); i++) {
            var row = rows[i];
            if (row instanceof Dictionary) {
                var hold = asInt((row as Dictionary).get("hold"), 0);
                var rest = asInt((row as Dictionary).get("rest"), 0);
                var number = i + 1;
                if (hold > 0) {
                    built.add({
                        "title" => PHASE_HOLD,
                        "seconds" => hold,
                        "round" => number
                    });
                }
                if (rest > 0) {
                    built.add({
                        "title" => PHASE_REST,
                        "seconds" => rest,
                        "round" => number
                    });
                }
            }
        }
    }
    return built;
}

function roundCount(plan as Dictionary) as Number {
    var rounds = plan.get("rounds");
    if (rounds instanceof Array) {
        return (rounds as Array).size();
    }
    return 0;
}
