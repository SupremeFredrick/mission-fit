import React from "react";
import { BodyMap, StreakCard } from "./TabShared";

const weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"];

export default function WorkoutsTab({
    todayWorkoutName,
    handleStartWorkout,
    completedWorkoutDates,
    plannedWorkouts,
    calendarDates,
    selectedWorkoutDate,
    setSelectedWorkoutDate,
    setPlannerDate,
    setIsPlannerModalOpen,
    quickStart,
    bodyMapStatus,
    setQuickStart,
    setIsBuilderModalOpen,
    setIsQuickStartModalOpen
}) {
    const now = new Date();
    const weekdayName = now.toLocaleDateString("en-US", { weekday: "long" });
    const dateString = `${weekdayName}, ${now.getDate()} ${now.toLocaleDateString("en-US", { month: "long" })} ${now.getFullYear()}`;

    return (
        <>
            <div className="date-row">
                <span>{dateString}</span>
            </div>

            <div className="today-banner">
                <div className="today-banner-copy">
                    <h3>{weekdayName}</h3>
                    <strong>{todayWorkoutName}</strong>
                </div>
                <button
                    type="button"
                    className="primary-button"
                    onClick={() => handleStartWorkout(todayWorkoutName)}>
                    {todayWorkoutName === "Rest day" ? "Plan" : "Start"}
                </button>
            </div>

            <StreakCard completedDates={completedWorkoutDates} plannedWorkouts={plannedWorkouts} />

            <div className="card calendar-card">
                <div className="calendar-header">
                    <h3>
                        {now.toLocaleDateString("en-US", { month: "long" })} {now.getFullYear()}
                    </h3>
                    <p>Plan a workout</p>
                </div>

                <div className="calendar-weekdays">
                    {weekdayLabels.map((lbl, i) => (
                        <span key={`${lbl}-${i}`}>{lbl}</span>
                    ))}
                </div>

                <div className="calendar-days-grid">
                    {calendarDates.map((day) => {
                        const key = `${day.getFullYear()}-${String(day.getMonth() + 1).padStart(2, "0")}-${String(day.getDate()).padStart(2, "0")}`;
                        const isSelected = selectedWorkoutDate === key;
                        const hasPlan = Boolean(plannedWorkouts[key]);
                        return (
                            <button
                                key={key}
                                type="button"
                                className={`calendar-day-btn ${isSelected ? "selected" : ""} ${hasPlan ? "has-plan" : ""}`}
                                onClick={() => {
                                    setSelectedWorkoutDate(key);
                                    setPlannerDate(day);
                                    setIsPlannerModalOpen(true);
                                }}>
                                {day.getDate()}
                            </button>
                        );
                    })}
                </div>
            </div>

            <div className="card panel body-map-card">
                <h2>Body Map</h2>
                <div className="body-map-container">
                    <BodyMap highlightedParts={bodyMapStatus} />
                </div>
            </div>

            <div className="card panel workout-presets-card">
                <h2>Workouts</h2>
                {Object.keys(quickStart).length === 0 ? (
                    <p
                        style={{
                            color: "var(--color-muted)",
                            fontSize: "0.85rem",
                            textAlign: "center"
                        }}>
                        No workouts created yet.
                    </p>
                ) : (
                    Object.keys(quickStart).map((name) => (
                        <div
                            key={name}
                            className="preset-tile"
                            onClick={() => handleStartWorkout(name)}>
                            <strong>{name}</strong>
                            <button
                                type="button"
                                className="icon-button"
                                onClick={(e) => {
                                    e.stopPropagation();
                                    setQuickStart((prev) => {
                                        const updated = { ...prev };
                                        delete updated[name];
                                        return updated;
                                    });
                                }}>
                                <span aria-hidden="true">×</span>
                            </button>
                        </div>
                    ))
                )}

                <button
                    type="button"
                    className="primary-button"
                    style={{ marginTop: "8px" }}
                    onClick={() => setIsBuilderModalOpen(true)}>
                    <span aria-hidden="true">＋</span> Create workout
                </button>
                <button
                    type="button"
                    className="outlined-button"
                    onClick={() => setIsQuickStartModalOpen(true)}>
                    Edit Quick Start
                </button>
            </div>
        </>
    );
}
