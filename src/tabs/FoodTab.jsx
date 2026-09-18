import React from "react";

export default function FoodTab({
    goal,
    calorieProgress,
    caloriesLeft,
    totalProtein,
    totalCarbs,
    totalFat,
    macroProteinTarget,
    macroCarbTarget,
    macroFatTarget,
    foodEntries,
    setFoodSheetInitialEntry,
    setIsFoodSheetOpen,
    setFoodEntries,
    setGoal
}) {
    return (
        <>
            <div className="date-row" style={{ marginTop: "4px" }}>
                <h2>Daily Calories</h2>
                <span className="goal-pill">{goal}</span>
            </div>

            <div className="card panel food-macro-section">
                <div
                    className="food-progress-ring"
                    style={{
                        background: `conic-gradient(#ce0e2d 0 ${Math.min(100, Math.round(calorieProgress * 100))}%, rgba(255,255,255,0.08) ${Math.min(100, Math.round(calorieProgress * 100))}% 100%)`
                    }}>
                    <div className="food-progress-ring-inner">
                        <strong>{Math.round(caloriesLeft)} kcal</strong>
                        <span>left</span>
                    </div>
                </div>

                <div className="macro-column">
                    <div className="macro-row">
                        <span>Protein</span>
                        <small>
                            {Math.round(totalProtein)}/{Math.round(macroProteinTarget)}g
                        </small>
                    </div>
                    <div className="macro-row">
                        <span>Carbs</span>
                        <small>
                            {Math.round(totalCarbs)}/{Math.round(macroCarbTarget)}g
                        </small>
                    </div>
                    <div className="macro-row">
                        <span>Fats</span>
                        <small>
                            {Math.round(totalFat)}/{Math.round(macroFatTarget)}g
                        </small>
                    </div>
                </div>
            </div>

            <div className="card panel food-log-card">
                <div className="food-log-header">
                    <h2>Food Log</h2>
                    <button
                        type="button"
                        className="add-circle-btn"
                        onClick={() => {
                            setFoodSheetInitialEntry(null);
                            setIsFoodSheetOpen(true);
                        }}>
                        <span aria-hidden="true">＋</span>
                    </button>
                </div>

                {foodEntries.length === 0 ? (
                    <p style={{ color: "var(--color-muted)", fontSize: "0.9rem" }}>
                        No food items logged yet.
                    </p>
                ) : (
                    foodEntries.map((item, index) => (
                        <div key={item.id || index} className="food-log-item">
                            <button
                                type="button"
                                className="icon-button"
                                onClick={() => {
                                    setFoodSheetInitialEntry({ ...item, index });
                                    setIsFoodSheetOpen(true);
                                }}>
                                <span aria-hidden="true">✎</span>
                            </button>
                            <div className="food-log-item-content">
                                <div className="food-log-item-info">
                                    <strong>{item.name}</strong>
                                    <span>
                                        {Math.round(item.calories)} kcal · P{" "}
                                        {Math.round(item.protein)}g · C {Math.round(item.carbs)}g ·
                                        F {Math.round(item.fat)}g
                                    </span>
                                </div>
                                <button
                                    type="button"
                                    className="icon-button"
                                    onClick={() =>
                                        setFoodEntries((prev) => prev.filter((_, i) => i !== index))
                                    }>
                                    <span aria-hidden="true">×</span>
                                </button>
                            </div>
                        </div>
                    ))
                )}
            </div>

            <div className="goal-toggle-row">
                {["Cut", "Maintain", "Bulk"].map((g) => (
                    <button
                        key={g}
                        type="button"
                        className={`goal-toggle-btn ${goal === g ? "active" : ""}`}
                        onClick={() => setGoal(g)}>
                        {g}
                    </button>
                ))}
            </div>
        </>
    );
}
