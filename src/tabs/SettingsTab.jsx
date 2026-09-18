import React from "react";

export default function SettingsTab({ profile, setProfile }) {
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
                                    heightValue: Number(e.target.value) || 0
                                }))
                            }
                        />
                    </label>
                    <select
                        value={profile.heightUnit}
                        onChange={(e) => setProfile((p) => ({ ...p, heightUnit: e.target.value }))}>
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
                                    weightValue: Number(e.target.value) || 0
                                }))
                            }
                        />
                    </label>
                    <select
                        value={profile.weightUnit}
                        onChange={(e) => setProfile((p) => ({ ...p, weightUnit: e.target.value }))}>
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
