import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'tabs/home_tab_logic.dart';
part 'tabs/home_tab_render.dart';
part 'tabs/workouts_tab_logic.dart';
part 'tabs/workouts_tab_render.dart';
part 'tabs/food_tab_logic.dart';
part 'tabs/food_tab_render.dart';
part 'tabs/settings_tab_logic.dart';
part 'tabs/settings_tab_render.dart';

const Color kMissionFitDominant = Color(0xFF000000);
const Color kMissionFitSecondary = Color(0xFFBC96E6);
const Color kMissionFitAccent = Color(0xFFFFD166);
const Color kMissionFitLight = Color(0xFFD8B9F2);
const Color kMissionFitSurface = Color(0xFF2B1238);
const Color kMissionFitSurfaceStrong = Color(0xFF3A1E4B);
const Color kMissionFitSurfaceSoft = Color(0xFF4B2A5C);
const Color kMissionFitMuted = Color(0xFFD8CBE3);
const Color kMissionFitBorder = Color(0x2EBC96E6);

double convertToMetricValue(double value, String unit) {
  switch (unit.toLowerCase()) {
    case 'in':
      return value * 2.54;
    case 'lbs':
      return value * 0.45359237;
    case 'cm':
    case 'kg':
    default:
      return value;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MissionFitApp());
}

class MissionFitApp extends StatelessWidget {
  const MissionFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mission Fit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kMissionFitSecondary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: kMissionFitDominant,
        cardColor: kMissionFitSurface,
        dividerColor: kMissionFitBorder,
        fontFamily: 'Roboto',
        iconTheme: const IconThemeData(color: Colors.white),
        useMaterial3: true,
        navigationBarTheme: NavigationBarThemeData(
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? kMissionFitDominant
                  : Colors.white,
            ),
          ),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(color: Colors.white),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          isDense: true,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
      home: const MissionFitHome(),
    );
  }
}

class MissionFitHome extends StatefulWidget {
  const MissionFitHome({super.key});

  @override
  State<MissionFitHome> createState() => MissionFitHomeState();
}

class MissionFitHomeState extends State<MissionFitHome> {
  int _selectedIndex = 0;
  late final SharedPreferences _prefs;

  final List<String> _tabLabels = ['Home', 'Workouts', 'Food', 'Settings'];
  static const List<IconData> _tabIcons = [
    Icons.home_rounded,
    Icons.fitness_center_rounded,
    Icons.restaurant_rounded,
    Icons.settings_rounded,
  ];

  String _name = 'Alex';
  String _age = '27';
  double _heightValue = 180;
  String _heightUnit = 'cm';
  double _weightValue = 74;
  String _weightUnit = 'kg';
  String _sex = 'Male';
  String _activityLevel = 'Moderate';
  String _instagram = '@missionfit';
  String _x = '@missionfit';
  String _strava = 'missionfit';
  String _workoutName = 'Push Day';
  List<String> _quickStart = ['Push', 'Pull', 'Legs', 'Run'];
  String _selectedQuickStartWorkout = 'Push';
  final Map<String, List<WorkoutExercise>> _quickStartWorkouts = {
    'Push': [
      const WorkoutExercise(
        name: 'Bench Press',
        weight: '80',
        setEntries: [
          WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
          WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
          WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
          WorkoutSetEntry(reps: '6', isWon: false, isComplete: false),
        ],
      ),
      const WorkoutExercise(
        name: 'Incline Press',
        weight: '65',
        setEntries: [
          WorkoutSetEntry(reps: '10', isWon: false, isComplete: false),
          WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
          WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
        ],
      ),
    ],
    'Pull': [
      const WorkoutExercise(
        name: 'Rows',
        weight: '60',
        setEntries: [
          WorkoutSetEntry(reps: '10', isWon: false, isComplete: false),
          WorkoutSetEntry(reps: '10', isWon: false, isComplete: false),
          WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
        ],
      ),
    ],
    'Legs': [
      const WorkoutExercise(
        name: 'Squat',
        weight: '100',
        setEntries: [
          WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
          WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
          WorkoutSetEntry(reps: '6', isWon: false, isComplete: false),
        ],
      ),
    ],
    'Run': [
      const WorkoutExercise(
        name: 'Treadmill',
        weight: '0',
        setEntries: [
          WorkoutSetEntry(reps: '15', isWon: false, isComplete: false),
        ],
      ),
    ],
  };
  List<FoodEntry> _foodEntries = [
    const FoodEntry(
      name: 'Greek yogurt, berries, oats',
      calories: 320,
      protein: 24,
      carbs: 28,
      fat: 8,
    ),
    const FoodEntry(
      name: 'Chicken rice bowl',
      calories: 540,
      protein: 42,
      carbs: 55,
      fat: 16,
    ),
    const FoodEntry(
      name: 'Protein shake',
      calories: 240,
      protein: 28,
      carbs: 12,
      fat: 4,
    ),
  ];
  List<MealPreset> _savedMeals = [
    const MealPreset(
      name: 'Post-Workout',
      items: [
        FoodEntry(
          name: 'Protein shake',
          calories: 240,
          protein: 28,
          carbs: 12,
          fat: 4,
        ),
        FoodEntry(name: 'Banana', calories: 105, protein: 1, carbs: 27, fat: 0),
      ],
      isSelected: false,
    ),
  ];
  List<WorkoutExercise> _exercises = [
    WorkoutExercise(
      name: 'Bench Press',
      weight: '80',
      setEntries: [
        const WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
        const WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
        const WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
        const WorkoutSetEntry(reps: '6', isWon: false, isComplete: false),
      ],
    ),
    WorkoutExercise(
      name: 'Incline Press',
      weight: '65',
      setEntries: [
        const WorkoutSetEntry(reps: '10', isWon: false, isComplete: false),
        const WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
        const WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
      ],
    ),
    WorkoutExercise(
      name: 'Cable Fly',
      weight: '35',
      setEntries: [
        const WorkoutSetEntry(reps: '12', isWon: false, isComplete: false),
        const WorkoutSetEntry(reps: '12', isWon: false, isComplete: false),
      ],
    ),
  ];
  String _goal = 'Cut';
  final Map<String, String> _plannedWorkouts = {};
  final List<DateTime> _completedWorkoutDates = [
    DateTime.now().subtract(const Duration(days: 0)),
    DateTime.now().subtract(const Duration(days: 1)),
    DateTime.now().subtract(const Duration(days: 2)),
    DateTime.now().subtract(const Duration(days: 3)),
  ];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = _prefs.getString('mission_fit_name') ?? _name;
      _age = _prefs.getString('mission_fit_age') ?? _age;

      final savedHeightValue = _prefs.getDouble('mission_fit_height_value');
      if (savedHeightValue != null) {
        _heightValue = savedHeightValue;
      } else {
        final heightText = _prefs.getString('mission_fit_height') ?? '180 cm';
        final parsed = _parseNumericValue(heightText);
        if (parsed > 0) {
          _heightValue = parsed;
        }
      }
      _heightUnit =
          _prefs.getString('mission_fit_height_unit') ??
          (_prefs.getString('mission_fit_height')?.contains('in') ?? false
              ? 'in'
              : 'cm');

      final savedWeightValue = _prefs.getDouble('mission_fit_weight_value');
      if (savedWeightValue != null) {
        _weightValue = savedWeightValue;
      } else {
        final weightText = _prefs.getString('mission_fit_weight') ?? '74 kg';
        final parsed = _parseNumericValue(weightText);
        if (parsed > 0) {
          _weightValue = parsed;
        }
      }
      _weightUnit =
          _prefs.getString('mission_fit_weight_unit') ??
          (_prefs.getString('mission_fit_weight')?.contains('lbs') ?? false
              ? 'lbs'
              : 'kg');

      _sex = _prefs.getString('mission_fit_sex') ?? _sex;
      _activityLevel =
          _prefs.getString('mission_fit_activity_level') ?? _activityLevel;
      _instagram = _prefs.getString('mission_fit_instagram') ?? _instagram;
      _x = _prefs.getString('mission_fit_x') ?? _x;
      _strava = _prefs.getString('mission_fit_strava') ?? _strava;
      _goal = _prefs.getString('mission_fit_goal') ?? _goal;
      _workoutName =
          _prefs.getString('mission_fit_workout_name') ?? _workoutName;
      _quickStart =
          _prefs.getStringList('mission_fit_quick_start') ?? _quickStart;
      final encodedPlans = _prefs.getString('mission_fit_planned_workouts');
      if (encodedPlans != null && encodedPlans.isNotEmpty) {
        try {
          final data = jsonDecode(encodedPlans) as Map<String, dynamic>;
          _plannedWorkouts
            ..clear()
            ..addAll(data.map((key, value) => MapEntry(key, value.toString())));
        } catch (_) {
          _plannedWorkouts.clear();
        }
      }

      final encodedFood = _prefs.getString('mission_fit_food_entries');
      if (encodedFood != null && encodedFood.isNotEmpty) {
        try {
          final data = jsonDecode(encodedFood) as List<dynamic>;
          _foodEntries = data
              .map((item) => FoodEntry.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {
          final legacy = _prefs.getStringList('mission_fit_food_log') ?? [];
          _foodEntries = legacy
              .map(
                (item) => FoodEntry(
                  name: item,
                  calories: 0,
                  protein: 0,
                  carbs: 0,
                  fat: 0,
                ),
              )
              .toList();
        }
      } else {
        final legacy = _prefs.getStringList('mission_fit_food_log') ?? [];
        _foodEntries = legacy
            .map(
              (item) => FoodEntry(
                name: item,
                calories: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
              ),
            )
            .toList();
      }

      final encodedMeals = _prefs.getString('mission_fit_saved_meals');
      if (encodedMeals != null && encodedMeals.isNotEmpty) {
        try {
          final data = jsonDecode(encodedMeals) as List<dynamic>;
          _savedMeals = data
              .map((item) => MealPreset.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {
          _savedMeals = _savedMeals;
        }
      }

      final encoded = _prefs.getString('mission_fit_exercises');
      if (encoded != null && encoded.isNotEmpty) {
        try {
          final data = jsonDecode(encoded) as List<dynamic>;
          _exercises = data
              .map((item) => WorkoutExercise.fromJson(item))
              .toList();
        } catch (_) {
          _exercises = _exercises;
        }
      }
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setString('mission_fit_name', _name);
    await _prefs.setString('mission_fit_age', _age);
    await _prefs.setDouble('mission_fit_height_value', _heightValue);
    await _prefs.setString('mission_fit_height_unit', _heightUnit);
    await _prefs.setDouble('mission_fit_weight_value', _weightValue);
    await _prefs.setString('mission_fit_weight_unit', _weightUnit);
    await _prefs.setString(
      'mission_fit_height',
      '${_heightValue.toStringAsFixed(_heightValue.truncateToDouble() == _heightValue ? 0 : 1)} $_heightUnit',
    );
    await _prefs.setString(
      'mission_fit_weight',
      '${_weightValue.toStringAsFixed(_weightValue.truncateToDouble() == _weightValue ? 0 : 1)} $_weightUnit',
    );
    await _prefs.setString('mission_fit_sex', _sex);
    await _prefs.setString('mission_fit_activity_level', _activityLevel);
    await _prefs.setString('mission_fit_instagram', _instagram);
    await _prefs.setString('mission_fit_x', _x);
    await _prefs.setString('mission_fit_strava', _strava);
    await _prefs.setString('mission_fit_goal', _goal);
    await _prefs.setString('mission_fit_workout_name', _workoutName);
    await _prefs.setStringList('mission_fit_quick_start', _quickStart);
    await _prefs.setString(
      'mission_fit_planned_workouts',
      jsonEncode(_plannedWorkouts),
    );
    await _prefs.setString(
      'mission_fit_food_entries',
      jsonEncode(_foodEntries.map((entry) => entry.toJson()).toList()),
    );
    await _prefs.setStringList(
      'mission_fit_food_log',
      _foodEntries.map((entry) => entry.name).toList(),
    );
    await _prefs.setString(
      'mission_fit_saved_meals',
      jsonEncode(_savedMeals.map((meal) => meal.toJson()).toList()),
    );
    await _prefs.setString(
      'mission_fit_exercises',
      jsonEncode(_exercises.map((exercise) => exercise.toJson()).toList()),
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String workoutForDate(DateTime date) =>
      _plannedWorkouts[_dateKey(date)] ?? _workoutName;

  List<WorkoutExercise> exercisesForWorkout(String workoutName) =>
      _quickStartWorkouts[workoutName] ?? _exercises;

  void planWorkout(DateTime date, String workoutName) {
    setState(() {
      _plannedWorkouts[_dateKey(date)] = workoutName;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeTabView(parent: this),
      WorkoutsTabView(parent: this),
      FoodTabView(parent: this),
      SettingsTabView(parent: this),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Semantics(
          label: 'Mission Fit',
          child: SizedBox(
            width: 56,
            height: 48,
            child: Image.asset(
              'src/assets/mission_fit_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: kMissionFitDominant,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: kMissionFitSurface,
        indicatorColor: kMissionFitAccent,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: List.generate(4, (index) {
          return NavigationDestination(
            icon: Icon(_tabIcons[index]),
            label: _tabLabels[index],
          );
        }),
      ),
    );
  }

  void _showQuickStartEditor() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String selectedWorkout = _selectedQuickStartWorkout;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final workoutExercises =
                _quickStartWorkouts[selectedWorkout] ??
                const <WorkoutExercise>[];
            return AlertDialog(
              backgroundColor: kMissionFitSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              title: const Text('Edit Quick Start'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected workout',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _quickStart.contains(selectedWorkout)
                            ? selectedWorkout
                            : _quickStart.first,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: kMissionFitSurfaceStrong,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _quickStart
                            .map(
                              (workout) => DropdownMenuItem(
                                value: workout,
                                child: Text(workout),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedWorkout = value;
                            _selectedQuickStartWorkout = value;
                          });
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      if (workoutExercises.isEmpty)
                        const Text('No exercises yet.')
                      else
                        ...workoutExercises.asMap().entries.map((entry) {
                          final index = entry.key;
                          final workoutExercise = entry.value;
                          final setCount = workoutExercise.setEntries.length;
                          final currentWeight = workoutExercise.setEntries
                              .map((set) => set.weight)
                              .firstWhere(
                                (weight) => weight.isNotEmpty,
                                orElse: () => workoutExercise.weight,
                              );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
                              decoration: BoxDecoration(
                                color: kMissionFitSurfaceSoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: workoutExercise.name,
                                          decoration: const InputDecoration(
                                            labelText: 'Exercise name',
                                            isDense: true,
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            contentPadding: EdgeInsets.fromLTRB(
                                              12,
                                              16,
                                              12,
                                              10,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(10),
                                              ),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setDialogState(() {
                                              final updated =
                                                  List<WorkoutExercise>.from(
                                                    _quickStartWorkouts[selectedWorkout] ??
                                                        const <
                                                          WorkoutExercise
                                                        >[],
                                                  );
                                              updated[index] = workoutExercise
                                                  .copyWith(name: value);
                                              _quickStartWorkouts[selectedWorkout] =
                                                  updated;
                                            });
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            final updated =
                                                List<WorkoutExercise>.from(
                                                  _quickStartWorkouts[selectedWorkout] ??
                                                      const <WorkoutExercise>[],
                                                )..removeAt(index);
                                            _quickStartWorkouts[selectedWorkout] =
                                                updated;
                                          });
                                          setState(() {});
                                        },
                                        icon: const Icon(Icons.close_rounded),
                                        color: Colors.redAccent,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: currentWeight,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9.]'),
                                            ),
                                          ],
                                          decoration: const InputDecoration(
                                            labelText: 'Weight',
                                            isDense: true,
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            contentPadding: EdgeInsets.fromLTRB(
                                              12,
                                              16,
                                              12,
                                              10,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(10),
                                              ),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            final updatedSets = workoutExercise
                                                .setEntries
                                                .map(
                                                  (set) => set.copyWith(
                                                    weight: value,
                                                  ),
                                                )
                                                .toList();
                                            setDialogState(() {
                                              final updated =
                                                  List<WorkoutExercise>.from(
                                                    _quickStartWorkouts[selectedWorkout] ??
                                                        const <
                                                          WorkoutExercise
                                                        >[],
                                                  );
                                              updated[index] = workoutExercise
                                                  .copyWith(
                                                    weight: value,
                                                    setEntries: updatedSets,
                                                  );
                                              _quickStartWorkouts[selectedWorkout] =
                                                  updated;
                                            });
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: 92,
                                        child: TextFormField(
                                          initialValue: setCount.toString(),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: const InputDecoration(
                                            labelText: 'Sets',
                                            isDense: true,
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            contentPadding: EdgeInsets.fromLTRB(
                                              12,
                                              16,
                                              12,
                                              10,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(10),
                                              ),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            final requestedCount =
                                                int.tryParse(value) ?? setCount;
                                            final targetCount = requestedCount
                                                .clamp(1, 20);
                                            final updatedSets =
                                                List<WorkoutSetEntry>.from(
                                                  workoutExercise.setEntries,
                                                );
                                            while (updatedSets.length <
                                                targetCount) {
                                              updatedSets.add(
                                                WorkoutSetEntry(
                                                  weight: currentWeight,
                                                  reps: '8',
                                                  isWon: false,
                                                  isComplete: false,
                                                ),
                                              );
                                            }
                                            if (updatedSets.length >
                                                targetCount) {
                                              updatedSets.removeRange(
                                                targetCount,
                                                updatedSets.length,
                                              );
                                            }
                                            setDialogState(() {
                                              final updated =
                                                  List<WorkoutExercise>.from(
                                                    _quickStartWorkouts[selectedWorkout] ??
                                                        const <
                                                          WorkoutExercise
                                                        >[],
                                                  );
                                              updated[index] = workoutExercise
                                                  .copyWith(
                                                    setEntries: updatedSets,
                                                  );
                                              _quickStartWorkouts[selectedWorkout] =
                                                  updated;
                                            });
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setDialogState(() {
                                  final current =
                                      _quickStartWorkouts[selectedWorkout] ??
                                      <WorkoutExercise>[];
                                  _quickStartWorkouts[selectedWorkout] = [
                                    ...current,
                                    const WorkoutExercise(
                                      name: 'New Exercise',
                                      weight: '50',
                                      setEntries: [
                                        WorkoutSetEntry(
                                          reps: '8',
                                          isWon: false,
                                          isComplete: false,
                                        ),
                                      ],
                                    ),
                                  ];
                                });
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kMissionFitSurface,
                                foregroundColor: kMissionFitLight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Add Exercise'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _saveSettings();
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double _parseNumericValue(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  double _convertToMetricValue(double value, String unit) =>
      convertToMetricValue(value, unit);

  double _bmr() {
    final weightKg = _convertToMetricValue(_weightValue, _weightUnit);
    final heightCm = _convertToMetricValue(_heightValue, _heightUnit);
    final ageValue = _parseNumericValue(_age);

    if (_sex.toLowerCase() == 'female' || _sex.toLowerCase() == 'woman') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * ageValue) - 161;
    }

    return (10 * weightKg) + (6.25 * heightCm) - (5 * ageValue) + 5;
  }

  double _activityMultiplier() {
    switch (_activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.2;
      case 'light':
        return 1.375;
      case 'moderate':
        return 1.55;
      case 'active':
        return 1.725;
      case 'extreme':
        return 1.98;
      default:
        return 1.55;
    }
  }

  double _calculateTdee() {
    return _bmr() * _activityMultiplier();
  }

  double _calculateCalorieGoal() {
    final tdee = _calculateTdee();
    switch (_goal) {
      case 'Cut':
        return tdee - 400;
      case 'Bulk':
        return tdee + 400;
      case 'Maintain':
      default:
        return tdee;
    }
  }
}

class WorkoutDetailScreen extends StatefulWidget {
  final String workoutName;
  final List<WorkoutExercise> exercises;
  final VoidCallback onComplete;

  const WorkoutDetailScreen({
    super.key,
    required this.workoutName,
    required this.exercises,
    required this.onComplete,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late List<WorkoutExercise> _exercises;

  @override
  void initState() {
    super.initState();
    _exercises = List<WorkoutExercise>.from(widget.exercises);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutName),
        backgroundColor: kMissionFitDominant,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _exercises.length,
                itemBuilder: (context, exerciseIndex) {
                  final exercise = _exercises[exerciseIndex];
                  final isExerciseComplete =
                      exercise.setEntries.isNotEmpty &&
                      exercise.setEntries.every((set) => set.isComplete);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isExerciseComplete
                          ? kMissionFitAccent
                          : kMissionFitSurface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                exercise.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isExerciseComplete
                                      ? kMissionFitDominant
                                      : Colors.white,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final completed = !isExerciseComplete;
                                setState(() {
                                  _exercises[exerciseIndex] =
                                      _exercises[exerciseIndex].copyWith(
                                        setEntries: exercise.setEntries
                                            .map(
                                              (set) => set.copyWith(
                                                isComplete: completed,
                                              ),
                                            )
                                            .toList(),
                                      );
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isExerciseComplete
                                    ? kMissionFitSurface
                                    : kMissionFitAccent,
                                foregroundColor: isExerciseComplete
                                    ? Colors.white
                                    : kMissionFitDominant,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Done'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...exercise.setEntries.asMap().entries.map((entry) {
                          final setIndex = entry.key;
                          final set = entry.value;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _exercises[exerciseIndex] =
                                          _exercises[exerciseIndex].copyWith(
                                            setEntries:
                                                List<WorkoutSetEntry>.from(
                                                    _exercises[exerciseIndex]
                                                        .setEntries,
                                                  )
                                                  ..[setIndex] = set.copyWith(
                                                    isWon: !set.isWon,
                                                  ),
                                          );
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: set.isWon
                                        ? kMissionFitAccent
                                        : kMissionFitSurfaceSoft,
                                    foregroundColor: set.isWon
                                        ? kMissionFitDominant
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text('W'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: set.weight,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]'),
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Weight',
                                      isDense: true,
                                      labelStyle: TextStyle(
                                        color: isExerciseComplete
                                            ? kMissionFitDominant
                                            : kMissionFitMuted,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: isExerciseComplete
                                          ? kMissionFitDominant
                                          : Colors.white,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _exercises[exerciseIndex] =
                                            _exercises[exerciseIndex].copyWith(
                                              setEntries:
                                                  List<WorkoutSetEntry>.from(
                                                      _exercises[exerciseIndex]
                                                          .setEntries,
                                                    )
                                                    ..[setIndex] = set.copyWith(
                                                      weight: value,
                                                    ),
                                            );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: set.reps,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Reps',
                                      isDense: true,
                                      labelStyle: TextStyle(
                                        color: isExerciseComplete
                                            ? kMissionFitDominant
                                            : kMissionFitMuted,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: isExerciseComplete
                                          ? kMissionFitDominant
                                          : Colors.white,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _exercises[exerciseIndex] =
                                            _exercises[exerciseIndex].copyWith(
                                              setEntries:
                                                  List<WorkoutSetEntry>.from(
                                                      _exercises[exerciseIndex]
                                                          .setEntries,
                                                    )
                                                    ..[setIndex] = set.copyWith(
                                                      reps: value,
                                                    ),
                                            );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _exercises[exerciseIndex] =
                                          _exercises[exerciseIndex].copyWith(
                                            setEntries:
                                                List<WorkoutSetEntry>.from(
                                                    _exercises[exerciseIndex]
                                                        .setEntries,
                                                  )
                                                  ..[setIndex] = set.copyWith(
                                                    isComplete: !set.isComplete,
                                                  ),
                                          );
                                    });
                                  },
                                  icon: Icon(
                                    set.isComplete
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                  ),
                                  color: isExerciseComplete
                                      ? kMissionFitDominant
                                      : set.isComplete
                                      ? kMissionFitAccent
                                      : kMissionFitMuted,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onComplete();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMissionFitAccent,
                  foregroundColor: kMissionFitDominant,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Complete',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutBuilderScreen extends StatefulWidget {
  final void Function(String workoutName, List<WorkoutExercise>) onSave;

  const WorkoutBuilderScreen({super.key, required this.onSave});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  final TextEditingController _nameController = TextEditingController(
    text: 'Push Day',
  );
  final List<WorkoutExercise> _exercises = [
    WorkoutExercise(
      name: 'Bench Press',
      weight: '80',
      setEntries: [
        const WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
        const WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
        const WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
        const WorkoutSetEntry(reps: '6', isWon: false, isComplete: false),
      ],
    ),
    WorkoutExercise(
      name: 'Rows',
      weight: '60',
      setEntries: [
        const WorkoutSetEntry(reps: '10', isWon: false, isComplete: false),
        const WorkoutSetEntry(reps: '10', isWon: false, isComplete: false),
        const WorkoutSetEntry(reps: '8', isWon: false, isComplete: false),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Workout'),
        backgroundColor: kMissionFitDominant,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Workout Name'),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.builder(
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return Card(
                    color: kMissionFitSurface,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: TextEditingController(
                                    text: exercise.name,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Exercise',
                                  ),
                                  onChanged: (value) => _exercises[index] =
                                      _exercises[index].copyWith(name: value),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _exercises.removeAt(index);
                                  });
                                },
                                icon: const Icon(Icons.close_rounded),
                                color: Colors.redAccent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const SizedBox(width: 56),
                              const SizedBox(width: 8),
                              const Expanded(child: SizedBox.shrink()),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  'Weight',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const SizedBox(width: 64),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  'Reps',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const SizedBox(width: 40),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...exercise.setEntries.asMap().entries.map((entry) {
                            final setIndex = entry.key + 1;
                            final set = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _exercises[index] = _exercises[index]
                                            .copyWith(
                                              setEntries:
                                                  List<WorkoutSetEntry>.from(
                                                      _exercises[index]
                                                          .setEntries,
                                                    )
                                                    ..[entry.key] = set
                                                        .copyWith(
                                                          isWon: !set.isWon,
                                                        ),
                                            );
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: set.isWon
                                          ? kMissionFitAccent
                                          : kMissionFitSurfaceSoft,
                                      foregroundColor: set.isWon
                                          ? kMissionFitDominant
                                          : Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                    ),
                                    child: const Text('W'),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text('Set $setIndex'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 80,
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: set.weight,
                                      ),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      onChanged: (value) {
                                        setState(() {
                                          _exercises[index] = _exercises[index]
                                              .copyWith(
                                                setEntries:
                                                    List<WorkoutSetEntry>.from(
                                                        _exercises[index]
                                                            .setEntries,
                                                      )
                                                      ..[entry.key] = set
                                                          .copyWith(
                                                            weight: value,
                                                          ),
                                              );
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 64,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: set.weightUnit,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: kMissionFitSurfaceStrong,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'kg',
                                          child: Text('kg'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'lbs',
                                          child: Text('lbs'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() {
                                          _exercises[index] = _exercises[index]
                                              .copyWith(
                                                setEntries:
                                                    List<WorkoutSetEntry>.from(
                                                        _exercises[index]
                                                            .setEntries,
                                                      )
                                                      ..[entry.key] = set
                                                          .copyWith(
                                                            weightUnit: value,
                                                          ),
                                              );
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 70,
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: set.reps,
                                      ),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      onChanged: (value) {
                                        setState(() {
                                          _exercises[index] = _exercises[index]
                                              .copyWith(
                                                setEntries:
                                                    List<WorkoutSetEntry>.from(
                                                        _exercises[index]
                                                            .setEntries,
                                                      )
                                                      ..[entry.key] = set
                                                          .copyWith(
                                                            reps: value,
                                                          ),
                                              );
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _exercises[index] = _exercises[index]
                                            .copyWith(
                                              setEntries:
                                                  List<WorkoutSetEntry>.from(
                                                      _exercises[index]
                                                          .setEntries,
                                                    )
                                                    ..[entry.key] = set
                                                        .copyWith(
                                                          isComplete:
                                                              !set.isComplete,
                                                        ),
                                            );
                                      });
                                    },
                                    icon: Icon(
                                      set.isComplete
                                          ? Icons.check_circle_rounded
                                          : Icons
                                                .radio_button_unchecked_rounded,
                                    ),
                                    color: set.isComplete
                                        ? kMissionFitAccent
                                        : kMissionFitMuted,
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _exercises[index] = _exercises[index].copyWith(
                                  setEntries: [
                                    ..._exercises[index].setEntries,
                                    const WorkoutSetEntry(
                                      weight: '0',
                                      reps: '8',
                                      isWon: false,
                                      isComplete: false,
                                    ),
                                  ],
                                );
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Set'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _exercises.add(
                          WorkoutExercise(
                            name: 'New Exercise',
                            weight: '50',
                            setEntries: [
                              const WorkoutSetEntry(
                                weight: '0',
                                reps: '8',
                                isWon: false,
                                isComplete: false,
                              ),
                              const WorkoutSetEntry(
                                weight: '0',
                                reps: '8',
                                isWon: false,
                                isComplete: false,
                              ),
                              const WorkoutSetEntry(
                                weight: '0',
                                reps: '8',
                                isWon: false,
                                isComplete: false,
                              ),
                            ],
                          ),
                        );
                      });
                    },
                    child: const Text('Add Exercise'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(
                        _nameController.text.trim().isEmpty
                            ? 'Push Day'
                            : _nameController.text.trim(),
                        _exercises,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMissionFitAccent,
                      foregroundColor: kMissionFitDominant,
                    ),
                    child: const Text('Save Workout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String suffix;
  final double progress;
  final Color progressColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.suffix,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kMissionFitSurfaceStrong,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: kMissionFitMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: kMissionFitSurfaceSoft,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        suffix,
                        style: const TextStyle(
                          fontSize: 12,
                          color: kMissionFitMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;

  const _MacroRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: kMissionFitMuted)),
        ],
      ),
    );
  }
}

class FoodEntry {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const FoodEntry({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  FoodEntry copyWith({
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    return FoodEntry(
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      name: json['name']?.toString() ?? 'Food',
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MealPreset {
  final String name;
  final List<FoodEntry> items;
  final bool isSelected;

  const MealPreset({
    required this.name,
    required this.items,
    this.isSelected = false,
  });

  MealPreset copyWith({
    String? name,
    List<FoodEntry>? items,
    bool? isSelected,
  }) {
    return MealPreset(
      name: name ?? this.name,
      items: items ?? this.items,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'items': items.map((item) => item.toJson()).toList(),
    'isSelected': isSelected,
  };

  factory MealPreset.fromJson(Map<String, dynamic> json) {
    return MealPreset(
      name: json['name']?.toString() ?? 'Meal',
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => FoodEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }
}

class _FoodEntrySheet extends StatefulWidget {
  final MissionFitHomeState parent;
  final FoodEntry? initialEntry;
  final void Function(FoodEntry)? onSave;
  final MealPreset? initialMeal;
  final void Function(MealPreset)? onSaveMeal;

  const _FoodEntrySheet({
    required this.parent,
    this.initialEntry,
    this.onSave,
    this.initialMeal,
    this.onSaveMeal,
  });

  @override
  State<_FoodEntrySheet> createState() => _FoodEntrySheetState();
}

class _FoodEntrySheetState extends State<_FoodEntrySheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  final List<FoodEntry> _mealItems = [];
  late final TextEditingController _mealNameController;

  @override
  void initState() {
    super.initState();
    final entry =
        widget.initialEntry ??
        const FoodEntry(name: '', calories: 0, protein: 0, carbs: 0, fat: 0);
    _nameController = TextEditingController(text: entry.name);
    _caloriesController = TextEditingController(
      text: entry.calories == 0 ? '' : entry.calories.toStringAsFixed(0),
    );
    _proteinController = TextEditingController(
      text: entry.protein == 0 ? '' : entry.protein.toStringAsFixed(0),
    );
    _carbsController = TextEditingController(
      text: entry.carbs == 0 ? '' : entry.carbs.toStringAsFixed(0),
    );
    _fatController = TextEditingController(
      text: entry.fat == 0 ? '' : entry.fat.toStringAsFixed(0),
    );
    _mealNameController = TextEditingController(
      text: widget.initialMeal?.name ?? 'Custom Meal',
    );
    if (widget.initialMeal != null) {
      _mealItems.addAll(widget.initialMeal!.items);
    } else if (widget.initialEntry == null) {
      _mealItems.add(
        const FoodEntry(
          name: 'Food item',
          calories: 250,
          protein: 20,
          carbs: 22,
          fat: 8,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _mealNameController.dispose();
    super.dispose();
  }

  FoodEntry _buildEntryFromFields() {
    return FoodEntry(
      name: _nameController.text.trim().isEmpty
          ? 'Food item'
          : _nameController.text.trim(),
      calories: double.tryParse(_caloriesController.text) ?? 0,
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
    );
  }

  double _mealCalories() =>
      _mealItems.fold<double>(0, (sum, item) => sum + item.calories);
  double _mealProtein() =>
      _mealItems.fold<double>(0, (sum, item) => sum + item.protein);
  double _mealCarbs() =>
      _mealItems.fold<double>(0, (sum, item) => sum + item.carbs);
  double _mealFat() =>
      _mealItems.fold<double>(0, (sum, item) => sum + item.fat);

  void _addFoodEntryToLog(FoodEntry entry) {
    final state = widget.parent;

    state.setState(() {
      state._foodEntries.add(entry);
    });
    state._saveSettings();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _addMealToLog({
    required String mealName,
    required List<FoodEntry> items,
  }) {
    final state = widget.parent;

    final logEntries = items.map((item) {
      final normalizedName = item.name.trim().isEmpty
          ? mealName
          : item.name.trim();
      return FoodEntry(
        name: normalizedName,
        calories: item.calories,
        protein: item.protein,
        carbs: item.carbs,
        fat: item.fat,
      );
    }).toList();

    state.setState(() {
      state._foodEntries.addAll(logEntries);
    });
    state._saveSettings();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.parent;
    final savedMeals = state._savedMeals;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: kMissionFitDominant,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DefaultTabController(
          length: 4,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    const Text(
                      'Add Food',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.edit_rounded), text: 'Manual'),
                  Tab(icon: Icon(Icons.qr_code_rounded), text: 'Scan'),
                  Tab(icon: Icon(Icons.restaurant_rounded), text: 'Add Meal'),
                  Tab(icon: Icon(Icons.bookmarks_rounded), text: 'Saved Meals'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Search food / nutrition details'),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Search food item',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Food name',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _caloriesController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Calories',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _proteinController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Protein',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _carbsController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Carbs',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _fatController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Fat',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                final entry = _buildEntryFromFields();
                                if (widget.onSave != null) {
                                  widget.onSave!(entry);
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                  return;
                                }
                                _addFoodEntryToLog(entry);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kMissionFitAccent,
                                foregroundColor: kMissionFitDominant,
                              ),
                              child: const Text('Add To Food Log'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scan a barcode to look up nutritional values online.',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Barcode / product code',
                              prefixIcon: Icon(Icons.qr_code_scanner_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final scanned = FoodEntry(
                                  name: 'Scanned Food',
                                  calories: 310,
                                  protein: 18,
                                  carbs: 35,
                                  fat: 9,
                                );
                                _addFoodEntryToLog(scanned);
                              },
                              icon: const Icon(Icons.camera_alt_rounded),
                              label: const Text('Add To Food Log'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kMissionFitAccent,
                                foregroundColor: kMissionFitDominant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _mealNameController,
                              decoration: const InputDecoration(
                                labelText: 'Meal name',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._mealItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kMissionFitSurfaceSoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: TextEditingController(
                                        text: item.name,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Item name',
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _mealItems[index] = _mealItems[index]
                                              .copyWith(name: value);
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: TextEditingController(
                                              text: item.calories
                                                  .toStringAsFixed(0),
                                            ),
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: const InputDecoration(
                                              labelText: 'kcal',
                                            ),
                                            onChanged: (value) {
                                              final parsed =
                                                  double.tryParse(value) ?? 0;
                                              setState(() {
                                                _mealItems[index] =
                                                    _mealItems[index].copyWith(
                                                      calories: parsed,
                                                    );
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: TextEditingController(
                                              text: item.protein
                                                  .toStringAsFixed(0),
                                            ),
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: const InputDecoration(
                                              labelText: 'Protein',
                                            ),
                                            onChanged: (value) {
                                              final parsed =
                                                  double.tryParse(value) ?? 0;
                                              setState(() {
                                                _mealItems[index] =
                                                    _mealItems[index].copyWith(
                                                      protein: parsed,
                                                    );
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: TextEditingController(
                                              text: item.carbs.toStringAsFixed(
                                                0,
                                              ),
                                            ),
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: const InputDecoration(
                                              labelText: 'Carbs',
                                            ),
                                            onChanged: (value) {
                                              final parsed =
                                                  double.tryParse(value) ?? 0;
                                              setState(() {
                                                _mealItems[index] =
                                                    _mealItems[index].copyWith(
                                                      carbs: parsed,
                                                    );
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: TextEditingController(
                                              text: item.fat.toStringAsFixed(0),
                                            ),
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: const InputDecoration(
                                              labelText: 'Fats',
                                            ),
                                            onChanged: (value) {
                                              final parsed =
                                                  double.tryParse(value) ?? 0;
                                              setState(() {
                                                _mealItems[index] =
                                                    _mealItems[index].copyWith(
                                                      fat: parsed,
                                                    );
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _mealItems.add(
                                          const FoodEntry(
                                            name: 'Food item',
                                            calories: 200,
                                            protein: 15,
                                            carbs: 20,
                                            fat: 5,
                                          ),
                                        );
                                      });
                                    },
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Add Item'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kMissionFitSurfaceStrong,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Meal total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('${_mealCalories().round()} kcal'),
                                  Text('Protein ${_mealProtein().round()}g'),
                                  Text('Carbs ${_mealCarbs().round()}g'),
                                  Text('Fats ${_mealFat().round()}g'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final meal = MealPreset(
                                    name:
                                        _mealNameController.text.trim().isEmpty
                                        ? 'Custom Meal'
                                        : _mealNameController.text.trim(),
                                    items: List<FoodEntry>.from(_mealItems),
                                  );
                                  if (widget.onSaveMeal != null) {
                                    widget.onSaveMeal!(meal);
                                    Navigator.pop(context);
                                    return;
                                  }
                                  state.setState(() {
                                    state._savedMeals.add(meal);
                                  });
                                  setState(() {});
                                  state._saveSettings();
                                  DefaultTabController.of(context).animateTo(3);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Meal saved for later.'),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kMissionFitAccent,
                                  foregroundColor: kMissionFitDominant,
                                ),
                                child: const Text('Save Meal'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  final meal = MealPreset(
                                    name:
                                        _mealNameController.text.trim().isEmpty
                                        ? 'Custom Meal'
                                        : _mealNameController.text.trim(),
                                    items: List<FoodEntry>.from(_mealItems),
                                  );
                                  _addMealToLog(
                                    mealName: meal.name,
                                    items: meal.items,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: kMissionFitSecondary,
                                  ),
                                ),
                                child: const Text('Add To Food Log'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (savedMeals.isEmpty)
                            const Text('No saved meals yet.'),
                          ...savedMeals.asMap().entries.map((entry) {
                            final meal = entry.value;
                            final mealCalories = meal.items.fold<double>(
                              0,
                              (sum, item) => sum + item.calories,
                            );
                            final mealProtein = meal.items.fold<double>(
                              0,
                              (sum, item) => sum + item.protein,
                            );
                            final mealCarbs = meal.items.fold<double>(
                              0,
                              (sum, item) => sum + item.carbs,
                            );
                            final mealFat = meal.items.fold<double>(
                              0,
                              (sum, item) => sum + item.fat,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kMissionFitSurfaceSoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          meal.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (sheetContext) =>
                                                _FoodEntrySheet(
                                                  parent: state,
                                                  initialMeal: meal,
                                                  onSaveMeal: (updatedMeal) {
                                                    state.setState(() {
                                                      state._savedMeals[entry
                                                          .key] = updatedMeal
                                                          .copyWith(
                                                            isSelected:
                                                                meal.isSelected,
                                                          );
                                                    });
                                                    state._saveSettings();
                                                  },
                                                ),
                                          );
                                        },
                                        child: const Text('Edit'),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          state.setState(() {
                                            state._savedMeals[entry.key] = state
                                                ._savedMeals[entry.key]
                                                .copyWith(
                                                  isSelected: !meal.isSelected,
                                                );
                                          });
                                          state._saveSettings();
                                        },
                                        icon: Icon(
                                          meal.isSelected
                                              ? Icons.check_circle_rounded
                                              : Icons
                                                    .radio_button_unchecked_rounded,
                                        ),
                                        color: meal.isSelected
                                            ? kMissionFitAccent
                                            : kMissionFitMuted,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('${mealCalories.round()} kcal'),
                                  Text('Protein ${mealProtein.round()}g'),
                                  Text('Carbs ${mealCarbs.round()}g'),
                                  Text('Fats ${mealFat.round()}g'),
                                ],
                              ),
                            );
                          }),
                          if (savedMeals.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final selectedMeals = state._savedMeals
                                      .where(
                                        (candidate) => candidate.isSelected,
                                      )
                                      .toList();
                                  if (selectedMeals.isEmpty) return;
                                  final selectedItems = selectedMeals
                                      .expand((candidate) => candidate.items)
                                      .toList();
                                  state.setState(() {
                                    state._foodEntries.addAll(selectedItems);
                                    for (
                                      var i = 0;
                                      i < state._savedMeals.length;
                                      i++
                                    ) {
                                      state._savedMeals[i] = state
                                          ._savedMeals[i]
                                          .copyWith(isSelected: false);
                                    }
                                  });
                                  state._saveSettings();
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kMissionFitAccent,
                                  foregroundColor: kMissionFitDominant,
                                ),
                                child: const Text('Add To Food Log'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _goalButton(String label, Color color) {
  return Container(
    height: 46,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Center(
      child: Text(
        label,
        style: TextStyle(
          color: color == kMissionFitAccent || color == kMissionFitLight
              ? kMissionFitDominant
              : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _BodyMapPainter extends CustomPainter {
  final Map<String, bool> highlightedParts;

  const _BodyMapPainter(this.highlightedParts);

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final activePaint = Paint()
      ..color = kMissionFitAccent
      ..style = PaintingStyle.fill;
    final mutedPaint = Paint()
      ..color = kMissionFitSurfaceSoft
      ..style = PaintingStyle.fill;

    final headRect = Rect.fromCenter(
      center: Offset(size.width / 2, 30),
      width: 48,
      height: 48,
    );
    final torsoRect = Rect.fromCenter(
      center: Offset(size.width / 2, 120),
      width: 72,
      height: 120,
    );
    final leftArmRect = Rect.fromLTWH(28, 100, 24, 110);
    final rightArmRect = Rect.fromLTWH(size.width - 52, 100, 24, 110);
    final leftLegRect = Rect.fromLTWH(76, 210, 30, 90);
    final rightLegRect = Rect.fromLTWH(size.width - 106, 210, 30, 90);

    canvas.drawOval(
      headRect,
      highlightedParts['Shoulders'] == true ? activePaint : mutedPaint,
    );
    canvas.drawRect(
      torsoRect,
      highlightedParts['Chest'] == true || highlightedParts['Back'] == true
          ? activePaint
          : mutedPaint,
    );
    canvas.drawRect(
      leftArmRect,
      highlightedParts['Shoulders'] == true ? activePaint : mutedPaint,
    );
    canvas.drawRect(
      rightArmRect,
      highlightedParts['Shoulders'] == true ? activePaint : mutedPaint,
    );
    canvas.drawRect(
      leftLegRect,
      highlightedParts['Legs'] == true ? activePaint : mutedPaint,
    );
    canvas.drawRect(
      rightLegRect,
      highlightedParts['Legs'] == true ? activePaint : mutedPaint,
    );

    canvas.drawOval(headRect, borderPaint);
    canvas.drawRect(torsoRect, borderPaint);
    canvas.drawRect(leftArmRect, borderPaint);
    canvas.drawRect(rightArmRect, borderPaint);
    canvas.drawRect(leftLegRect, borderPaint);
    canvas.drawRect(rightLegRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BodyMapPainter oldDelegate) {
    return highlightedParts != oldDelegate.highlightedParts;
  }
}

class WorkoutExercise {
  final String name;
  final String weight;
  final List<WorkoutSetEntry> setEntries;

  const WorkoutExercise({
    required this.name,
    required this.weight,
    required this.setEntries,
  });

  WorkoutExercise copyWith({
    String? name,
    String? weight,
    List<WorkoutSetEntry>? setEntries,
  }) {
    return WorkoutExercise(
      name: name ?? this.name,
      weight: weight ?? this.weight,
      setEntries: setEntries ?? this.setEntries,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'weight': weight,
    'setEntries': setEntries.map((entry) => entry.toJson()).toList(),
  };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      name: json['name'] ?? 'Exercise',
      weight: json['weight'] ?? '50',
      setEntries: (json['setEntries'] as List<dynamic>? ?? const [])
          .map((item) => WorkoutSetEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorkoutSetEntry {
  final String weight;
  final String reps;
  final String weightUnit;
  final bool isWon;
  final bool isComplete;

  const WorkoutSetEntry({
    this.weight = '0',
    required this.reps,
    this.weightUnit = 'kg',
    required this.isWon,
    required this.isComplete,
  });

  WorkoutSetEntry copyWith({
    String? weight,
    String? reps,
    String? weightUnit,
    bool? isWon,
    bool? isComplete,
  }) {
    return WorkoutSetEntry(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      weightUnit: weightUnit ?? this.weightUnit,
      isWon: isWon ?? this.isWon,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toJson() => {
    'weight': weight,
    'reps': reps,
    'weightUnit': weightUnit,
    'isWon': isWon,
    'isComplete': isComplete,
  };

  factory WorkoutSetEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutSetEntry(
      weight: json['weight']?.toString() ?? '0',
      reps: json['reps']?.toString() ?? '8',
      weightUnit: json['weightUnit']?.toString() ?? 'kg',
      isWon: json['isWon'] as bool? ?? false,
      isComplete: json['isComplete'] as bool? ?? false,
    );
  }
}
