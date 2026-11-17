export function normalizeWorkoutInput(value) {
    const normalized = String(value).trim().toUpperCase();
    if (normalized === "BW" || normalized === "B" || normalized === ".") return normalized;
    return /^(?:\d+(?:\.\d*)?|\.\d+)?$/.test(normalized) ? normalized : null;
}

export function isCompleteWorkoutInput(value) {
    return value !== "B" && value !== ".";
}
