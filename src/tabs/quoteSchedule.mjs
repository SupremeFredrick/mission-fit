const DAYS_PER_WEEK = 7;

function parseDateKey(dateString) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dateString)) {
        throw new RangeError("Quote dates must use YYYY-MM-DD format.");
    }

    const date = new Date(`${dateString}T00:00:00`);
    if (Number.isNaN(date.getTime())) {
        throw new RangeError("Quote date is invalid.");
    }
    return date;
}

function localDateKey(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
}

export function getUniqueQuotePool(quotes) {
    const seen = new Set();

    return quotes.filter((entry) => {
        if (
            typeof entry?.quote !== "string" ||
            !entry.quote.trim() ||
            typeof entry.character !== "string" ||
            typeof entry.anime !== "string"
        ) {
            throw new TypeError("Every anime quote must include quote, character, and anime text.");
        }

        const key = entry.quote.trim().toLocaleLowerCase();
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
    });
}

export function getQuoteWeekStart(dateString) {
    const date = parseDateKey(dateString);
    date.setDate(date.getDate() - date.getDay());
    return localDateKey(date);
}

export function createWeeklyQuoteSchedule(dateString, quotes, random = Math.random) {
    if (quotes.length < DAYS_PER_WEEK) {
        throw new RangeError("At least seven unique anime quotes are required.");
    }

    const shuffledIndices = Array.from({ length: quotes.length }, (_, index) => index);
    for (let index = shuffledIndices.length - 1; index > 0; index -= 1) {
        const randomIndex = Math.min(index, Math.floor(random() * (index + 1)));
        [shuffledIndices[index], shuffledIndices[randomIndex]] = [
            shuffledIndices[randomIndex],
            shuffledIndices[index]
        ];
    }

    return {
        weekStart: getQuoteWeekStart(dateString),
        quoteIndices: shuffledIndices.slice(0, DAYS_PER_WEEK)
    };
}

export function isValidWeeklyQuoteSchedule(schedule, dateString, quotes) {
    if (
        !schedule ||
        schedule.weekStart !== getQuoteWeekStart(dateString) ||
        !Array.isArray(schedule.quoteIndices) ||
        schedule.quoteIndices.length !== DAYS_PER_WEEK ||
        quotes.length < DAYS_PER_WEEK
    ) {
        return false;
    }

    const indices = new Set(schedule.quoteIndices);
    return (
        indices.size === DAYS_PER_WEEK &&
        schedule.quoteIndices.every(
            (index) => Number.isInteger(index) && index >= 0 && index < quotes.length
        )
    );
}

export function getDailyQuoteForDate(dateString, schedule, quotes) {
    if (!isValidWeeklyQuoteSchedule(schedule, dateString, quotes)) {
        throw new RangeError("A valid weekly quote schedule is required for this date.");
    }

    const dayOfWeek = parseDateKey(dateString).getDay();
    const { quote, character, anime } = quotes[schedule.quoteIndices[dayOfWeek]];
    return { text: quote, author: `${character} (${anime})` };
}
