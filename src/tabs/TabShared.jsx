import React from "react";

export function MetricCard({ title, value, suffix, progress, accent, controls }) {
    const percent = Math.min(100, Math.max(0, Math.round((progress || 0) * 100)));

    return (
        <div className="metric-card">
            <div className="metric-title">{title}</div>
            <div className="metric-body">
                <div
                    className="mini-ring"
                    style={{
                        background: `conic-gradient(${accent} 0 ${percent}%, rgba(255,255,255,0.08) ${percent}% 100%)`
                    }}>
                    <div className="mini-ring-inner">
                        <span>{percent}%</span>
                    </div>
                </div>
                <div className="metric-value-col">
                    <div className="metric-value-row">
                        <strong>{value}</strong>
                    </div>
                    <small>{suffix}</small>
                    {controls && <div className="metric-controls">{controls}</div>}
                </div>
            </div>
        </div>
    );
}

export function BodyMap({ highlightedParts = {} }) {
    const primaryColor = "#ce0e2d";
    const outlineColor = "#a2a9ad";
    const bodyColor = "#000000";

    const head = (cx) => <ellipse cx={cx} cy={38} rx={19} ry={23} />;
    const torso = (cx) => (
        <path
            d={`M ${cx - 28} 65 Q ${cx - 43} 86 ${cx - 35} 129 Q ${cx - 29} 153 ${cx - 22} 166 L ${cx - 17} 184 L ${cx + 17} 184 L ${cx + 22} 166 Q ${cx + 29} 153 ${cx + 35} 129 Q ${cx + 43} 86 ${cx + 28} 65 Z`}
        />
    );
    const arm = (cx, isLeft) => {
        const dir = isLeft ? -1 : 1;
        return (
            <path
                d={`M ${cx + dir * 28} 70 Q ${cx + dir * 47} 80 ${cx + dir * 43} 109 L ${cx + dir * 38} 156 Q ${cx + dir * 36} 171 ${cx + dir * 27} 169 Q ${cx + dir * 22} 165 ${cx + dir * 25} 151 L ${cx + dir * 30} 107 Q ${cx + dir * 27} 86 ${cx + dir * 19} 76 Z`}
            />
        );
    };
    const leg = (cx, isLeft) => {
        const dir = isLeft ? -1 : 1;
        return (
            <path
                d={`M ${cx + dir * 16} 183 Q ${cx + dir * 30} 205 ${cx + dir * 25} 235 L ${cx + dir * 23} 270 L ${cx + dir * 4} 270 L ${cx + dir * 3} 232 Q ${cx + dir * 4} 204 ${cx + dir * 1} 184 Z`}
            />
        );
    };

    const renderFigure = (cx, isBack) => (
        <g key={cx}>
            <g fill={bodyColor} stroke={outlineColor} strokeWidth="1.5">
                {head(cx)}
                {torso(cx)}
                {arm(cx, true)}
                {arm(cx, false)}
                {leg(cx, true)}
                {leg(cx, false)}
            </g>

            <g
                fill={highlightedParts.Shoulders ? primaryColor : bodyColor}
                stroke={outlineColor}
                strokeWidth="1.5">
                <ellipse cx={cx - 25} cy={74} rx={11} ry={9} />
                <ellipse cx={cx + 25} cy={74} rx={11} ry={9} />
            </g>

            <g
                fill={
                    isBack
                        ? highlightedParts.Back
                            ? primaryColor
                            : bodyColor
                        : highlightedParts.Chest
                          ? primaryColor
                          : bodyColor
                }
                stroke={outlineColor}
                strokeWidth="1.5">
                {isBack ? (
                    <path
                        d={`M ${cx - 26} 84 Q ${cx} 100 ${cx + 26} 84 L ${cx + 22} 130 Q ${cx} 147 ${cx - 22} 130 Z`}
                    />
                ) : (
                    <path
                        d={`M ${cx - 23} 87 Q ${cx - 7} 81 ${cx} 95 Q ${cx + 7} 81 ${cx + 23} 87 L ${cx + 20} 119 Q ${cx} 126 ${cx - 20} 119 Z`}
                    />
                )}
            </g>

            <g
                fill={highlightedParts.Core ? primaryColor : bodyColor}
                stroke={outlineColor}
                strokeWidth="1.5">
                <rect x={cx - 12} y={124} width={24} height={42} rx={8} ry={8} />
            </g>

            <g
                fill={highlightedParts.Legs ? primaryColor : bodyColor}
                stroke={outlineColor}
                strokeWidth="1.5">
                <rect x={cx - 24} y={190} width={18} height={48} rx={7} ry={7} />
                <rect x={cx + 6} y={190} width={18} height={48} rx={7} ry={7} />
            </g>
        </g>
    );

    return (
        <svg viewBox="0 0 300 280" width="300" height="280">
            <text x="85" y="16" fill="#a2a9ad" fontSize="11" fontWeight="700" textAnchor="middle">
                FRONT
            </text>
            <text x="215" y="16" fill="#a2a9ad" fontSize="11" fontWeight="700" textAnchor="middle">
                BACK
            </text>
            {renderFigure(85, false)}
            {renderFigure(215, true)}
        </svg>
    );
}

export function calculateWeekActivity(today, completedDates) {
    const uniqueKeys = new Set(
        (completedDates || []).map((date) => new Date(date).toISOString().slice(0, 10))
    );
    return Array.from({ length: 7 }, (_, index) => {
        const date = new Date(today);
        date.setDate(today.getDate() - (6 - index));
        return uniqueKeys.has(date.toISOString().slice(0, 10));
    });
}

export function calculateBodyMapStatus(quickStart) {
    const map = { Chest: false, Back: false, Legs: false, Core: false, Shoulders: false };
    const allExercises = Object.values(quickStart || {}).flat();

    for (const exercise of allExercises) {
        const name = (exercise?.name || "").trim().toLowerCase();
        const hasMeaningfulData =
            Array.isArray(exercise?.setEntries) &&
            exercise.setEntries.some(
                (set) =>
                    set &&
                    (String(set.weight ?? "").trim() !== "" || String(set.reps ?? "").trim() !== "")
            );

        if (!name || !hasMeaningfulData) continue;

        if (
            name.includes("bench") ||
            name.includes("press") ||
            name.includes("fly") ||
            name.includes("chest")
        ) {
            map.Chest = true;
        }
        if (
            name.includes("row") ||
            name.includes("pull") ||
            name.includes("back") ||
            name.includes("lat")
        ) {
            map.Back = true;
        }
        if (
            name.includes("squat") ||
            name.includes("lunge") ||
            name.includes("leg") ||
            name.includes("deadlift") ||
            name.includes("run") ||
            name.includes("treadmill")
        ) {
            map.Legs = true;
        }
        if (
            name.includes("core") ||
            name.includes("plank") ||
            name.includes("crunch") ||
            name.includes("abs")
        ) {
            map.Core = true;
        }
        if (name.includes("shoulder") || name.includes("raise") || name.includes("overhead")) {
            map.Shoulders = true;
        }
    }

    return map;
}

export function calculateWorkoutStreak(completedDates, plannedWorkouts = {}) {
    const validDays = new Set();

    (completedDates || []).forEach((date) => {
        validDays.add(new Date(date).toISOString().slice(0, 10));
    });

    Object.entries(plannedWorkouts || {}).forEach(([date, workoutName]) => {
        if (workoutName === "Rest day") {
            validDays.add(new Date(date).toISOString().slice(0, 10));
        }
    });

    if (validDays.size === 0) return 0;

    const cursor = new Date();
    cursor.setHours(0, 0, 0, 0);

    if (!validDays.has(cursor.toISOString().slice(0, 10))) {
        cursor.setDate(cursor.getDate() - 1);
    }

    let streak = 0;
    while (validDays.has(cursor.toISOString().slice(0, 10))) {
        streak += 1;
        cursor.setDate(cursor.getDate() - 1);
    }

    return streak >= 2 ? streak : 0;
}

export function StreakCard({ completedDates, plannedWorkouts }) {
    const dayLabels = ["S", "M", "T", "W", "T", "F", "S"];
    const today = new Date();
    const activeDays = calculateWeekActivity(today, completedDates);
    const streakCount = calculateWorkoutStreak(completedDates, plannedWorkouts);

    return (
        <div className="streak-card">
            <h3>Streak Counter</h3>
            <div className="streak-days">
                {dayLabels.map((day, index) => {
                    const isActive = activeDays[index];
                    return (
                        <div
                            key={`${day}-${index}`}
                            className={isActive ? "streak-dot active" : "streak-dot"}>
                            {day}
                        </div>
                    );
                })}
            </div>
            <div className="streak-label">{streakCount}-day streak!</div>
        </div>
    );
}
