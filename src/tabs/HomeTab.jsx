import React from "react";
import { MetricCard, StreakCard } from "./TabShared";

export default function HomeTab({
    profile,
    totalCalories,
    calorieProgress,
    waterConsumed,
    waterGoal,
    quickStart,
    dailyQuote,
    completedWorkoutDates,
    plannedWorkouts,
    handleStartWorkout,
    setWaterConsumed
}) {
    const now = new Date();
    const dateString = `${now.toLocaleDateString("en-US", { weekday: "long" })}, ${now.getDate()} ${now.toLocaleDateString("en-US", { month: "long" })} ${now.getFullYear()}`;

    return (
        <>
            <div className="date-row">
                <span>{dateString}</span>
            </div>

            <div>
                <h1>Welcome{profile.name ? ` ${profile.name}` : "!"}</h1>
            </div>

            <div className="stats-grid">
                <MetricCard
                    title="Calories Consumed"
                    value={String(Math.round(totalCalories))}
                    suffix="kcal"
                    progress={calorieProgress}
                    accent="#a2a9ad"
                />
                <MetricCard
                    title="Water Intake"
                    value={waterConsumed.toFixed(1)}
                    suffix={`/ ${waterGoal.toFixed(1)} L`}
                    progress={Math.min(1, waterConsumed / Math.max(1, waterGoal))}
                    accent="#ffffff"
                    controls={
                        <>
                            <button
                                type="button"
                                className="tiny-button"
                                onClick={() =>
                                    setWaterConsumed((c) =>
                                        Math.max(0, Number((c - 0.25).toFixed(2)))
                                    )
                                }>
                                −
                            </button>
                            <button
                                type="button"
                                className="tiny-button"
                                onClick={() =>
                                    setWaterConsumed((c) =>
                                        Math.min(10, Number((c + 0.25).toFixed(2)))
                                    )
                                }>
                                +
                            </button>
                        </>
                    }
                />
            </div>

            <StreakCard completedDates={completedWorkoutDates} plannedWorkouts={plannedWorkouts} />

            <div className="card panel quote-card">
                <h2>Daily Perspective</h2>
                <blockquote className="quote-block">“{dailyQuote.text}”</blockquote>
                <div className="quote-author">{dailyQuote.author}</div>
            </div>

            <div className="card panel quickstart-card">
                <h2>Quick Start</h2>
                <div className="quickstart-list">
                    {Object.keys(quickStart).length === 0 ? (
                        <p style={{ color: "var(--color-muted)", fontSize: "0.85rem" }}>
                            No quick start workouts yet.
                        </p>
                    ) : (
                        Object.entries(quickStart).map(([name, exercises], index) => (
                            <div
                                key={name}
                                className="quickstart-row"
                                onClick={() => handleStartWorkout(name)}>
                                <div className="quickstart-copy">
                                    <strong>{name}</strong>
                                </div>
                                <span className="quickstart-time">{45 + index * 5} min</span>
                            </div>
                        ))
                    )}
                </div>
            </div>
        </>
    );
}
