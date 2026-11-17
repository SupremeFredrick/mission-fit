function localDateKey(date) {
    if (!(date instanceof Date) || Number.isNaN(date.getTime())) return null;

    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
}

export function getWorkoutDateKey(value) {
    if (typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value)) {
        const date = new Date(`${value}T00:00:00`);
        return localDateKey(date) === value ? value : null;
    }

    return localDateKey(value instanceof Date ? value : new Date(value));
}

export function calculateWeekActivity(today, completedDates) {
    const completedDays = new Set((completedDates || []).map(getWorkoutDateKey).filter(Boolean));
    const firstDay = new Date(today);
    firstDay.setHours(0, 0, 0, 0);
    firstDay.setDate(firstDay.getDate() - firstDay.getDay());

    return Array.from({ length: 7 }, (_, index) => {
        const date = new Date(firstDay);
        date.setDate(firstDay.getDate() + index);
        return completedDays.has(localDateKey(date));
    });
}

export function calculateWorkoutStreak(completedDates, plannedWorkouts = {}, today = new Date()) {
    const validDays = new Set((completedDates || []).map(getWorkoutDateKey).filter(Boolean));

    Object.entries(plannedWorkouts || {}).forEach(([date, workoutName]) => {
        if (workoutName === "Rest day") {
            const dateKey = getWorkoutDateKey(date);
            if (dateKey) validDays.add(dateKey);
        }
    });

    const todayKey = localDateKey(today);
    if (!todayKey || validDays.size === 0) return 0;

    const cursor = new Date(today);
    cursor.setHours(0, 0, 0, 0);
    if (!validDays.has(todayKey)) cursor.setDate(cursor.getDate() - 1);

    let streak = 0;
    while (validDays.has(localDateKey(cursor))) {
        streak += 1;
        cursor.setDate(cursor.getDate() - 1);
    }

    return streak;
}
