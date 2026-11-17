import assert from "node:assert/strict";
import { test } from "node:test";
import {
    createWeeklyQuoteSchedule,
    getDailyQuoteForDate,
    getQuoteWeekStart,
    getUniqueQuotePool,
    isValidWeeklyQuoteSchedule
} from "./quoteSchedule.mjs";

const quotes = getUniqueQuotePool(
    Array.from({ length: 10 }, (_, index) => ({
        quote: `Quote ${index}`,
        character: `Character ${index}`,
        anime: `Anime ${index}`
    })).concat([
        { quote: "quote 1", character: "Duplicate", anime: "Duplicate Anime" }
    ])
);

test("deduplicates quotes by text regardless of case", () => {
    assert.equal(quotes.length, 10);
});

test("shuffles seven distinct quotes across a Sunday-to-Saturday week", () => {
    const schedule = createWeeklyQuoteSchedule("2026-01-08", quotes, () => 0.5);
    const weekDates = [
        "2026-01-04",
        "2026-01-05",
        "2026-01-06",
        "2026-01-07",
        "2026-01-08",
        "2026-01-09",
        "2026-01-10"
    ];
    const dailyQuotes = weekDates.map((date) =>
        getDailyQuoteForDate(date, schedule, quotes).text
    );

    assert.equal(new Set(dailyQuotes).size, 7);
    assert.equal(schedule.weekStart, "2026-01-04");
});

test("accepts only a unique schedule for the matching week", () => {
    const schedule = createWeeklyQuoteSchedule("2026-01-08", quotes, () => 0.5);

    assert.equal(isValidWeeklyQuoteSchedule(schedule, "2026-01-10", quotes), true);
    assert.equal(isValidWeeklyQuoteSchedule(schedule, "2026-01-11", quotes), false);
    assert.equal(getQuoteWeekStart("2026-01-11"), "2026-01-11");
});
