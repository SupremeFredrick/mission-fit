import React from "react";

const stats = [
    { label: "Daily goals", value: "92%" },
    { label: "Workouts", value: "4x" },
    { label: "Calories", value: "2,140" }
];

const features = ["Meal logging", "Workout tracking", "Goal coaching"];

export default function App() {
    return (
        <div className="App preview-shell">
            <header className="App-header">
                <div className="badge">Preview</div>
                <h1>Mission Fit</h1>
                <p>Preview surface for the mobile fitness dashboard and nutrition planner.</p>
                <div className="cta-row">
                    <a href="#tracker" className="cta-button primary">
                        Open dashboard
                    </a>
                    <button type="button" className="cta-button secondary">
                        View plan
                    </button>
                </div>
            </header>

            <main className="main-shell">
                <section className="tracker card" id="tracker">
                    <div className="section-heading">
                        <span className="eyebrow">Overview</span>
                        <h2>Track Meals & Workouts</h2>
                    </div>

                    <div className="stat-grid">
                        {stats.map((stat) => (
                            <div className="stat-card glass-card" key={stat.label}>
                                <span>{stat.label}</span>
                                <strong>{stat.value}</strong>
                            </div>
                        ))}
                    </div>

                    <div className="feature-list">
                        {features.map((feature) => (
                            <div className="feature-item" key={feature}>
                                <span className="feature-dot" aria-hidden="true" />
                                <span>{feature}</span>
                            </div>
                        ))}
                    </div>
                </section>

                <aside className="light-section glow-panel">
                    <h2>Smart recommendations</h2>
                    <p>
                        Keep your nutrition and training in balance with personalized daily feedback
                        tailored to your goals.
                    </p>
                </aside>
            </main>
        </div>
    );
}
