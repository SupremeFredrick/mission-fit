import React, { useEffect, useMemo, useState } from "react";
import { Html5Qrcode } from "html5-qrcode";
import {
    MdHome,
    MdFitnessCenter,
    MdRestaurant,
    MdSettings,
    MdAdd,
    MdClose,
    MdSync,
    MdPlayArrow,
    MdPause,
    MdRestartAlt,
    MdEditNote,
    MdSearch,
    MdQrCodeScanner,
    MdCheckCircle,
    MdRadioButtonUnchecked,
    MdCheck
} from "react-icons/md";
import logo from "./assets/mission_fit_logo.png";

const STORAGE_KEY = "mission_fit_web_state_v4";
const ONBOARDING_COMPLETE_KEY = "mission_fit_onboarding_complete";

const navItems = ["Home", "Workouts", "Food", "Settings"];
const navIcons = [MdHome, MdFitnessCenter, MdRestaurant, MdSettings];
const weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"];

const defaultQuickStart = {};

const defaultProfile = {
    name: "",
    age: "",
    heightValue: "",
    heightUnit: "cm",
    weightValue: "",
    weightUnit: "kg",
    sex: "Male",
    activityLevel: "Moderate"
};

const defaultFoodEntries = [
    { id: 1, name: "Greek yogurt, berries, oats", calories: 320, protein: 24, carbs: 28, fat: 8 },
    { id: 2, name: "Chicken rice bowl", calories: 540, protein: 42, carbs: 55, fat: 16 },
    { id: 3, name: "Protein shake", calories: 240, protein: 28, carbs: 12, fat: 4 }
];

const defaultSavedMeals = [];

function dateKey(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
}

function monthName(monthIndex) {
    const months = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
    ];
    return months[monthIndex];
}

function parseNumeric(value) {
    const parsed = Number.parseFloat(String(value ?? "0").replace(/[^0-9.]/g, ""));
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

function calculateTdee(profile) {
    return calculateBmr(profile) * getActivityMultiplier(profile.activityLevel);
}

function calculateCalorieGoal(profile, goal) {
    const tdee = calculateTdee(profile);
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
            sedentary: 0.0,
            light: 0.2,
            moderate: 0.4,
            active: 0.6,
            extreme: 0.8
        }[String(profile.activityLevel).toLowerCase()] ?? 0.4;

    const sexAdjustment = String(profile.sex).toLowerCase() === "female" ? 0.0 : 0.2;
    const heightAdjustment = (heightCm - 170) * 0.002;
    const ageAdjustment = age >= 55 ? -0.2 : age >= 35 ? -0.1 : 0.0;

    const result =
        weightKg * 0.033 + activityAdjustment + sexAdjustment + heightAdjustment + ageAdjustment;
    return Math.min(5.0, Math.max(1.5, result));
}

function calculateWorkoutStreak(completedDates) {
    if (!completedDates || completedDates.length === 0) return 0;
    const uniqueKeys = new Set(completedDates.map((date) => dateKey(new Date(date))));
    let cursor = new Date();
    cursor.setHours(0, 0, 0, 0);

    if (!uniqueKeys.has(dateKey(cursor))) {
        cursor.setDate(cursor.getDate() - 1);
    }

    let streak = 0;
    while (uniqueKeys.has(dateKey(cursor))) {
        streak += 1;
        cursor.setDate(cursor.getDate() - 1);
    }
    return streak >= 2 ? streak : 0;
}

function calculateWeekActivity(today, completedDates) {
    const uniqueKeys = new Set((completedDates || []).map((date) => dateKey(new Date(date))));
    return Array.from({ length: 7 }, (_, index) => {
        const date = new Date(today);
        date.setDate(today.getDate() - (6 - index));
        return uniqueKeys.has(dateKey(date));
    });
}

function calculateBodyMapStatus(quickStart) {
    const map = { Chest: false, Back: false, Legs: false, Core: false, Shoulders: false };
    const allExercises = Object.values(quickStart || {}).flat();

    for (const ex of allExercises) {
        const name = (ex.name || "").toLowerCase();
        if (
            name.includes("bench") ||
            name.contains?.("press") ||
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

function BodyMap({ highlightedParts = {} }) {
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

            {/* Shoulders */}
            <g
                fill={highlightedParts.Shoulders ? primaryColor : bodyColor}
                stroke={outlineColor}
                strokeWidth="1.5">
                <ellipse cx={cx - 25} cy={74} rx={11} ry={9} />
                <ellipse cx={cx + 25} cy={74} rx={11} ry={9} />
            </g>

            {/* Chest / Back */}
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

            {/* Core */}
            <g
                fill={highlightedParts.Core ? primaryColor : bodyColor}
                stroke={outlineColor}
                strokeWidth="1.5">
                <rect x={cx - 12} y={124} width={24} height={42} rx={8} ry={8} />
            </g>

            {/* Legs Overlay */}
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

function MetricCard({ title, value, suffix, progress, accent, controls }) {
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

function StreakCard({ completedDates }) {
    const dayLabels = ["S", "M", "T", "W", "T", "F", "S"];
    const today = new Date();
    const activeDays = calculateWeekActivity(today, completedDates);
    const streakCount = calculateWorkoutStreak(completedDates);

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

function AppLoadingScreen() {
    return (
        <main className="app-loading-screen" aria-label="Loading Mission Fit">
            <div className="loading-spinner" aria-hidden="true" />
        </main>
    );
}

function ProfileSetupScreen({ initialProfile, onComplete }) {
    const [profile, setProfile] = useState(initialProfile);
    const [error, setError] = useState("");

    function updateProfile(field, value) {
        setProfile((current) => ({ ...current, [field]: value }));
    }

    function handleSubmit(event) {
        event.preventDefault();
        const age = Number(profile.age);
        const height = Number(profile.heightValue);
        const weight = Number(profile.weightValue);

        if (!profile.name.trim() || age <= 0 || height <= 0 || weight <= 0) {
            setError("Enter your name, age, height, and weight to continue.");
            return;
        }

        onComplete({
            ...profile,
            name: profile.name.trim(),
            age: String(age),
            heightValue: height,
            weightValue: weight
        });
    }

    return (
        <main className="profile-setup">
            <form className="profile-setup-form" onSubmit={handleSubmit}>
                <img src={logo} alt="Mission Fit logo" className="setup-logo" />
                <div>
                    <h1>Set up your profile</h1>
                    <p>Your information personalizes your daily targets.</p>
                </div>

                <label>
                    <span>Name</span>
                    <input
                        value={profile.name}
                        onChange={(event) => updateProfile("name", event.target.value)}
                        autoComplete="name"
                    />
                </label>
                <label>
                    <span>Age</span>
                    <input
                        type="number"
                        min="1"
                        value={profile.age}
                        onChange={(event) => updateProfile("age", event.target.value)}
                    />
                </label>
                <div className="setup-measurement-row">
                    <label>
                        <span>Height</span>
                        <input
                            type="number"
                            min="0.1"
                            step="0.1"
                            value={profile.heightValue}
                            onChange={(event) => updateProfile("heightValue", event.target.value)}
                        />
                    </label>
                    <select
                        aria-label="Height unit"
                        value={profile.heightUnit}
                        onChange={(event) => updateProfile("heightUnit", event.target.value)}>
                        <option value="cm">cm</option>
                        <option value="in">in</option>
                    </select>
                </div>
                <div className="setup-measurement-row">
                    <label>
                        <span>Weight</span>
                        <input
                            type="number"
                            min="0.1"
                            step="0.1"
                            value={profile.weightValue}
                            onChange={(event) => updateProfile("weightValue", event.target.value)}
                        />
                    </label>
                    <select
                        aria-label="Weight unit"
                        value={profile.weightUnit}
                        onChange={(event) => updateProfile("weightUnit", event.target.value)}>
                        <option value="kg">kg</option>
                        <option value="lbs">lbs</option>
                    </select>
                </div>
                <label>
                    <span>Sex</span>
                    <select
                        value={profile.sex}
                        onChange={(event) => updateProfile("sex", event.target.value)}>
                        <option value="Male">Male</option>
                        <option value="Female">Female</option>
                    </select>
                </label>
                <label>
                    <span>Activity level</span>
                    <select
                        value={profile.activityLevel}
                        onChange={(event) => updateProfile("activityLevel", event.target.value)}>
                        <option value="Sedentary">Sedentary</option>
                        <option value="Light">Light</option>
                        <option value="Moderate">Moderate</option>
                        <option value="Active">Active</option>
                        <option value="Extreme">Extreme</option>
                    </select>
                </label>
                {error && (
                    <p className="setup-error" role="alert">
                        {error}
                    </p>
                )}
                <button type="submit" className="primary-button">
                    Done
                </button>
            </form>
        </main>
    );
}

export default function App() {
    const [isLoading, setIsLoading] = useState(true);
    const [hasCompletedOnboarding, setHasCompletedOnboarding] = useState(
        () => window.localStorage.getItem(ONBOARDING_COMPLETE_KEY) === "true"
    );

    // Main App State
    const [profile, setProfile] = useState(defaultProfile);
    const [waterConsumed, setWaterConsumed] = useState(2.0);
    const [goal, setGoal] = useState("Cut");
    const [foodEntries, setFoodEntries] = useState(defaultFoodEntries);
    const [savedMeals, setSavedMeals] = useState(defaultSavedMeals);
    const [plannedWorkouts, setPlannedWorkouts] = useState({});
    const [quickStart, setQuickStart] = useState(defaultQuickStart);
    const [completedWorkoutDates, setCompletedWorkoutDates] = useState([]);
    const [selectedTab, setSelectedTab] = useState("Home");
    const [selectedWorkoutDate, setSelectedWorkoutDate] = useState(dateKey(new Date()));

    // Active Modals / Sheets
    const [activeWorkoutModal, setActiveWorkoutModal] = useState(null); // { name, exercises }
    const [isBuilderModalOpen, setIsBuilderModalOpen] = useState(false);
    const [isQuickStartModalOpen, setIsQuickStartModalOpen] = useState(false);
    const [isFoodSheetOpen, setIsFoodSheetOpen] = useState(false);
    const [foodSheetInitialEntry, setFoodSheetInitialEntry] = useState(null);
    const [isPlannerModalOpen, setIsPlannerModalOpen] = useState(false);
    const [plannerDate, setPlannerDate] = useState(new Date());

    // Daily quote
    const [dailyQuote, setDailyQuote] = useState({
        text: "The impediment to action advances action. What stands in the way becomes the way.",
        author: "Marcus Aurelius"
    });

    // Load initial stored state
    useEffect(() => {
        try {
            const cached = window.localStorage.getItem(STORAGE_KEY);
            if (cached) {
                const parsed = JSON.parse(cached);
                if (parsed.profile) setProfile(parsed.profile);
                if (parsed.waterConsumed !== undefined) setWaterConsumed(parsed.waterConsumed);
                if (parsed.goal) setGoal(parsed.goal);
                if (parsed.foodEntries) setFoodEntries(parsed.foodEntries);
                if (parsed.savedMeals) setSavedMeals(parsed.savedMeals);
                if (parsed.plannedWorkouts) setPlannedWorkouts(parsed.plannedWorkouts);
                if (parsed.quickStart) setQuickStart(parsed.quickStart);
                if (parsed.completedWorkoutDates)
                    setCompletedWorkoutDates(parsed.completedWorkoutDates);
            }
        } catch (_) {}
        const loadingTimer = window.setTimeout(() => setIsLoading(false), 500);
        return () => window.clearTimeout(loadingTimer);
    }, []);

    // Save state on change
    useEffect(() => {
        if (isLoading) return;
        const payload = {
            profile,
            waterConsumed,
            goal,
            foodEntries,
            savedMeals,
            plannedWorkouts,
            quickStart,
            completedWorkoutDates
        };
        window.localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
    }, [
        profile,
        waterConsumed,
        goal,
        foodEntries,
        savedMeals,
        plannedWorkouts,
        quickStart,
        completedWorkoutDates,
        isLoading
    ]);

    // Daily Stoic quote fetch
    useEffect(() => {
        async function fetchQuote() {
            try {
                const response = await fetch("https://stoic.tekloon.net/stoic-quote");
                if (!response.ok) return;
                const payload = await response.json();
                if (payload?.data?.quote && payload?.data?.author) {
                    setDailyQuote({ text: payload.data.quote, author: payload.data.author });
                }
            } catch (_) {}
        }
        fetchQuote();
    }, []);

    // Calculations
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

    const macroProteinTarget = useMemo(() => Math.max(0, (calorieGoal * 0.3) / 4), [calorieGoal]);
    const macroCarbTarget = useMemo(() => Math.max(0, (calorieGoal * 0.45) / 4), [calorieGoal]);
    const macroFatTarget = useMemo(() => Math.max(0, (calorieGoal * 0.25) / 9), [calorieGoal]);

    const bodyMapStatus = useMemo(() => calculateBodyMapStatus(quickStart), [quickStart]);

    // Calendar 14 days
    const calendarDates = useMemo(() => {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const dayOfWeek = today.getDay(); // 0 is Sun
        const diffToMonday = (dayOfWeek + 6) % 7;
        const monday = new Date(today);
        monday.setDate(today.getDate() - diffToMonday);

        return Array.from({ length: 14 }, (_, index) => {
            const next = new Date(monday);
            next.setDate(monday.getDate() + index);
            return next;
        });
    }, []);

    // Today's workout name
    const todayWorkoutName = plannedWorkouts[dateKey(new Date())] ?? "Rest day";

    function handleStartWorkout(workoutName) {
        const name = workoutName || todayWorkoutName;
        if (!name || name === "Rest day") return;
        const exercises = quickStart[name] || defaultQuickStart.Push;
        setActiveWorkoutModal({ name, exercises: JSON.parse(JSON.stringify(exercises)) });
    }

    function handleCompleteWorkout() {
        const today = new Date();
        setCompletedWorkoutDates((current) => {
            const exists = current.some((d) => dateKey(new Date(d)) === dateKey(today));
            return exists ? current : [...current, today];
        });
        setActiveWorkoutModal(null);
    }

    function renderHomeTab() {
        const now = new Date();
        const dateString = `${now.toLocaleDateString("en-US", { weekday: "long" })}, ${now.getDate()} ${monthName(now.getMonth())} ${now.getFullYear()}`;

        return (
            <>
                <div className="date-row">
                    <span>{dateString}</span>
                </div>

                <div>
                    <h1>Welcome{profile.name ? ` ${profile.name}` : ""}!</h1>
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
                        progress={waterProgress}
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

                <StreakCard completedDates={completedWorkoutDates} />

                <div className="card panel quote-card">
                    <h2>Daily perspective</h2>
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
                                        <span>{exercises.map((e) => e.name).join(" / ")}</span>
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

    function renderWorkoutsTab() {
        const now = new Date();
        const weekdayName = now.toLocaleDateString("en-US", { weekday: "long" });
        const dateString = `${weekdayName}, ${now.getDate()} ${monthName(now.getMonth())} ${now.getFullYear()}`;

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

                <StreakCard completedDates={completedWorkoutDates} />

                <div className="card calendar-card">
                    <div className="calendar-header">
                        <h3>
                            {monthName(now.getMonth())} {now.getFullYear()}
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
                            const key = dateKey(day);
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
                                    <MdClose />
                                </button>
                            </div>
                        ))
                    )}

                    <button
                        type="button"
                        className="primary-button"
                        style={{ marginTop: "8px" }}
                        onClick={() => setIsBuilderModalOpen(true)}>
                        <MdAdd /> Create workout
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

    function renderFoodTab() {
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
                            <MdAdd />
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
                                    <MdEditNote />
                                </button>
                                <div className="food-log-item-content">
                                    <div className="food-log-item-info">
                                        <strong>{item.name}</strong>
                                        <span>
                                            {Math.round(item.calories)} kcal · P{" "}
                                            {Math.round(item.protein)}g · C {Math.round(item.carbs)}
                                            g · F {Math.round(item.fat)}g
                                        </span>
                                    </div>
                                    <button
                                        type="button"
                                        className="icon-button"
                                        onClick={() =>
                                            setFoodEntries((prev) =>
                                                prev.filter((_, i) => i !== index)
                                            )
                                        }>
                                        <MdClose />
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

    function renderSettingsTab() {
        return (
            <>
                <div className="card panel settings-group">
                    <h2>Profile</h2>
                    <label>
                        <span>Name</span>
                        <input
                            value={profile.name}
                            onChange={(e) => setProfile((p) => ({ ...p, name: e.target.value }))}
                        />
                    </label>
                    <label>
                        <span>Age</span>
                        <input
                            value={profile.age}
                            onChange={(e) => setProfile((p) => ({ ...p, age: e.target.value }))}
                        />
                    </label>
                    <div className="inline-input-group">
                        <label>
                            <span>Height</span>
                            <input
                                value={profile.heightValue}
                                onChange={(e) =>
                                    setProfile((p) => ({
                                        ...p,
                                        heightValue: parseNumeric(e.target.value)
                                    }))
                                }
                            />
                        </label>
                        <select
                            value={profile.heightUnit}
                            onChange={(e) =>
                                setProfile((p) => ({ ...p, heightUnit: e.target.value }))
                            }>
                            <option value="cm">cm</option>
                            <option value="in">in</option>
                        </select>
                    </div>
                    <div className="inline-input-group">
                        <label>
                            <span>Weight</span>
                            <input
                                value={profile.weightValue}
                                onChange={(e) =>
                                    setProfile((p) => ({
                                        ...p,
                                        weightValue: parseNumeric(e.target.value)
                                    }))
                                }
                            />
                        </label>
                        <select
                            value={profile.weightUnit}
                            onChange={(e) =>
                                setProfile((p) => ({ ...p, weightUnit: e.target.value }))
                            }>
                            <option value="kg">kg</option>
                            <option value="lbs">lbs</option>
                        </select>
                    </div>
                </div>

                <div className="card panel settings-group">
                    <h2>Body Metrics</h2>
                    <label>
                        <span>Sex</span>
                        <select
                            value={profile.sex}
                            onChange={(e) => setProfile((p) => ({ ...p, sex: e.target.value }))}>
                            <option value="Male">Male</option>
                            <option value="Female">Female</option>
                        </select>
                    </label>
                    <label>
                        <span>Activity Level</span>
                        <select
                            value={profile.activityLevel}
                            onChange={(e) =>
                                setProfile((p) => ({ ...p, activityLevel: e.target.value }))
                            }>
                            <option value="Sedentary">Sedentary</option>
                            <option value="Light">Light</option>
                            <option value="Moderate">Moderate</option>
                            <option value="Active">Active</option>
                            <option value="Extreme">Extreme</option>
                        </select>
                    </label>
                </div>

                <button
                    type="button"
                    className="primary-button"
                    onClick={() => alert("Settings saved locally")}>
                    Save Settings
                </button>
            </>
        );
    }

    if (isLoading) return <AppLoadingScreen />;

    if (!hasCompletedOnboarding) {
        return (
            <ProfileSetupScreen
                initialProfile={profile}
                onComplete={(nextProfile) => {
                    setProfile(nextProfile);
                    window.localStorage.setItem(ONBOARDING_COMPLETE_KEY, "true");
                    setHasCompletedOnboarding(true);
                }}
            />
        );
    }

    return (
        <div className="missionfit-app">
            <div className="phone-shell">
                <header className="topbar">
                    <div style={{ width: "38px" }} />
                    <div className="topbar-center">
                        <div className="brand-wrap">
                            <img src={logo} alt="Mission Fit logo" className="brand-logo" />
                        </div>
                    </div>
                    <button type="button" className="icon-button" aria-label="Sync">
                        <MdSync />
                    </button>
                </header>

                <main className="content">
                    {selectedTab === "Home" && renderHomeTab()}
                    {selectedTab === "Workouts" && renderWorkoutsTab()}
                    {selectedTab === "Food" && renderFoodTab()}
                    {selectedTab === "Settings" && renderSettingsTab()}
                </main>

                <nav className="bottom-nav">
                    {navItems.map((item, index) => {
                        const Icon = navIcons[index];
                        const isActive = selectedTab === item;
                        return (
                            <button
                                key={item}
                                type="button"
                                className={`nav-item ${isActive ? "active" : ""}`}
                                onClick={() => setSelectedTab(item)}>
                                <div className="nav-indicator">
                                    <Icon />
                                </div>
                                <span>{item}</span>
                            </button>
                        );
                    })}
                </nav>
            </div>

            {/* Active Workout Detail Modal */}
            {activeWorkoutModal && (
                <WorkoutDetailModal
                    workout={activeWorkoutModal}
                    onClose={() => setActiveWorkoutModal(null)}
                    onComplete={handleCompleteWorkout}
                />
            )}

            {/* Workout Builder Modal */}
            {isBuilderModalOpen && (
                <WorkoutBuilderModal
                    onClose={() => setIsBuilderModalOpen(false)}
                    onSave={(name, exercises) => {
                        setQuickStart((prev) => ({ ...prev, [name]: exercises }));
                        setIsBuilderModalOpen(false);
                    }}
                />
            )}

            {/* Quick Start Editor Modal */}
            {isQuickStartModalOpen && (
                <QuickStartEditorModal
                    quickStart={quickStart}
                    onClose={() => setIsQuickStartModalOpen(false)}
                    onSave={(updatedQuickStart) => {
                        setQuickStart(updatedQuickStart);
                        setIsQuickStartModalOpen(false);
                    }}
                />
            )}

            {/* Calendar Day Workout Planner Modal */}
            {isPlannerModalOpen && (
                <WorkoutPlannerModal
                    date={plannerDate}
                    quickStartNames={Object.keys(quickStart)}
                    currentPlan={plannedWorkouts[dateKey(plannerDate)]}
                    onClose={() => setIsPlannerModalOpen(false)}
                    onSave={(workoutName) => {
                        const key = dateKey(plannerDate);
                        setPlannedWorkouts((prev) => {
                            const updated = { ...prev };
                            if (workoutName) updated[key] = workoutName;
                            else delete updated[key];
                            return updated;
                        });
                        setIsPlannerModalOpen(false);
                    }}
                />
            )}

            {/* Food Entry Sheet Modal */}
            {isFoodSheetOpen && (
                <FoodEntrySheetModal
                    initialEntry={foodSheetInitialEntry}
                    savedMeals={savedMeals}
                    onClose={() => setIsFoodSheetOpen(false)}
                    onSaveEntry={(entry, editIndex) => {
                        setFoodEntries((prev) => {
                            if (editIndex !== undefined && editIndex !== null) {
                                const updated = [...prev];
                                updated[editIndex] = entry;
                                return updated;
                            }
                            return [entry, ...prev];
                        });
                        setIsFoodSheetOpen(false);
                    }}
                    onAddMeal={(meal) => {
                        setFoodEntries((prev) => [
                            ...meal.items.map((it) => ({ ...it, id: Date.now() + Math.random() })),
                            ...prev
                        ]);
                        setIsFoodSheetOpen(false);
                    }}
                />
            )}
        </div>
    );
}

// Modal Components

function WorkoutDetailModal({ workout, onClose, onComplete }) {
    const [exercises, setExercises] = useState(() =>
        JSON.parse(JSON.stringify(workout.exercises || []))
    );
    const [timerRunning, setTimerRunning] = useState(false);
    const [timerSeconds, setTimerSeconds] = useState(0);

    const isRun =
        (workout.name || "").toLowerCase() === "run" ||
        (workout.name || "").toLowerCase() === "treadmill";

    useEffect(() => {
        let interval;
        if (timerRunning) {
            interval = setInterval(() => setTimerSeconds((s) => s + 1), 1000);
        }
        return () => clearInterval(interval);
    }, [timerRunning]);

    const formatTimer = (totalSec) => {
        const h = String(Math.floor(totalSec / 3600)).padStart(2, "0");
        const m = String(Math.floor((totalSec % 3600) / 60)).padStart(2, "0");
        const s = String(totalSec % 60).padStart(2, "0");
        return `${h}:${m}:${s}`;
    };

    const toggleSetComplete = (exIdx, setIdx) => {
        setExercises((prev) => {
            const updated = [...prev];
            const sets = [...updated[exIdx].setEntries];
            sets[setIdx] = { ...sets[setIdx], isComplete: !sets[setIdx].isComplete };
            updated[exIdx].setEntries = sets;
            return updated;
        });
    };

    const toggleSetWon = (exIdx, setIdx) => {
        setExercises((prev) => {
            const updated = [...prev];
            const sets = [...updated[exIdx].setEntries];
            sets[setIdx] = { ...sets[setIdx], isWon: !sets[setIdx].isWon };
            updated[exIdx].setEntries = sets;
            return updated;
        });
    };

    const toggleExerciseDone = (exIdx) => {
        setExercises((prev) => {
            const updated = [...prev];
            const ex = updated[exIdx];
            const allComplete = ex.setEntries.every((s) => s.isComplete);
            ex.setEntries = ex.setEntries.map((s) => ({ ...s, isComplete: !allComplete }));
            return updated;
        });
    };

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="sheet-content" onClick={(e) => e.stopPropagation()}>
                <div
                    style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center"
                    }}>
                    <h2>{workout.name}</h2>
                    <button type="button" className="icon-button" onClick={onClose}>
                        <MdClose />
                    </button>
                </div>

                {isRun && (
                    <div className="run-timer-box">
                        <span
                            style={{
                                fontSize: "0.9rem",
                                color: "var(--color-muted)",
                                fontWeight: "700"
                            }}>
                            Run timer
                        </span>
                        <div className="run-timer-digits">{formatTimer(timerSeconds)}</div>
                        <div style={{ display: "flex", gap: "10px" }}>
                            <button
                                type="button"
                                className="primary-button small"
                                onClick={() => setTimerRunning((r) => !r)}>
                                {timerRunning ? <MdPause /> : <MdPlayArrow />}{" "}
                                {timerRunning ? "Pause" : "Start"}
                            </button>
                            <button
                                type="button"
                                className="outlined-button"
                                style={{ padding: "8px 12px" }}
                                onClick={() => {
                                    setTimerRunning(false);
                                    setTimerSeconds(0);
                                }}>
                                <MdRestartAlt /> Reset
                            </button>
                        </div>
                    </div>
                )}

                <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                    {exercises.map((ex, exIdx) => {
                        const isComplete =
                            ex.setEntries.length > 0 && ex.setEntries.every((s) => s.isComplete);
                        return (
                            <div
                                key={`${ex.name}-${exIdx}`}
                                className={`exercise-card ${isComplete ? "completed" : ""}`}>
                                <div className="exercise-card-header">
                                    <h4>{ex.name}</h4>
                                    <button
                                        type="button"
                                        className="primary-button small"
                                        style={
                                            isComplete
                                                ? {
                                                      background: "var(--color-surface)",
                                                      color: "white"
                                                  }
                                                : {}
                                        }
                                        onClick={() => toggleExerciseDone(exIdx)}>
                                        Done
                                    </button>
                                </div>

                                <div
                                    style={{
                                        display: "flex",
                                        flexDirection: "column",
                                        gap: "8px"
                                    }}>
                                    {ex.setEntries.map((set, setIdx) => (
                                        <div key={setIdx} className="set-row">
                                            <button
                                                type="button"
                                                className={`win-btn ${set.isWon ? "won" : ""}`}
                                                onClick={() => toggleSetWon(exIdx, setIdx)}>
                                                W
                                            </button>
                                            <input
                                                type="text"
                                                value={(set.weight ?? ex.weight) || "0"}
                                                onChange={(e) => {
                                                    const val = e.target.value;
                                                    setExercises((prev) => {
                                                        const updated = [...prev];
                                                        updated[exIdx].setEntries[setIdx].weight =
                                                            val;
                                                        return updated;
                                                    });
                                                }}
                                                style={{ width: "80px" }}
                                                placeholder="Weight"
                                            />
                                            <input
                                                type="text"
                                                value={set.reps || "8"}
                                                onChange={(e) => {
                                                    const val = e.target.value;
                                                    setExercises((prev) => {
                                                        const updated = [...prev];
                                                        updated[exIdx].setEntries[setIdx].reps =
                                                            val;
                                                        return updated;
                                                    });
                                                }}
                                                style={{ width: "70px" }}
                                                placeholder="Reps"
                                            />
                                            <button
                                                type="button"
                                                className="icon-button"
                                                onClick={() => toggleSetComplete(exIdx, setIdx)}>
                                                {set.isComplete ? (
                                                    <MdCheckCircle />
                                                ) : (
                                                    <MdRadioButtonUnchecked />
                                                )}
                                            </button>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        );
                    })}
                </div>

                <button
                    type="button"
                    className="primary-button"
                    style={{ marginTop: "12px" }}
                    onClick={onComplete}>
                    Complete Workout
                </button>
            </div>
        </div>
    );
}

function WorkoutBuilderModal({ onClose, onSave }) {
    const [name, setName] = useState("Push Day");
    const [exercises, setExercises] = useState([
        {
            name: "Bench Press",
            weight: "80",
            setEntries: [{ reps: "8", isWon: false, isComplete: false }]
        }
    ]);

    const addExercise = () => {
        setExercises((prev) => [
            ...prev,
            {
                name: "New Exercise",
                weight: "50",
                setEntries: [{ reps: "8", isWon: false, isComplete: false }]
            }
        ]);
    };

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="dialog-content" onClick={(e) => e.stopPropagation()}>
                <div
                    style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center"
                    }}>
                    <h2>Create Workout</h2>
                    <button type="button" className="icon-button" onClick={onClose}>
                        <MdClose />
                    </button>
                </div>

                <label>
                    <span>Workout Name</span>
                    <input value={name} onChange={(e) => setName(e.target.value)} />
                </label>

                <div
                    style={{
                        display: "flex",
                        flexDirection: "column",
                        gap: "10px",
                        maxHeight: "300px",
                        overflowY: "auto"
                    }}>
                    {exercises.map((ex, index) => (
                        <div
                            key={index}
                            style={{
                                padding: "10px",
                                background: "var(--color-surface-soft)",
                                borderRadius: "12px"
                            }}>
                            <div style={{ display: "flex", gap: "8px", marginBottom: "8px" }}>
                                <input
                                    style={{ flex: 1 }}
                                    value={ex.name}
                                    placeholder="Exercise name"
                                    onChange={(e) => {
                                        const val = e.target.value;
                                        setExercises((prev) => {
                                            const updated = [...prev];
                                            updated[index].name = val;
                                            return updated;
                                        });
                                    }}
                                />
                                <button
                                    type="button"
                                    className="icon-button"
                                    onClick={() =>
                                        setExercises((prev) => prev.filter((_, i) => i !== index))
                                    }>
                                    <MdClose />
                                </button>
                            </div>
                        </div>
                    ))}
                </div>

                <button type="button" className="outlined-button" onClick={addExercise}>
                    + Add Exercise
                </button>
                <button
                    type="button"
                    className="primary-button"
                    onClick={() => onSave(name || "Custom", exercises)}>
                    Save Workout
                </button>
            </div>
        </div>
    );
}

function QuickStartEditorModal({ quickStart, onClose, onSave }) {
    const [data, setData] = useState(() => JSON.parse(JSON.stringify(quickStart || {})));
    const [selectedName, setSelectedName] = useState(() => Object.keys(quickStart || {})[0] || "");
    const [newWorkoutName, setNewWorkoutName] = useState("");

    const handleCreateWorkout = () => {
        const name = newWorkoutName.trim();
        if (!name) return;
        setData((prev) => ({
            ...prev,
            [name]: prev[name] || [
                { name: "New Exercise", weight: "50", setEntries: [{ reps: "8" }] }
            ]
        }));
        setSelectedName(name);
        setNewWorkoutName("");
    };

    const exercises = data[selectedName] || [];

    const updateExercise = (idx, field, val) => {
        setData((prev) => {
            const updated = { ...prev };
            const exList = [...(updated[selectedName] || [])];
            exList[idx] = { ...exList[idx], [field]: val };
            updated[selectedName] = exList;
            return updated;
        });
    };

    const addExercise = () => {
        if (!selectedName) return;
        setData((prev) => {
            const updated = { ...prev };
            const exList = [...(updated[selectedName] || [])];
            exList.push({ name: "New Exercise", weight: "50", setEntries: [{ reps: "8" }] });
            updated[selectedName] = exList;
            return updated;
        });
    };

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="dialog-content" onClick={(e) => e.stopPropagation()}>
                <div
                    style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center"
                    }}>
                    <h2>Edit Quick Start</h2>
                    <button type="button" className="icon-button" onClick={onClose}>
                        <MdClose />
                    </button>
                </div>

                <div style={{ display: "flex", gap: "8px" }}>
                    <input
                        style={{ flex: 1 }}
                        value={newWorkoutName}
                        placeholder="Add workout name"
                        onChange={(e) => setNewWorkoutName(e.target.value)}
                    />
                    <button
                        type="button"
                        className="primary-button small"
                        onClick={handleCreateWorkout}>
                        + Add
                    </button>
                </div>

                {Object.keys(data).length > 0 && (
                    <label>
                        <span>Selected Workout</span>
                        <select
                            value={selectedName}
                            onChange={(e) => setSelectedName(e.target.value)}>
                            {Object.keys(data).map((n) => (
                                <option key={n} value={n}>
                                    {n}
                                </option>
                            ))}
                        </select>
                    </label>
                )}

                <div
                    style={{
                        display: "flex",
                        flexDirection: "column",
                        gap: "10px",
                        maxHeight: "300px",
                        overflowY: "auto"
                    }}>
                    {exercises.map((ex, idx) => (
                        <div
                            key={idx}
                            style={{
                                padding: "10px",
                                background: "var(--color-surface-soft)",
                                borderRadius: "12px",
                                display: "flex",
                                flexDirection: "column",
                                gap: "6px"
                            }}>
                            <div style={{ display: "flex", gap: "8px" }}>
                                <input
                                    style={{ flex: 1 }}
                                    value={ex.name}
                                    placeholder="Exercise name"
                                    onChange={(e) => updateExercise(idx, "name", e.target.value)}
                                />
                                <button
                                    type="button"
                                    className="icon-button"
                                    onClick={() => {
                                        setData((prev) => {
                                            const updated = { ...prev };
                                            updated[selectedName] = updated[selectedName].filter(
                                                (_, i) => i !== idx
                                            );
                                            return updated;
                                        });
                                    }}>
                                    <MdClose />
                                </button>
                            </div>
                            <div style={{ display: "flex", gap: "8px" }}>
                                <input
                                    style={{ flex: 1 }}
                                    value={ex.weight}
                                    placeholder="Weight"
                                    onChange={(e) => updateExercise(idx, "weight", e.target.value)}
                                />
                            </div>
                        </div>
                    ))}
                </div>

                <button type="button" className="outlined-button" onClick={addExercise}>
                    + Add Exercise
                </button>
                <button type="button" className="primary-button" onClick={() => onSave(data)}>
                    Done
                </button>
            </div>
        </div>
    );
}

function WorkoutPlannerModal({ date, quickStartNames, currentPlan, onClose, onSave }) {
    const [selected, setSelected] = useState(currentPlan || "");

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="dialog-content" onClick={(e) => e.stopPropagation()}>
                <div
                    style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center"
                    }}>
                    <h2>
                        Plan {monthName(date.getMonth())} {date.getDate()}
                    </h2>
                    <button type="button" className="icon-button" onClick={onClose}>
                        <MdClose />
                    </button>
                </div>

                <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
                    <label
                        style={{
                            flexDirection: "row",
                            alignItems: "center",
                            gap: "10px",
                            cursor: "pointer"
                        }}>
                        <input
                            type="radio"
                            name="workoutPlan"
                            checked={!selected}
                            onChange={() => setSelected("")}
                        />
                        <span>Rest day</span>
                    </label>
                    {quickStartNames.map((name) => (
                        <label
                            key={name}
                            style={{
                                flexDirection: "row",
                                alignItems: "center",
                                gap: "10px",
                                cursor: "pointer"
                            }}>
                            <input
                                type="radio"
                                name="workoutPlan"
                                checked={selected === name}
                                onChange={() => setSelected(name)}
                            />
                            <span>{name}</span>
                        </label>
                    ))}
                </div>

                <button type="button" className="primary-button" onClick={() => onSave(selected)}>
                    Done
                </button>
            </div>
        </div>
    );
}

function FoodEntrySheetModal({ initialEntry, savedMeals, onClose, onSaveEntry, onAddMeal }) {
    const [tab, setTab] = useState("manual"); // barcode, search, manual, meals
    const [name, setName] = useState(initialEntry?.name || "");
    const [calories, setCalories] = useState(initialEntry ? String(initialEntry.calories) : "");
    const [protein, setProtein] = useState(initialEntry ? String(initialEntry.protein) : "");
    const [carbs, setCarbs] = useState(initialEntry ? String(initialEntry.carbs) : "");
    const [fat, setFat] = useState(initialEntry ? String(initialEntry.fat) : "");

    const [barcode, setBarcode] = useState("");
    const [barcodeMsg, setBarcodeMsg] = useState("");
    const [isLookingUp, setIsLookingUp] = useState(false);
    const [isScanningCamera, setIsScanningCamera] = useState(false);

    const [searchQuery, setSearchQuery] = useState("");
    const [searchResults, setSearchResults] = useState([]);
    const [isSearching, setIsSearching] = useState(false);
    const [searchMsg, setSearchMsg] = useState("");

    const fetchBarcodeProduct = async (codeToFetch) => {
        const cleanCode = codeToFetch.replace(/[^0-9]/g, "");
        if (!cleanCode) return;
        setIsLookingUp(true);
        setBarcodeMsg("Looking up product...");
        try {
            const res = await fetch(
                `https://world.openfoodfacts.org/api/v0/product/${cleanCode}.json`
            );
            if (!res.ok) throw new Error();
            const data = await res.json();
            if (data.status === 1 && data.product) {
                const p = data.product;
                const nuts = p.nutriments || {};
                setName(p.product_name || "Food item");
                setCalories(String(nuts["energy-kcal_100g"] || nuts["energy-kcal"] || 0));
                setProtein(String(nuts.proteins_100g || nuts.proteins || 0));
                setCarbs(String(nuts.carbohydrates_100g || nuts.carbohydrates || 0));
                setFat(String(nuts.fat_100g || nuts.fat || 0));
                setTab("manual");
                setBarcodeMsg("Loaded product details!");
            } else {
                setBarcodeMsg("Product not found");
            }
        } catch (_) {
            setBarcodeMsg("Unable to look up barcode");
        } finally {
            setIsLookingUp(false);
        }
    };

    const handleLookupBarcode = async () => {
        if (!barcode.trim()) return;
        await fetchBarcodeProduct(barcode);
    };

    useEffect(() => {
        if (!isScanningCamera || tab !== "barcode") return;
        const scannerId = "html5qr-code-full-region";
        const html5QrCode = new Html5Qrcode(scannerId);
        let stopped = false;

        html5QrCode
            .start(
                { facingMode: "environment" },
                { fps: 10, qrbox: { width: 250, height: 150 } },
                (decodedText) => {
                    if (stopped) return;
                    stopped = true;
                    setBarcode(decodedText);
                    setIsScanningCamera(false);
                    html5QrCode
                        .stop()
                        .then(() => fetchBarcodeProduct(decodedText))
                        .catch(() => fetchBarcodeProduct(decodedText));
                },
                () => {}
            )
            .catch(() => {
                setBarcodeMsg("Camera access failed or permission denied.");
                setIsScanningCamera(false);
            });

        return () => {
            if (html5QrCode && html5QrCode.isScanning) {
                html5QrCode.stop().catch(() => {});
            }
        };
    }, [isScanningCamera, tab]);

    const handleSearchFood = async () => {
        if (!searchQuery.trim()) return;
        setIsSearching(true);
        setSearchMsg("Searching...");
        try {
            const uri = `https://world.openfoodfacts.org/cgi/search.pl?search_terms=${encodeURIComponent(searchQuery)}&json=true&page_size=8&fields=product_name,nutriments`;
            const res = await fetch(uri);
            if (!res.ok) throw new Error();
            const data = await res.json();
            const products = data.products || [];
            const results = products.map((p) => {
                const nuts = p.nutriments || {};
                return {
                    name: p.product_name || "Food item",
                    calories: Number(nuts["energy-kcal_100g"] || 0),
                    protein: Number(nuts.proteins_100g || 0),
                    carbs: Number(nuts.carbohydrates_100g || 0),
                    fat: Number(nuts.fat_100g || 0)
                };
            });
            setSearchResults(results);
            setSearchMsg(results.length === 0 ? "No products found" : "");
        } catch (_) {
            setSearchMsg("Failed to search foods");
        } finally {
            setIsSearching(false);
        }
    };

    const handleSaveManual = (e) => {
        e.preventDefault();
        if (!name.trim()) return;
        onSaveEntry(
            {
                id: initialEntry?.id || Date.now(),
                name: name.trim(),
                calories: parseNumeric(calories),
                protein: parseNumeric(protein),
                carbs: parseNumeric(carbs),
                fat: parseNumeric(fat)
            },
            initialEntry?.index
        );
    };

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="sheet-content" onClick={(e) => e.stopPropagation()}>
                <div
                    style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center"
                    }}>
                    <h2>Log Food</h2>
                    <button type="button" className="icon-button" onClick={onClose}>
                        <MdClose />
                    </button>
                </div>

                <div className="sheet-tabs">
                    <button
                        type="button"
                        className={`sheet-tab-btn ${tab === "barcode" ? "active" : ""}`}
                        onClick={() => setTab("barcode")}>
                        Barcode
                    </button>
                    <button
                        type="button"
                        className={`sheet-tab-btn ${tab === "search" ? "active" : ""}`}
                        onClick={() => setTab("search")}>
                        Search
                    </button>
                    <button
                        type="button"
                        className={`sheet-tab-btn ${tab === "manual" ? "active" : ""}`}
                        onClick={() => setTab("manual")}>
                        Manual
                    </button>
                    <button
                        type="button"
                        className={`sheet-tab-btn ${tab === "meals" ? "active" : ""}`}
                        onClick={() => setTab("meals")}>
                        Saved Meals
                    </button>
                </div>

                {tab === "barcode" && (
                    <div style={{ display: "flex", flexDirection: "column", gap: "14px" }}>
                        <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
                            {!isScanningCamera ? (
                                <button
                                    type="button"
                                    className="primary-button"
                                    onClick={() => {
                                        setBarcodeMsg("");
                                        setIsScanningCamera(true);
                                    }}>
                                    <MdQrCodeScanner fontSize="1.25rem" /> Scan Barcode with Camera
                                </button>
                            ) : (
                                <button
                                    type="button"
                                    className="outlined-button"
                                    onClick={() => setIsScanningCamera(false)}>
                                    Stop Camera Scanner
                                </button>
                            )}

                            {isScanningCamera && (
                                <div
                                    id="html5qr-code-full-region"
                                    style={{
                                        width: "100%",
                                        minHeight: "220px",
                                        borderRadius: "14px",
                                        overflow: "hidden",
                                        background: "#000",
                                        marginTop: "8px"
                                    }}
                                />
                            )}
                        </div>

                        <div
                            style={{
                                display: "flex",
                                alignItems: "center",
                                gap: "10px",
                                margin: "4px 0"
                            }}>
                            <hr style={{ flex: 1, borderColor: "var(--color-border)" }} />
                            <span
                                style={{
                                    fontSize: "0.75rem",
                                    color: "var(--color-muted)",
                                    fontWeight: "700"
                                }}>
                                OR
                            </span>
                            <hr style={{ flex: 1, borderColor: "var(--color-border)" }} />
                        </div>

                        <label>
                            <span>Barcode Number</span>
                            <div style={{ display: "flex", gap: "8px" }}>
                                <input
                                    style={{ flex: 1 }}
                                    value={barcode}
                                    placeholder="e.g. 737628064502"
                                    onChange={(e) => setBarcode(e.target.value)}
                                />
                                <button
                                    type="button"
                                    className="primary-button small"
                                    onClick={handleLookupBarcode}
                                    disabled={isLookingUp}>
                                    Lookup
                                </button>
                            </div>
                        </label>
                        {barcodeMsg && (
                            <p style={{ color: "var(--color-accent)", fontSize: "0.85rem" }}>
                                {barcodeMsg}
                            </p>
                        )}
                    </div>
                )}

                {tab === "search" && (
                    <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                        <div style={{ display: "flex", gap: "8px" }}>
                            <input
                                style={{ flex: 1 }}
                                value={searchQuery}
                                placeholder="Search food name"
                                onChange={(e) => setSearchQuery(e.target.value)}
                            />
                            <button
                                type="button"
                                className="primary-button small"
                                onClick={handleSearchFood}
                                disabled={isSearching}>
                                <MdSearch />
                            </button>
                        </div>
                        {searchMsg && (
                            <p style={{ color: "var(--color-muted)", fontSize: "0.85rem" }}>
                                {searchMsg}
                            </p>
                        )}
                        <div
                            style={{
                                display: "flex",
                                flexDirection: "column",
                                gap: "8px",
                                maxHeight: "250px",
                                overflowY: "auto"
                            }}>
                            {searchResults.map((item, i) => (
                                <div
                                    key={i}
                                    style={{
                                        padding: "10px",
                                        background: "var(--color-surface-soft)",
                                        borderRadius: "10px",
                                        cursor: "pointer"
                                    }}
                                    onClick={() => {
                                        setName(item.name);
                                        setCalories(String(item.calories));
                                        setProtein(String(item.protein));
                                        setCarbs(String(item.carbs));
                                        setFat(String(item.fat));
                                        setTab("manual");
                                    }}>
                                    <strong>{item.name}</strong>
                                    <div
                                        style={{
                                            fontSize: "0.75rem",
                                            color: "var(--color-muted)"
                                        }}>
                                        {item.calories} kcal · P {item.protein}g · C {item.carbs}g ·
                                        F {item.fat}g
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}

                {tab === "manual" && (
                    <form
                        onSubmit={handleSaveManual}
                        style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                        <label>
                            <span>Food Name</span>
                            <input
                                value={name}
                                onChange={(e) => setName(e.target.value)}
                                placeholder="e.g. Chicken breast"
                            />
                        </label>
                        <div
                            style={{
                                display: "grid",
                                gridTemplateColumns: "1fr 1fr",
                                gap: "10px"
                            }}>
                            <label>
                                <span>Calories (kcal)</span>
                                <input
                                    value={calories}
                                    onChange={(e) => setCalories(e.target.value)}
                                    placeholder="320"
                                />
                            </label>
                            <label>
                                <span>Protein (g)</span>
                                <input
                                    value={protein}
                                    onChange={(e) => setProtein(e.target.value)}
                                    placeholder="24"
                                />
                            </label>
                        </div>
                        <div
                            style={{
                                display: "grid",
                                gridTemplateColumns: "1fr 1fr",
                                gap: "10px"
                            }}>
                            <label>
                                <span>Carbs (g)</span>
                                <input
                                    value={carbs}
                                    onChange={(e) => setCarbs(e.target.value)}
                                    placeholder="28"
                                />
                            </label>
                            <label>
                                <span>Fat (g)</span>
                                <input
                                    value={fat}
                                    onChange={(e) => setFat(e.target.value)}
                                    placeholder="8"
                                />
                            </label>
                        </div>
                        <button type="submit" className="primary-button">
                            Save Food Entry
                        </button>
                    </form>
                )}

                {tab === "meals" && (
                    <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
                        {savedMeals.length === 0 ? (
                            <p
                                style={{
                                    color: "var(--color-muted)",
                                    fontSize: "0.85rem",
                                    textAlign: "center"
                                }}>
                                No saved meals yet.
                            </p>
                        ) : (
                            savedMeals.map((meal) => (
                                <div
                                    key={meal.id}
                                    style={{
                                        padding: "12px",
                                        background: "var(--color-surface-soft)",
                                        borderRadius: "12px",
                                        display: "flex",
                                        justifyContent: "space-between",
                                        alignItems: "center"
                                    }}>
                                    <div>
                                        <strong>{meal.name}</strong>
                                        <div
                                            style={{
                                                fontSize: "0.8rem",
                                                color: "var(--color-muted)"
                                            }}>
                                            {meal.items.map((it) => it.name).join(", ")}
                                        </div>
                                    </div>
                                    <button
                                        type="button"
                                        className="primary-button small"
                                        onClick={() => onAddMeal(meal)}>
                                        Add Meal
                                    </button>
                                </div>
                            ))
                        )}
                    </div>
                )}
            </div>
        </div>
    );
}
