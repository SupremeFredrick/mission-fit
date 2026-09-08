import React, { useEffect, useMemo, useState } from "react";
import logo from "./assets/mission_fit_logo.png";

const STORAGE_KEY = "mission_fit_web_state_v1";
const navItems = ["Home", "Workouts", "Food", "Settings"];
const weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"];
const defaultQuickStart = {
    Push: [
        { name: "Bench Press", weight: "80", reps: "8" },
        { name: "Incline Press", weight: "65", reps: "10" }
    ],
    Pull: [
        { name: "Rows", weight: "60", reps: "10" },
        { name: "Lat Pulldown", weight: "50", reps: "12" }
    ],
    Legs: [
        { name: "Squat", weight: "100", reps: "8" },
        { name: "Romanian Deadlift", weight: "90", reps: "8" }
    ],
    Run: [{ name: "Treadmill", weight: "0", reps: "15" }]
};

const defaultProfile = {
    name: "Alex",
    age: "27",
    heightValue: 180,
    heightUnit: "cm",
    weightValue: 74,
    weightUnit: "kg",
    sex: "Male",
    activityLevel: "Moderate",
    goal: "Cut"
};

const defaultFoodEntries = [
    { id: 1, name: "Greek yogurt, berries, oats", calories: 320, protein: 24, carbs: 28, fat: 8 },
    { id: 2, name: "Chicken rice bowl", calories: 540, protein: 42, carbs: 55, fat: 16 },
    { id: 3, name: "Protein shake", calories: 240, protein: 28, carbs: 12, fat: 4 }
];

const defaultCompletedWorkoutDates = [
    new Date(Date.now() - 3 * 86400000),
    new Date(Date.now() - 2 * 86400000),
    new Date(Date.now() - 86400000),
    new Date()
];

const initialWorkoutPlan = () => {
    const today = new Date();
    return { [dateKey(today)]: "Push Day" };
};

function dateKey(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
}

function formatDisplayDate(date) {
    const day = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][
        date.getDay()
    ];
    const month = new Intl.DateTimeFormat("en-US", { month: "long" }).format(date);
    return `${day}, ${date.getDate()} ${month} ${date.getFullYear()}`;
}

function readStoredState() {
    try {
        const cached = window.localStorage.getItem(STORAGE_KEY);
        if (!cached) {
            return null;
        }
        return JSON.parse(cached);
    } catch {
        return null;
    }
}

function getActivityMultiplier(level) {
    switch (String(level).toLowerCase()) {
        case "sedentary":
            return 1.2;
        case "light":
            return 1.375;
        case "moderate":
            return 1.55;
        case "active":
            return 1.725;
        case "extreme":
            return 1.98;
        default:
            return 1.55;
    }
}

function parseNumeric(value) {
    const parsed = Number.parseFloat(value ?? "0");
    return Number.isFinite(parsed) ? parsed : 0;
}

function convertToMetricValue(value, unit) {
    const numeric = parseNumeric(value);
    switch (String(unit).toLowerCase()) {
        case "in":
            return numeric * 2.54;
        case "lbs":
            return numeric * 0.45359237;
        case "cm":
        case "kg":
        default:
            return numeric;
    }
}

function calculateBmr(profile) {
    const weightKg = convertToMetricValue(profile.weightValue, profile.weightUnit);
    const heightCm = convertToMetricValue(profile.heightValue, profile.heightUnit);
    const age = parseNumeric(profile.age);

    if (
        String(profile.sex).toLowerCase() === "female" ||
        String(profile.sex).toLowerCase() === "woman"
    ) {
        return 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }

    return 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
}

function calculateCalorieGoal(profile, goal) {
    const tdee = calculateBmr(profile) * getActivityMultiplier(profile.activityLevel);
    switch (String(goal)) {
        case "Cut":
            return tdee - 400;
        case "Bulk":
            return tdee + 400;
        case "Maintain":
        default:
            return tdee;
    }
}

function calculateWaterGoal(profile) {
    const weightKg = convertToMetricValue(profile.weightValue, profile.weightUnit);
    const heightCm = convertToMetricValue(profile.heightValue, profile.heightUnit);
    const age = parseNumeric(profile.age);
    const activityAdjustment =
        {
            sedentary: 0,
            light: 0.2,
            moderate: 0.4,
            active: 0.6,
            extreme: 0.8
        }[String(profile.activityLevel).toLowerCase()] ?? 0.4;

    const sexAdjustment = String(profile.sex).toLowerCase() === "female" ? 0 : 0.2;
    const heightAdjustment = (heightCm - 170) * 0.002;
    const ageAdjustment = age >= 55 ? -0.2 : age >= 35 ? -0.1 : 0;

    return (
        weightKg * 0.033 +
        activityAdjustment +
        sexAdjustment +
        heightAdjustment +
        ageAdjustment +
        1.8
    );
}

function getDailyQuote() {
    const quotes = [
        {
            text: "The impediment to action advances action. What stands in the way becomes the way.",
            author: "Marcus Aurelius"
        },
        {
            text: "Discipline is choosing between what you want most and what you want right now.",
            author: "Abraham Lincoln"
        },
        {
            text: "Success is the sum of small efforts, repeated day in and day out.",
            author: "Robert Collier"
        },
        { text: "Take rest; a field that has rested gives a bountiful crop.", author: "Ovid" }
    ];
    return quotes[new Date().getDate() % quotes.length];
}

function getCalendarDates() {
    const today = new Date();
    const start = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 6);
    return Array.from({ length: 14 }, (_, index) => {
        const next = new Date(start);
        next.setDate(start.getDate() + index);
        return next;
    });
}

function calculateWorkoutStreak(completedDates) {
    const unique = [...new Set(completedDates.map((date) => dateKey(new Date(date))))];
    const sorted = unique.sort((a, b) => new Date(b) - new Date(a));
    let streak = 0;
    const today = new Date();
    let cursor = new Date(today.getFullYear(), today.getMonth(), today.getDate());

    while (sorted.includes(dateKey(cursor))) {
        streak += 1;
        cursor.setDate(cursor.getDate() - 1);
    }

    return streak;
}

function MetricCard({ title, value, suffix, progress, accent, controls }) {
    const percent = Math.min(100, Math.max(0, Math.round((progress || 0) * 100)));

    return (
        <article className="metric-card card">
            <div className="metric-head">
                <span>{title}</span>
                <div
                    className="mini-ring"
                    style={{
                        background: `conic-gradient(${accent} 0 ${percent}%, rgba(255,255,255,0.08) ${percent}% 100%)`
                    }}>
                    <span>{percent}%</span>
                </div>
            </div>
            <div className="metric-value-row">
                <strong>{value}</strong>
                <small>{suffix}</small>
            </div>
            {controls && <div className="metric-controls">{controls}</div>}
        </article>
    );
}

function AppLoadingScreen() {
    return (
        <main className="app-loading-screen" aria-label="Loading Mission Fit">
            <div className="loading-spinner" aria-hidden="true" />
        </main>
    );
}

export default function App() {
    const stored = readStoredState();
    const initialState = stored ?? {
        profile: defaultProfile,
        waterConsumed: 2.0,
        goal: "Cut",
        foodEntries: defaultFoodEntries,
        plannedWorkouts: initialWorkoutPlan(),
        quickStart: defaultQuickStart,
        selectedTab: "Home",
        selectedWorkoutDate: dateKey(new Date())
    };

    const [profile, setProfile] = useState(initialState.profile);
    const [waterConsumed, setWaterConsumed] = useState(initialState.waterConsumed);
    const [goal, setGoal] = useState(initialState.goal);
    const [foodEntries, setFoodEntries] = useState(initialState.foodEntries);
    const [plannedWorkouts, setPlannedWorkouts] = useState(initialState.plannedWorkouts);
    const [quickStart, setQuickStart] = useState(initialState.quickStart);
    const [selectedTab, setSelectedTab] = useState(initialState.selectedTab);
    const [selectedWorkoutDate, setSelectedWorkoutDate] = useState(
        initialState.selectedWorkoutDate
    );
    const [foodForm, setFoodForm] = useState({
        name: "",
        calories: "320",
        protein: "24",
        carbs: "28",
        fat: "8"
    });
    const [newPresetName, setNewPresetName] = useState("Push Day");
    const [newPresetExercises, setNewPresetExercises] = useState([
        { name: "Bench Press", weight: "80", reps: "8" },
        { name: "Incline Press", weight: "65", reps: "10" }
    ]);
    const [completedWorkoutDates, setCompletedWorkoutDates] = useState(
        defaultCompletedWorkoutDates
    );
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        const loadingTimer = window.setTimeout(() => setIsLoading(false), 650);
        return () => window.clearTimeout(loadingTimer);
    }, []);

    const dailyQuote = useMemo(() => getDailyQuote(), []);

    const calorieGoal = useMemo(() => calculateCalorieGoal(profile, goal), [profile, goal]);
    const waterGoal = useMemo(() => calculateWaterGoal(profile), [profile]);
    const totalCalories = useMemo(
        () => foodEntries.reduce((sum, item) => sum + Number(item.calories || 0), 0),
        [foodEntries]
    );
    const totalProtein = useMemo(
        () => foodEntries.reduce((sum, item) => sum + Number(item.protein || 0), 0),
        [foodEntries]
    );
    const totalCarbs = useMemo(
        () => foodEntries.reduce((sum, item) => sum + Number(item.carbs || 0), 0),
        [foodEntries]
    );
    const totalFat = useMemo(
        () => foodEntries.reduce((sum, item) => sum + Number(item.fat || 0), 0),
        [foodEntries]
    );
    const caloriesLeft = Math.max(0, calorieGoal - totalCalories);
    const calorieProgress = Math.min(1, totalCalories / Math.max(1, calorieGoal));
    const waterProgress = Math.min(1, waterConsumed / Math.max(1, waterGoal));

    useEffect(() => {
        const payload = {
            profile,
            waterConsumed,
            goal,
            foodEntries,
            plannedWorkouts,
            quickStart,
            selectedTab,
            selectedWorkoutDate
        };
        window.localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
    }, [
        profile,
        waterConsumed,
        goal,
        foodEntries,
        plannedWorkouts,
        quickStart,
        selectedTab,
        selectedWorkoutDate
    ]);

    const todayWorkout = plannedWorkouts[dateKey(new Date())] ?? "Rest day";
    const calendarDates = useMemo(() => getCalendarDates(), []);
    const streakCount = useMemo(
        () => calculateWorkoutStreak(completedWorkoutDates),
        [completedWorkoutDates]
    );

    function handleAddFoodEntry(event) {
        event.preventDefault();
        if (!foodForm.name.trim()) return;

        const nextEntry = {
            id: Date.now(),
            name: foodForm.name.trim(),
            calories: Number(foodForm.calories || 0),
            protein: Number(foodForm.protein || 0),
            carbs: Number(foodForm.carbs || 0),
            fat: Number(foodForm.fat || 0)
        };

        setFoodEntries((current) => [nextEntry, ...current]);
        setFoodForm({ name: "", calories: "320", protein: "24", carbs: "28", fat: "8" });
    }

    function handleRemoveFoodEntry(id) {
        setFoodEntries((current) => current.filter((item) => item.id !== id));
    }

    function handleGoalChange(nextGoal) {
        setGoal(nextGoal);
    }

    function handlePlanWorkout(date, workoutName) {
        setSelectedWorkoutDate(dateKey(date));
        setPlannedWorkouts((current) => ({ ...current, [dateKey(date)]: workoutName }));
    }

    function handleAddPreset() {
        const name = (newPresetName || "Custom Workout").trim();
        if (!name) return;
        setQuickStart((current) => ({ ...current, [name]: newPresetExercises }));
        setNewPresetName(name);
    }

    function renderHomeTab() {
        return (
            <>
                <div className="date-row">
                    <span>
                        {new Date().toLocaleDateString("en-US", { weekday: "long" })},{" "}
                        {new Date().toLocaleDateString("en-US", {
                            day: "numeric",
                            month: "long",
                            year: "numeric"
                        })}
                    </span>
                </div>

                <section className="hero card panel">
                    <div className="hero-header">
                        <div>
                            <p className="eyebrow">Welcome back</p>
                            <h1>Hello, {profile.name}</h1>
                        </div>
                        <button type="button" className="primary-button">
                            + Add
                        </button>
                    </div>

                    <div className="profile-meta">
                        <span>{profile.age} years</span>
                        <span>
                            {profile.heightValue} {profile.heightUnit}
                        </span>
                        <span>
                            {profile.weightValue} {profile.weightUnit}
                        </span>
                    </div>

                    <div className="progress-panel">
                        <div className="ring-wrap">
                            <div
                                className="ring"
                                style={{
                                    background: `conic-gradient(#ce0e2d 0 ${Math.min(100, Math.round(calorieProgress * 100))}%, rgba(255,255,255,0.08) ${Math.min(100, Math.round(calorieProgress * 100))}% 100%)`
                                }}>
                                <span>{Math.min(100, Math.round(calorieProgress * 100))}%</span>
                            </div>
                        </div>
                        <div className="progress-copy">
                            <strong>Daily goal</strong>
                            <p>
                                {caloriesLeft > 0
                                    ? `${Math.round(caloriesLeft)} kcal left today.`
                                    : "Calorie target hit for today."}
                            </p>
                        </div>
                    </div>
                </section>

                <section className="stats-grid" aria-label="Progress metrics">
                    <MetricCard
                        title="Calories Burned"
                        value={String(Math.round(totalCalories * 0.7))}
                        suffix="kcal"
                        progress={Math.min(1, (totalCalories * 0.7) / Math.max(1, 2400))}
                        accent="#ce0e2d"
                    />
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
                        progress={waterProgress}
                        accent="#ffffff"
                        controls={
                            <>
                                <button
                                    type="button"
                                    className="tiny-button"
                                    onClick={() =>
                                        setWaterConsumed((current) =>
                                            Math.max(0, Number((current - 0.25).toFixed(2)))
                                        )
                                    }>
                                    −
                                </button>
                                <button
                                    type="button"
                                    className="tiny-button"
                                    onClick={() =>
                                        setWaterConsumed((current) =>
                                            Math.min(10, Number((current + 0.25).toFixed(2)))
                                        )
                                    }>
                                    +
                                </button>
                            </>
                        }
                    />
                    <MetricCard
                        title="Steps Taken"
                        value={String(7200)}
                        suffix=" / 10000"
                        progress={0.72}
                        accent="#ce0e2d"
                    />
                </section>

                <section className="panel card streak-card">
                    <div className="section-heading compact">
                        <div>
                            <p className="eyebrow">Streak</p>
                            <h2>Streak Counter</h2>
                        </div>
                    </div>
                    <div className="streak-days">
                        {["S", "M", "T", "W", "T", "F", "S"].map((day, index) => {
                            const isActive = completedWorkoutDates.some(
                                (date) =>
                                    dateKey(date) ===
                                    dateKey(new Date(Date.now() - (3 - index) * 86400000))
                            );
                            return (
                                <span
                                    key={`${day}-${index}`}
                                    className={isActive ? "streak-dot active" : "streak-dot"}>
                                    {day}
                                </span>
                            );
                        })}
                    </div>
                    <strong className="streak-label">{streakCount}-day streak!</strong>
                </section>

                <section className="panel card quickstart-card">
                    <div className="section-heading compact">
                        <div>
                            <p className="eyebrow">Quick start</p>
                            <h2>Workout plan</h2>
                        </div>
                    </div>
                    <div className="quickstart-list">
                        {Object.entries(quickStart)
                            .slice(0, 3)
                            .map(([name, exercises]) => (
                                <div key={name} className="quickstart-row">
                                    <div className="quickstart-copy">
                                        <strong>{name}</strong>
                                        <span>
                                            {exercises.map((exercise) => exercise.name).join(" / ")}
                                        </span>
                                    </div>
                                    <span className="quickstart-time">
                                        {45 + Object.keys(quickStart).indexOf(name) * 7} min
                                    </span>
                                </div>
                            ))}
                    </div>
                </section>

                <section className="panel card">
                    <div className="section-heading compact">
                        <div>
                            <p className="eyebrow">Insight</p>
                            <h2>Daily perspective</h2>
                        </div>
                    </div>
                    <blockquote className="quote-block">
                        “{dailyQuote.text}”<footer>— {dailyQuote.author}</footer>
                    </blockquote>
                </section>
            </>
        );
    }

    function renderWorkoutsTab() {
        const date = new Date(selectedWorkoutDate);
        const currentWorkoutName = plannedWorkouts[selectedWorkoutDate] ?? "Rest day";

        return (
            <>
                <div className="panel card workout-summary">
                    <div className="section-heading compact">
                        <div>
                            <p className="eyebrow">Workout</p>
                            <h2>{formatDisplayDate(date)}</h2>
                        </div>
                        <button
                            type="button"
                            className="primary-button small"
                            onClick={() =>
                                handlePlanWorkout(
                                    new Date(selectedWorkoutDate),
                                    Object.keys(quickStart)[0]
                                )
                            }>
                            {currentWorkoutName === "Rest day" ? "Plan" : "Start"}
                        </button>
                    </div>

                    <div className="today-plan">
                        <strong>{currentWorkoutName}</strong>
                        <span>{Object.keys(quickStart).length} preset plans ready</span>
                    </div>
                </div>

                <div className="panel card">
                    <div className="section-heading compact">
                        <div>
                            <p className="eyebrow">Calendar</p>
                            <h2>Plan a workout</h2>
                        </div>
                    </div>

                    <div className="calendar-grid">
                        {weekdayLabels.map((label) => (
                            <span key={label} className="weekday-label">
                                {label}
                            </span>
                        ))}
                        {calendarDates.map((day) => {
                            const key = dateKey(day);
                            const isSelected = selectedWorkoutDate === key;
                            const planned = plannedWorkouts[key];
                            return (
                                <button
                                    key={key}
                                    type="button"
                                    className={
                                        isSelected ? "calendar-day selected" : "calendar-day"
                                    }
                                    onClick={() => setSelectedWorkoutDate(key)}>
                                    <span>{day.getDate()}</span>
                                    {planned ? <i className="calendar-dot" /> : null}
                                </button>
                            );
                        })}
                    </div>
                </div>

                <div className="panel card">
                    <div className="section-heading compact">
                        <div>
                            <p className="eyebrow">Quick start</p>
                            <h2>Pick a workout</h2>
                        </div>
                    </div>
                    <div className="preset-list">
                        {Object.entries(quickStart).map(([name, exercises]) => (
                            <button
                                key={name}
                                type="button"
                                className={
                                    currentWorkoutName === name
                                        ? "preset-item active"
                                        : "preset-item"
                                }
                                onClick={() =>
                                    handlePlanWorkout(new Date(selectedWorkoutDate), name)
                                }>
                                <strong>{name}</strong>
                                <span>{exercises.length} exercises</span>
                            </button>
                        ))}
                    </div>
                </div>

                <div className="panel card">
                    <div className="section-heading compact">
                        <div>
                            <p className="eyebrow">Create plan</p>
                            <h2>Custom workout</h2>
                        </div>
                    </div>
                    <div className="custom-workout-form">
                        <input
                            type="text"
                            value={newPresetName}
                            onChange={(event) => setNewPresetName(event.target.value)}
                            placeholder="Workout name"
                        />
                        <div className="exercise-editor">
                            {newPresetExercises.map((exercise, index) => (
                                <div key={`${exercise.name}-${index}`} className="exercise-row">
                                    <input
                                        type="text"
                                        value={exercise.name}
                                        onChange={(event) => {
                                            const updated = [...newPresetExercises];
                                            updated[index] = {
                                                ...updated[index],
                                                name: event.target.value
                                            };
                                            setNewPresetExercises(updated);
                                        }}
                                    />
                                    <input
                                        type="text"
                                        value={exercise.weight}
                                        onChange={(event) => {
                                            const updated = [...newPresetExercises];
                                            updated[index] = {
                                                ...updated[index],
                                                weight: event.target.value
                                            };
                                            setNewPresetExercises(updated);
                                        }}
                                    />
                                    <input
                                        type="text"
                                        value={exercise.reps}
                                        onChange={(event) => {
                                            const updated = [...newPresetExercises];
                                            updated[index] = {
                                                ...updated[index],
                                                reps: event.target.value
                                            };
                                            setNewPresetExercises(updated);
                                        }}
                                    />
                                </div>
                            ))}
                        </div>
                        <button type="button" className="primary-button" onClick={handleAddPreset}>
                            Save workout
                        </button>
                    </div>
                </div>
            </>
        );
    }

    function renderFoodTab() {
        return (
            <>
                <section className="panel card food-summary">
                    <div className="section-heading compact">
                        <div>
                            <p className="eyebrow">Nutrition</p>
                            <h2>Daily calories</h2>
                        </div>
                        <span className="goal-pill">{goal}</span>
                    </div>

                    <div className="food-ring-row">
                        <div
                            className="food-ring"
                            style={{
                                background: `conic-gradient(#ce0e2d 0 ${Math.min(100, Math.round(calorieProgress * 100))}%, rgba(255,255,255,0.08) ${Math.min(100, Math.round(calorieProgress * 100))}% 100%)`
                            }}>
                            <div className="food-ring-inner">
                                <strong>{Math.round(caloriesLeft)}</strong>
                                <span>kcal left</span>
                            </div>
                        </div>

                        <div className="macro-list">
                            <div>
                                <span>Protein</span>
                                <strong>
                                    {Math.round(totalProtein)} /{" "}
                                    {Math.round((calorieGoal * 0.3) / 4)}g
                                </strong>
                            </div>
                            <div>
                                <span>Carbs</span>
                                <strong>
                                    {Math.round(totalCarbs)} /{" "}
                                    {Math.round((calorieGoal * 0.45) / 4)}g
                                </strong>
                            </div>
                            <div>
                                <span>Fats</span>
                                <strong>
                                    {Math.round(totalFat)} / {Math.round((calorieGoal * 0.25) / 9)}g
                                </strong>
                            </div>
                        </div>
                    </div>
                </section>

                <section className="panel card">
                    <div className="section-heading compact">
                        <div>
                            <p className="eyebrow">Log</p>
                            <h2>Food log</h2>
                        </div>
                    </div>

                    <form className="food-form" onSubmit={handleAddFoodEntry}>
                        <input
                            value={foodForm.name}
                            onChange={(event) =>
                                setFoodForm((current) => ({ ...current, name: event.target.value }))
                            }
                            placeholder="Food name"
                        />
                        <div className="food-row">
                            <input
                                value={foodForm.calories}
                                onChange={(event) =>
                                    setFoodForm((current) => ({
                                        ...current,
                                        calories: event.target.value
                                    }))
                                }
                                placeholder="Calories"
                            />
                            <input
                                value={foodForm.protein}
                                onChange={(event) =>
                                    setFoodForm((current) => ({
                                        ...current,
                                        protein: event.target.value
                                    }))
                                }
                                placeholder="Protein"
                            />
                        </div>
                        <div className="food-row">
                            <input
                                value={foodForm.carbs}
                                onChange={(event) =>
                                    setFoodForm((current) => ({
                                        ...current,
                                        carbs: event.target.value
                                    }))
                                }
                                placeholder="Carbs"
                            />
                            <input
                                value={foodForm.fat}
                                onChange={(event) =>
                                    setFoodForm((current) => ({
                                        ...current,
                                        fat: event.target.value
                                    }))
                                }
                                placeholder="Fat"
                            />
                        </div>
                        <button type="submit" className="primary-button">
                            Add food
                        </button>
                    </form>

                    <div className="food-list">
                        {foodEntries.map((item) => (
                            <div key={item.id} className="food-item">
                                <div className="food-item-copy">
                                    <strong>{item.name}</strong>
                                    <span>
                                        {item.calories} kcal · P {item.protein}g · C {item.carbs}g ·
                                        F {item.fat}g
                                    </span>
                                </div>
                                <button
                                    type="button"
                                    className="remove-button"
                                    onClick={() => handleRemoveFoodEntry(item.id)}>
                                    ×
                                </button>
                            </div>
                        ))}
                    </div>
                </section>
            </>
        );
    }

    function renderSettingsTab() {
        return (
            <>
                <section className="panel card">
                    <div className="section-heading compact">
                        <div>
                            <p className="eyebrow">Profile</p>
                            <h2>Update details</h2>
                        </div>
                    </div>

                    <div className="settings-form">
                        <label>
                            <span>Name</span>
                            <input
                                value={profile.name}
                                onChange={(event) =>
                                    setProfile((current) => ({
                                        ...current,
                                        name: event.target.value
                                    }))
                                }
                            />
                        </label>
                        <label>
                            <span>Age</span>
                            <input
                                value={profile.age}
                                onChange={(event) =>
                                    setProfile((current) => ({
                                        ...current,
                                        age: event.target.value
                                    }))
                                }
                            />
                        </label>
                        <div className="inline-field">
                            <label>
                                <span>Height</span>
                                <input
                                    value={profile.heightValue}
                                    onChange={(event) =>
                                        setProfile((current) => ({
                                            ...current,
                                            heightValue: Number(event.target.value || 0)
                                        }))
                                    }
                                />
                            </label>
                            <select
                                value={profile.heightUnit}
                                onChange={(event) =>
                                    setProfile((current) => ({
                                        ...current,
                                        heightUnit: event.target.value
                                    }))
                                }>
                                <option value="cm">cm</option>
                                <option value="in">in</option>
                            </select>
                        </div>
                        <div className="inline-field">
                            <label>
                                <span>Weight</span>
                                <input
                                    value={profile.weightValue}
                                    onChange={(event) =>
                                        setProfile((current) => ({
                                            ...current,
                                            weightValue: Number(event.target.value || 0)
                                        }))
                                    }
                                />
                            </label>
                            <select
                                value={profile.weightUnit}
                                onChange={(event) =>
                                    setProfile((current) => ({
                                        ...current,
                                        weightUnit: event.target.value
                                    }))
                                }>
                                <option value="kg">kg</option>
                                <option value="lbs">lbs</option>
                            </select>
                        </div>
                        <label>
                            <span>Sex</span>
                            <select
                                value={profile.sex}
                                onChange={(event) =>
                                    setProfile((current) => ({
                                        ...current,
                                        sex: event.target.value
                                    }))
                                }>
                                <option value="Male">Male</option>
                                <option value="Female">Female</option>
                            </select>
                        </label>
                        <label>
                            <span>Activity level</span>
                            <select
                                value={profile.activityLevel}
                                onChange={(event) =>
                                    setProfile((current) => ({
                                        ...current,
                                        activityLevel: event.target.value
                                    }))
                                }>
                                <option value="Sedentary">Sedentary</option>
                                <option value="Light">Light</option>
                                <option value="Moderate">Moderate</option>
                                <option value="Active">Active</option>
                                <option value="Extreme">Extreme</option>
                            </select>
                        </label>
                        <label>
                            <span>Goal</span>
                            <select
                                value={goal}
                                onChange={(event) => handleGoalChange(event.target.value)}>
                                <option value="Cut">Cut</option>
                                <option value="Maintain">Maintain</option>
                                <option value="Bulk">Bulk</option>
                            </select>
                        </label>
                    </div>
                </section>
            </>
        );
    }

    if (isLoading) {
        return <AppLoadingScreen />;
    }

    return (
        <div className="missionfit-app">
            <div className="phone-shell">
                <header className="topbar">
                    <div className="brand-wrap" aria-label="Mission Fit brand">
                        <img src={logo} alt="Mission Fit logo" className="brand-logo" />
                    </div>
                    <button type="button" className="icon-button" aria-label="Activity sync">
                        ⏱
                    </button>
                </header>

                <main className="content">
                    {selectedTab === "Home" && renderHomeTab()}
                    {selectedTab === "Workouts" && renderWorkoutsTab()}
                    {selectedTab === "Food" && renderFoodTab()}
                    {selectedTab === "Settings" && renderSettingsTab()}
                </main>

                <nav className="bottom-nav" aria-label="Main navigation">
                    {navItems.map((label, index) => (
                        <button
                            key={label}
                            type="button"
                            className={selectedTab === label ? "nav-item active" : "nav-item"}
                            onClick={() => setSelectedTab(label)}>
                            <span className="nav-icon" aria-hidden="true">
                                {index === 0 ? "⌂" : index === 1 ? "◫" : index === 2 ? "◍" : "⚙"}
                            </span>
                            <span>{label}</span>
                        </button>
                    ))}
                </nav>
            </div>
        </div>
    );
}
