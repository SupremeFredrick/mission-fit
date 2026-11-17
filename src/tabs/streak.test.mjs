import assert from "node:assert/strict";
import { test } from "node:test";
import {
    calculateWeekActivity,
    calculateWorkoutStreak,
    getWorkoutDateKey
} from "./streak.mjs";
import { isCompleteWorkoutInput, normalizeWorkoutInput } from "./workoutInput.mjs";

test("maps completed workouts to their weekdays in the current Sunday-Saturday week", () => {
    const today = new Date(2026, 0, 7, 12);

    assert.deepEqual(
        calculateWeekActivity(today, ["2026-01-04", "2026-01-06"]),
        [true, false, true, false, false, false, false]
    );
});

test("counts a one-day streak and continues it through a planned rest day", () => {
    const today = new Date(2026, 0, 7, 12);

    assert.equal(calculateWorkoutStreak(["2026-01-07"], {}, today), 1);
    assert.equal(
        calculateWorkoutStreak(
            ["2026-01-07", "2026-01-06", "2026-01-04"],
            { "2026-01-05": "Rest day" },
            today
        ),
        4
    );
});

test("resets a streak after a missed day and preserves local date-only keys", () => {
    const today = new Date(2026, 0, 7, 12);

    assert.equal(calculateWorkoutStreak(["2026-01-05"], {}, today), 0);
    assert.equal(getWorkoutDateKey("2026-01-04"), "2026-01-04");
});

test("accepts workout numbers and BW only", () => {
    assert.equal(normalizeWorkoutInput("72.5"), "72.5");
    assert.equal(normalizeWorkoutInput("bw"), "BW");
    assert.equal(normalizeWorkoutInput(""), "");
    assert.equal(normalizeWorkoutInput("72 kg"), null);
    assert.equal(normalizeWorkoutInput("-3"), null);
    assert.equal(isCompleteWorkoutInput(normalizeWorkoutInput("B")), false);
    assert.equal(isCompleteWorkoutInput(normalizeWorkoutInput("BW")), true);
});
