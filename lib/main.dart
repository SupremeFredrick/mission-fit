import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
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
const Color kMissionFitSecondary = Color(0xFFA2A9AD);
const Color kMissionFitAccent = Color(0xFFCE0E2D);
const Color kMissionFitLight = Color(0xFFFFFFFF);
const Color kMissionFitSurface = Color(0xFF323E48);
const Color kMissionFitSurfaceStrong = Color(0xFF323E48);
const Color kMissionFitSurfaceSoft = Color(0xFF323E48);
const Color kMissionFitMuted = Color(0xFFA2A9AD);
const Color kMissionFitBorder = Color(0x52A2A9AD);

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

Future<FoodEntry?> fetchFoodEntryByBarcode(String barcode) async {
  final productCode = barcode.replaceAll(RegExp(r'[^0-9]'), '');
  if (productCode.isEmpty) return null;

  final response = await http
      .get(
        Uri.parse(
          'https://world.openfoodfacts.org/api/v0/product/$productCode.json',
        ),
      )
      .timeout(const Duration(seconds: 8));
  if (response.statusCode != 200) return null;

  final payload = jsonDecode(response.body) as Map<String, dynamic>;
  if (payload['status'] != 1) return null;
  final product = payload['product'] as Map<String, dynamic>?;
  return product == null ? null : foodEntryFromOpenFoodFactsProduct(product);
}

Future<List<FoodEntry>> searchFoodEntries(String query) async {
  if (query.trim().isEmpty) return [];
  final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
    'search_terms': query.trim(),
    'json': 'true',
    'page_size': '8',
    'fields': 'product_name,nutriments',
  });
  final response = await http.get(uri).timeout(const Duration(seconds: 8));
  if (response.statusCode != 200) return [];

  final payload = jsonDecode(response.body) as Map<String, dynamic>;
  final products = payload['products'] as List<dynamic>? ?? const [];
  return products
      .whereType<Map<String, dynamic>>()
      .map(foodEntryFromOpenFoodFactsProduct)
      .whereType<FoodEntry>()
      .toList();
}

FoodEntry? foodEntryFromOpenFoodFactsProduct(Map<String, dynamic> product) {
  final nutriments = product['nutriments'] as Map<String, dynamic>?;
  if (nutriments == null) return null;

  double nutrientValue(String key) =>
      (nutriments[key] as num?)?.toDouble() ?? 0;

  return FoodEntry(
    name: product['product_name']?.toString().trim().isNotEmpty == true
        ? product['product_name'].toString().trim()
        : 'Food item',
    calories: nutrientValue('energy-kcal_100g'),
    protein: nutrientValue('proteins_100g'),
    carbs: nutrientValue('carbohydrates_100g'),
    fat: nutrientValue('fat_100g'),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MissionFitApp());
}

class MissionFitApp extends StatelessWidget {
  final bool skipOnboarding;

  const MissionFitApp({super.key, this.skipOnboarding = false});

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
        appBarTheme: const AppBarTheme(
          backgroundColor: kMissionFitDominant,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: kMissionFitSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: kMissionFitBorder),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kMissionFitAccent,
            foregroundColor: kMissionFitDominant,
            elevation: 0,
            minimumSize: const Size(44, 48),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kMissionFitLight,
            minimumSize: const Size(44, 48),
            side: const BorderSide(color: kMissionFitSecondary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
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
      home: skipOnboarding ? const MissionFitHome() : const AppLaunchGate(),
    );
  }
}

class AppLaunchGate extends StatefulWidget {
  const AppLaunchGate({super.key});

  @override
  State<AppLaunchGate> createState() => _AppLaunchGateState();
}

class _AppLaunchGateState extends State<AppLaunchGate> {
  SharedPreferences? _preferences;
  bool? _hasCompletedOnboarding;

  @override
  void initState() {
    super.initState();
    _loadLaunchState();
  }

  Future<void> _loadLaunchState() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _hasCompletedOnboarding =
          preferences.getBool('mission_fit_onboarding_complete') ?? false;
    });
  }

  Future<void> _completeOnboarding(SetupProfile profile) async {
    final preferences = _preferences!;
    await preferences.setString('mission_fit_name', profile.name);
    await preferences.setString('mission_fit_age', profile.age);
    await preferences.setDouble('mission_fit_height_value', profile.height);
    await preferences.setString('mission_fit_height_unit', profile.heightUnit);
    await preferences.setDouble('mission_fit_weight_value', profile.weight);
    await preferences.setString('mission_fit_weight_unit', profile.weightUnit);
    await preferences.setString('mission_fit_sex', profile.sex);
    await preferences.setString(
      'mission_fit_activity_level',
      profile.activityLevel,
    );
    await preferences.setStringList('mission_fit_quick_start', []);
    await preferences.setString('mission_fit_planned_workouts', '');
    await preferences.setString('mission_fit_food_entries', '[]');
    await preferences.setStringList('mission_fit_food_log', []);
    await preferences.setString('mission_fit_saved_meals', '[]');
    await preferences.setString('mission_fit_exercises', '[]');
    await preferences.setBool('mission_fit_onboarding_complete', true);
    if (mounted) setState(() => _hasCompletedOnboarding = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasCompletedOnboarding == null) return const AppLoadingScreen();
    if (_hasCompletedOnboarding == false) {
      return ProfileSetupScreen(onComplete: _completeOnboarding);
    }
    return const MissionFitHome();
  }
}

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: kMissionFitAccent)),
    );
  }
}

class SetupProfile {
  final String name;
  final String age;
  final double height;
  final String heightUnit;
  final double weight;
  final String weightUnit;
  final String sex;
  final String activityLevel;

  const SetupProfile({
    required this.name,
    required this.age,
    required this.height,
    required this.heightUnit,
    required this.weight,
    required this.weightUnit,
    required this.sex,
    required this.activityLevel,
  });
}

class ProfileSetupScreen extends StatefulWidget {
  final Future<void> Function(SetupProfile profile) onComplete;

  const ProfileSetupScreen({super.key, required this.onComplete});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';
  String _sex = 'Male';
  String _activityLevel = 'Moderate';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    await widget.onComplete(
      SetupProfile(
        name: _nameController.text.trim(),
        age: _ageController.text.trim(),
        height: double.parse(_heightController.text),
        heightUnit: _heightUnit,
        weight: double.parse(_weightController.text),
        weightUnit: _weightUnit,
        sex: _sex,
        activityLevel: _activityLevel,
      ),
    );
    if (mounted) setState(() => _isSaving = false);
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: kMissionFitDominant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kMissionFitSecondary),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'src/assets/mission_fit_logo.png',
                        key: const ValueKey('mission-fit-setup-logo'),
                        width: 96,
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Set up your profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your information personalizes your daily targets.',
                      style: TextStyle(color: kMissionFitMuted),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: _fieldDecoration('Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _fieldDecoration('Age'),
                      validator: (value) => (int.tryParse(value ?? '') ?? 0) > 0
                          ? null
                          : 'Enter your age',
                    ),
                    const SizedBox(height: 14),
                    _measurementFields(
                      controller: _heightController,
                      label: 'Height',
                      unit: _heightUnit,
                      units: const ['cm', 'in'],
                      onUnitChanged: (value) =>
                          setState(() => _heightUnit = value),
                    ),
                    const SizedBox(height: 14),
                    _measurementFields(
                      controller: _weightController,
                      label: 'Weight',
                      unit: _weightUnit,
                      units: const ['kg', 'lbs'],
                      onUnitChanged: (value) =>
                          setState(() => _weightUnit = value),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _sex,
                      decoration: _fieldDecoration('Sex'),
                      items: const ['Male', 'Female']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _sex = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _activityLevel,
                      decoration: _fieldDecoration('Activity level'),
                      items:
                          const [
                                'Sedentary',
                                'Light',
                                'Moderate',
                                'Active',
                                'Extreme',
                              ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _activityLevel = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      child: Text(_isSaving ? 'Saving' : 'Done'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _measurementFields({
    required TextEditingController controller,
    required String label,
    required String unit,
    required List<String> units,
    required ValueChanged<String> onUnitChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: _fieldDecoration(label),
            validator: (value) =>
                (double.tryParse(value ?? '') ?? 0) > 0 ? null : 'Enter $label',
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 96,
          child: DropdownButtonFormField<String>(
            initialValue: unit,
            isExpanded: true,
            decoration: _fieldDecoration(''),
            items: units
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onUnitChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class MissionFitHome extends StatefulWidget {
  const MissionFitHome({super.key});

  @override
  State<MissionFitHome> createState() => MissionFitHomeState();
}

class MissionFitHomeState extends State<MissionFitHome> {
  int _selectedTabIndex = 0;
  late final SharedPreferences _preferences;

  final List<String> _navigationLabels = [
    'Home',
    'Workouts',
    'Food',
    'Settings',
  ];
  static const List<IconData> _navigationIcons = [
    Icons.home_rounded,
    Icons.fitness_center_rounded,
    Icons.restaurant_rounded,
    Icons.settings_rounded,
  ];

  String _profileName = '';
  String _age = '';
  double _heightValue = 0;
  String _heightUnit = 'cm';
  double _weightValue = 0;
  String _weightUnit = 'kg';
  String _sex = 'Male';
  String _activityLevel = 'Moderate';
  String _instagramHandle = '@missionfit';
  String _xHandle = '@missionfit';
  String _stravaHandle = 'missionfit';
  String _workoutName = '';
  List<String> _quickStartWorkoutNames = [];
  String _selectedQuickStartWorkout = '';
  final Map<String, List<WorkoutExercise>> _quickStartWorkouts = {};
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
  List<MealPreset> _savedMeals = [];
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
  double _waterConsumed = 2.0;
  String _dailyQuote =
      'The impediment to action advances action. What stands in the way becomes the way.';
  String _dailyQuoteAuthor = 'Marcus Aurelius';
  int? _nativeStepCount;
  double? _nativeCaloriesBurned;
  bool _isLoadingHealthData = false;
  bool get canReadNativeHealthData =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  final Map<String, String> _plannedWorkouts = {};
  final List<DateTime> _completedWorkoutDates = [];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    _preferences = await SharedPreferences.getInstance();
    setState(() {
      _profileName = _preferences.getString('mission_fit_name') ?? _profileName;
      _age = _preferences.getString('mission_fit_age') ?? _age;

      final savedHeightValue = _preferences.getDouble(
        'mission_fit_height_value',
      );
      if (savedHeightValue != null) {
        _heightValue = savedHeightValue;
      } else {
        final heightText = _preferences.getString('mission_fit_height') ?? '';
        final parsed = _parseNumericValue(heightText);
        if (parsed > 0) {
          _heightValue = parsed;
        }
      }
      _heightUnit =
          _preferences.getString('mission_fit_height_unit') ??
          (_preferences.getString('mission_fit_height')?.contains('in') ?? false
              ? 'in'
              : 'cm');

      final savedWeightValue = _preferences.getDouble(
        'mission_fit_weight_value',
      );
      if (savedWeightValue != null) {
        _weightValue = savedWeightValue;
      } else {
        final weightText = _preferences.getString('mission_fit_weight') ?? '';
        final parsed = _parseNumericValue(weightText);
        if (parsed > 0) {
          _weightValue = parsed;
        }
      }
      _weightUnit =
          _preferences.getString('mission_fit_weight_unit') ??
          (_preferences.getString('mission_fit_weight')?.contains('lbs') ??
                  false
              ? 'lbs'
              : 'kg');

      _sex = _preferences.getString('mission_fit_sex') ?? _sex;
      _activityLevel =
          _preferences.getString('mission_fit_activity_level') ??
          _activityLevel;
      _instagramHandle =
          _preferences.getString('mission_fit_instagram') ?? _instagramHandle;
      _xHandle = _preferences.getString('mission_fit_x') ?? _xHandle;
      _stravaHandle =
          _preferences.getString('mission_fit_strava') ?? _stravaHandle;
      _goal = _preferences.getString('mission_fit_goal') ?? _goal;
      _waterConsumed =
          _preferences.getDouble('mission_fit_water_consumed') ??
          _waterConsumed;
      _workoutName =
          _preferences.getString('mission_fit_workout_name') ?? _workoutName;
      _quickStartWorkoutNames =
          _preferences.getStringList('mission_fit_quick_start') ??
          _quickStartWorkoutNames;
      final encodedPlans = _preferences.getString(
        'mission_fit_planned_workouts',
      );
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

      final encodedFood = _preferences.getString('mission_fit_food_entries');
      if (encodedFood != null && encodedFood.isNotEmpty) {
        try {
          final data = jsonDecode(encodedFood) as List<dynamic>;
          _foodEntries = data
              .map((item) => FoodEntry.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {
          final legacy =
              _preferences.getStringList('mission_fit_food_log') ?? [];
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
        final legacy = _preferences.getStringList('mission_fit_food_log') ?? [];
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

      final encodedMeals = _preferences.getString('mission_fit_saved_meals');
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

      final encoded = _preferences.getString('mission_fit_exercises');
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
    await _loadDailyQuote();
  }

  Future<void> _loadDailyQuote() async {
    final todayKey = _dateKey(DateTime.now());
    final cachedDate = _preferences.getString('mission_fit_quote_date');
    final cachedQuote = _preferences.getString('mission_fit_daily_quote');
    final cachedAuthor = _preferences.getString(
      'mission_fit_daily_quote_author',
    );
    if (cachedDate == todayKey && cachedQuote != null && cachedAuthor != null) {
      if (mounted) {
        setState(() {
          _dailyQuote = cachedQuote;
          _dailyQuoteAuthor = cachedAuthor;
        });
      }
      return;
    }

    try {
      final response = await http
          .get(Uri.parse('https://stoic.tekloon.net/stoic-quote'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final quoteData = payload['data'] as Map<String, dynamic>?;
      final quote = quoteData?['quote']?.toString().trim();
      final author = quoteData?['author']?.toString().trim();
      if (quote == null || quote.isEmpty || author == null || author.isEmpty) {
        return;
      }
      if (mounted) {
        setState(() {
          _dailyQuote = quote;
          _dailyQuoteAuthor = author;
        });
      }
      await _preferences.setString('mission_fit_quote_date', todayKey);
      await _preferences.setString('mission_fit_daily_quote', quote);
      await _preferences.setString('mission_fit_daily_quote_author', author);
    } catch (_) {}
  }

  Future<bool> loadNativeActivityData() async {
    if (!canReadNativeHealthData || _isLoadingHealthData) return false;
    setState(() => _isLoadingHealthData = true);

    try {
      final health = Health();
      final types = <HealthDataType>[
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ];
      final permissions = <HealthDataAccess>[
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ];
      final granted = await health.requestAuthorization(
        types,
        permissions: permissions,
      );
      if (!granted) return false;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final points = await health.getHealthDataFromTypes(
        types: types,
        startTime: startOfDay,
        endTime: now,
      );
      final steps = await health.getTotalStepsInInterval(startOfDay, now);
      final activeCalories = points
          .where((point) => point.type == HealthDataType.ACTIVE_ENERGY_BURNED)
          .fold<double>(0, (sum, point) {
            final value = point.value;
            return sum + (value is NumericHealthValue ? value.numericValue : 0);
          });
      if (!mounted) return false;
      setState(() {
        _nativeStepCount = steps;
        _nativeCaloriesBurned = activeCalories;
      });
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) setState(() => _isLoadingHealthData = false);
    }
  }

  Future<void> _saveSettings() async {
    await _preferences.setString('mission_fit_name', _profileName);
    await _preferences.setString('mission_fit_age', _age);
    await _preferences.setDouble('mission_fit_height_value', _heightValue);
    await _preferences.setString('mission_fit_height_unit', _heightUnit);
    await _preferences.setDouble('mission_fit_weight_value', _weightValue);
    await _preferences.setString('mission_fit_weight_unit', _weightUnit);
    await _preferences.setString(
      'mission_fit_height',
      '${_heightValue.toStringAsFixed(_heightValue.truncateToDouble() == _heightValue ? 0 : 1)} $_heightUnit',
    );
    await _preferences.setString(
      'mission_fit_weight',
      '${_weightValue.toStringAsFixed(_weightValue.truncateToDouble() == _weightValue ? 0 : 1)} $_weightUnit',
    );
    await _preferences.setString('mission_fit_sex', _sex);
    await _preferences.setString('mission_fit_activity_level', _activityLevel);
    await _preferences.setString('mission_fit_instagram', _instagramHandle);
    await _preferences.setString('mission_fit_x', _xHandle);
    await _preferences.setString('mission_fit_strava', _stravaHandle);
    await _preferences.setString('mission_fit_goal', _goal);
    await _preferences.setDouble('mission_fit_water_consumed', _waterConsumed);
    await _preferences.setString('mission_fit_workout_name', _workoutName);
    await _preferences.setStringList(
      'mission_fit_quick_start',
      _quickStartWorkoutNames,
    );
    await _preferences.setString(
      'mission_fit_planned_workouts',
      jsonEncode(_plannedWorkouts),
    );
    await _preferences.setString(
      'mission_fit_food_entries',
      jsonEncode(_foodEntries.map((entry) => entry.toJson()).toList()),
    );
    await _preferences.setStringList(
      'mission_fit_food_log',
      _foodEntries.map((entry) => entry.name).toList(),
    );
    await _preferences.setString(
      'mission_fit_saved_meals',
      jsonEncode(_savedMeals.map((meal) => meal.toJson()).toList()),
    );
    await _preferences.setString(
      'mission_fit_exercises',
      jsonEncode(_exercises.map((exercise) => exercise.toJson()).toList()),
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String? plannedWorkoutForDate(DateTime date) =>
      _plannedWorkouts[_dateKey(date)];

  String workoutForDate(DateTime date) =>
      plannedWorkoutForDate(date) ?? _workoutName;

  List<WorkoutExercise> exercisesForWorkout(String workoutName) =>
      _quickStartWorkouts[workoutName] ?? _exercises;

  void planWorkout(DateTime date, String workoutName) {
    setState(() {
      _plannedWorkouts[_dateKey(date)] = workoutName;
    });
    _saveSettings();
  }

  void adjustWaterConsumed(double change) {
    setState(() {
      _waterConsumed = (_waterConsumed + change).clamp(0.0, 10.0);
    });
    _saveSettings();
  }

  void removeQuickStartWorkout(String workoutName) {
    setState(() {
      _quickStartWorkoutNames.remove(workoutName);
      _quickStartWorkouts.remove(workoutName);
      _plannedWorkouts.removeWhere(
        (_, plannedWorkout) => plannedWorkout == workoutName,
      );
      if (_selectedQuickStartWorkout == workoutName) {
        _selectedQuickStartWorkout = _quickStartWorkoutNames.isEmpty
            ? ''
            : _quickStartWorkoutNames.first;
      }
      if (_workoutName == workoutName) {
        _workoutName = _quickStartWorkoutNames.isEmpty
            ? 'New workout'
            : _quickStartWorkoutNames.first;
      }
    });
    _saveSettings();
  }

  InputDecoration _quickStartFieldDecoration({String? labelText}) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kMissionFitSecondary, width: 1.5),
    );

    return InputDecoration(
      labelText: labelText,
      isDense: true,
      filled: true,
      fillColor: kMissionFitDominant,
      contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: baseBorder.copyWith(
        borderSide: const BorderSide(color: kMissionFitAccent, width: 2),
      ),
      labelStyle: const TextStyle(color: kMissionFitMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeTabView(parent: this),
      WorkoutsTabView(parent: this),
      FoodTabView(parent: this),
      SettingsTabView(parent: this),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktopNavigation = constraints.maxWidth >= 840;
        final activeScreen = Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: screens[_selectedTabIndex],
          ),
        );

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
                  key: const ValueKey('mission-fit-header-logo'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            centerTitle: true,
          ),
          body: useDesktopNavigation
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedTabIndex,
                      onDestinationSelected: (index) =>
                          setState(() => _selectedTabIndex = index),
                      backgroundColor: kMissionFitSurface,
                      indicatorColor: kMissionFitAccent,
                      labelType: NavigationRailLabelType.all,
                      destinations: List.generate(4, (index) {
                        return NavigationRailDestination(
                          icon: Icon(_navigationIcons[index]),
                          selectedIcon: Icon(_navigationIcons[index]),
                          label: Text(_navigationLabels[index]),
                        );
                      }),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: activeScreen),
                  ],
                )
              : activeScreen,
          bottomNavigationBar: useDesktopNavigation
              ? null
              : NavigationBar(
                  selectedIndex: _selectedTabIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedTabIndex = index),
                  backgroundColor: kMissionFitSurface,
                  indicatorColor: kMissionFitAccent,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  destinations: List.generate(4, (index) {
                    return NavigationDestination(
                      icon: Icon(_navigationIcons[index]),
                      label: _navigationLabels[index],
                    );
                  }),
                ),
        );
      },
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
                        initialValue:
                            _quickStartWorkoutNames.contains(selectedWorkout)
                            ? selectedWorkout
                            : _quickStartWorkoutNames.first,
                        decoration: _quickStartFieldDecoration(),
                        items: _quickStartWorkoutNames
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
                                          decoration:
                                              _quickStartFieldDecoration(
                                                labelText: 'Exercise name',
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
                                        color: kMissionFitAccent,
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
                                          decoration:
                                              _quickStartFieldDecoration(
                                                labelText: 'Weight',
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
                                          decoration:
                                              _quickStartFieldDecoration(
                                                labelText: 'Sets',
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

  double calculateWaterGoal() {
    final weightKg = _convertToMetricValue(_weightValue, _weightUnit);
    final heightCm = _convertToMetricValue(_heightValue, _heightUnit);
    final ageYears = _parseNumericValue(_age);
    final activityAdjustment = switch (_activityLevel.toLowerCase()) {
      'sedentary' => 0.0,
      'light' => 0.2,
      'moderate' => 0.4,
      'active' => 0.6,
      'extreme' => 0.8,
      _ => 0.4,
    };
    final sexAdjustment =
        _sex.toLowerCase() == 'female' || _sex.toLowerCase() == 'woman'
        ? 0.0
        : 0.2;
    final heightAdjustment = (heightCm - 170) * 0.002;
    final ageAdjustment = ageYears >= 55
        ? -0.2
        : ageYears >= 35
        ? -0.1
        : 0.0;

    return (weightKg * 0.033 +
            activityAdjustment +
            sexAdjustment +
            heightAdjustment +
            ageAdjustment)
        .clamp(1.5, 5.0);
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
  final Stopwatch _runStopwatch = Stopwatch();
  Timer? _runTimer;

  @override
  void initState() {
    super.initState();
    _exercises = List<WorkoutExercise>.from(widget.exercises);
  }

  @override
  void dispose() {
    _runTimer?.cancel();
    super.dispose();
  }

  void _toggleRunTimer() {
    if (_runStopwatch.isRunning) {
      _runStopwatch.stop();
      _runTimer?.cancel();
    } else {
      _runStopwatch.start();
      _runTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
    setState(() {});
  }

  void _resetRunTimer() {
    _runStopwatch
      ..stop()
      ..reset();
    _runTimer?.cancel();
    setState(() {});
  }

  String get _runTimeLabel {
    final elapsed = _runStopwatch.elapsed;
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Widget _buildRunTimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kMissionFitSurfaceStrong,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text(
            'Run timer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _runTimeLabel,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleRunTimer,
                  icon: Icon(
                    _runStopwatch.isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    _runStopwatch.isRunning ? 'Pause timer' : 'Start timer',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _runStopwatch.elapsed == Duration.zero
                    ? null
                    : _resetRunTimer,
                icon: const Icon(Icons.restart_alt_rounded),
                tooltip: 'Reset timer',
              ),
            ],
          ),
        ],
      ),
    );
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
            if (widget.workoutName.toLowerCase() == 'run') ...[
              _buildRunTimer(),
              const SizedBox(height: 16),
            ],
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
  final Widget? valueControls;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.suffix,
    required this.progress,
    required this.progressColor,
    this.valueControls,
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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: kMissionFitDominant,
                        shape: BoxShape.circle,
                      ),
                    ),
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
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
              if (valueControls != null) ...[
                const SizedBox(width: 6),
                valueControls!,
              ],
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
  final TextEditingController _foodSearchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  bool _isLookingUpBarcode = false;
  String? _barcodeLookupMessage;
  List<FoodEntry> _foodSearchResults = [];
  bool _isSearchingFood = false;
  String? _foodSearchMessage;
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
    _foodSearchController.dispose();
    _barcodeController.dispose();
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

  Future<void> _lookupBarcode() async {
    final barcode = _barcodeController.text;
    if (barcode.trim().isEmpty) {
      setState(() => _barcodeLookupMessage = 'Enter a barcode first');
      return;
    }
    setState(() {
      _isLookingUpBarcode = true;
      _barcodeLookupMessage = null;
    });
    try {
      final entry = await fetchFoodEntryByBarcode(barcode);
      if (!mounted) return;
      if (entry == null) {
        setState(() => _barcodeLookupMessage = 'Product not found');
        return;
      }
      _applyFoodEntry(entry);
      setState(() => _barcodeLookupMessage = 'Product loaded per 100 g');
    } catch (_) {
      if (mounted) {
        setState(() => _barcodeLookupMessage = 'Unable to look up product');
      }
    } finally {
      if (mounted) setState(() => _isLookingUpBarcode = false);
    }
  }

  Future<void> _handleBarcodeDetection(BarcodeCapture capture) async {
    if (_isLookingUpBarcode || capture.barcodes.isEmpty) return;
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;
    _barcodeController.text = barcode;
    await _lookupBarcode();
  }

  Future<void> _searchFood() async {
    final query = _foodSearchController.text;
    if (query.trim().isEmpty) {
      setState(() => _foodSearchMessage = 'Enter a food name first');
      return;
    }
    setState(() {
      _isSearchingFood = true;
      _foodSearchMessage = null;
      _foodSearchResults = [];
    });
    try {
      final results = await searchFoodEntries(query);
      if (!mounted) return;
      setState(() {
        _foodSearchResults = results;
        _foodSearchMessage = results.isEmpty ? 'No matching foods found' : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _foodSearchMessage = 'Unable to search foods');
      }
    } finally {
      if (mounted) setState(() => _isSearchingFood = false);
    }
  }

  void _applyFoodEntry(FoodEntry entry) {
    _nameController.text = entry.name;
    _caloriesController.text = entry.calories.toStringAsFixed(0);
    _proteinController.text = entry.protein.toStringAsFixed(1);
    _carbsController.text = entry.carbs.toStringAsFixed(1);
    _fatController.text = entry.fat.toStringAsFixed(1);
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
                            controller: _foodSearchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _searchFood(),
                            decoration: const InputDecoration(
                              labelText: 'Search food item',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isSearchingFood ? null : _searchFood,
                              icon: _isSearchingFood
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.search_rounded),
                              label: const Text('Search Open Food Facts'),
                            ),
                          ),
                          if (_foodSearchMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _foodSearchMessage!,
                              style: const TextStyle(color: kMissionFitMuted),
                            ),
                          ],
                          if (_foodSearchResults.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 104,
                              child: ListView.builder(
                                itemCount: _foodSearchResults.length,
                                itemBuilder: (context, index) {
                                  final result = _foodSearchResults[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(result.name),
                                    subtitle: Text(
                                      '${result.calories.round()} kcal per 100 g',
                                    ),
                                    onTap: () {
                                      _applyFoodEntry(result);
                                      setState(() {
                                        _foodSearchResults = [];
                                        _foodSearchMessage =
                                            'Product loaded per 100 g';
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 190,
                              width: double.infinity,
                              child: MobileScanner(
                                onDetect: _handleBarcodeDetection,
                                placeholderBuilder: (context) =>
                                    const ColoredBox(
                                      color: kMissionFitSurfaceStrong,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                errorBuilder: (context, error) =>
                                    const ColoredBox(
                                      color: kMissionFitSurfaceStrong,
                                      child: Center(
                                        child: Text(
                                          'Camera access is unavailable',
                                        ),
                                      ),
                                    ),
                                overlayBuilder: (context, constraints) =>
                                    Center(
                                      child: Container(
                                        width: constraints.maxWidth * 0.78,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: kMissionFitAccent,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _barcodeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Barcode / product code',
                              prefixIcon: Icon(Icons.qr_code_scanner_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_barcodeLookupMessage != null) ...[
                            Text(
                              _barcodeLookupMessage!,
                              style: const TextStyle(color: kMissionFitMuted),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLookingUpBarcode
                                  ? null
                                  : _lookupBarcode,
                              icon: _isLookingUpBarcode
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.search_rounded),
                              label: Text(
                                _isLookingUpBarcode
                                    ? 'Looking up product'
                                    : 'Look Up Product',
                              ),
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
    canvas.save();
    canvas.scale(size.width / 300, size.height / 280);

    final outlinePaint = Paint()
      ..color = kMissionFitSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final activePaint = Paint()
      ..color = kMissionFitAccent
      ..style = PaintingStyle.fill;
    final bodyPaint = Paint()
      ..color = kMissionFitDominant
      ..style = PaintingStyle.fill;
    final labelStyle = TextStyle(
      color: kMissionFitMuted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );

    void drawPath(Path path, {bool active = false}) {
      canvas.drawPath(path, active ? activePaint : bodyPaint);
      canvas.drawPath(path, outlinePaint);
    }

    Path head(double centerX) => Path()
      ..addOval(
        Rect.fromCenter(center: Offset(centerX, 38), width: 38, height: 46),
      );
    Path torso(double centerX) => Path()
      ..moveTo(centerX - 28, 65)
      ..quadraticBezierTo(centerX - 43, 86, centerX - 35, 129)
      ..quadraticBezierTo(centerX - 29, 153, centerX - 22, 166)
      ..lineTo(centerX - 17, 184)
      ..lineTo(centerX + 17, 184)
      ..lineTo(centerX + 22, 166)
      ..quadraticBezierTo(centerX + 29, 153, centerX + 35, 129)
      ..quadraticBezierTo(centerX + 43, 86, centerX + 28, 65)
      ..close();
    Path arm(double centerX, bool left) {
      final direction = left ? -1.0 : 1.0;
      return Path()
        ..moveTo(centerX + direction * 28, 70)
        ..quadraticBezierTo(
          centerX + direction * 47,
          80,
          centerX + direction * 43,
          109,
        )
        ..lineTo(centerX + direction * 38, 156)
        ..quadraticBezierTo(
          centerX + direction * 36,
          171,
          centerX + direction * 27,
          169,
        )
        ..quadraticBezierTo(
          centerX + direction * 22,
          165,
          centerX + direction * 25,
          151,
        )
        ..lineTo(centerX + direction * 30, 107)
        ..quadraticBezierTo(
          centerX + direction * 27,
          86,
          centerX + direction * 19,
          76,
        )
        ..close();
    }

    Path leg(double centerX, bool left) {
      final direction = left ? -1.0 : 1.0;
      return Path()
        ..moveTo(centerX + direction * 16, 183)
        ..quadraticBezierTo(
          centerX + direction * 30,
          205,
          centerX + direction * 25,
          235,
        )
        ..lineTo(centerX + direction * 23, 270)
        ..lineTo(centerX + direction * 4, 270)
        ..lineTo(centerX + direction * 3, 232)
        ..quadraticBezierTo(
          centerX + direction * 4,
          204,
          centerX + direction * 1,
          184,
        )
        ..close();
    }

    void drawFigure(double centerX, {required bool isBack}) {
      drawPath(head(centerX));
      drawPath(torso(centerX));
      drawPath(arm(centerX, true));
      drawPath(arm(centerX, false));
      drawPath(leg(centerX, true));
      drawPath(leg(centerX, false));

      final shoulders = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(centerX - 25, 74),
            width: 22,
            height: 18,
          ),
        )
        ..addOval(
          Rect.fromCenter(
            center: Offset(centerX + 25, 74),
            width: 22,
            height: 18,
          ),
        );
      drawPath(shoulders, active: highlightedParts['Shoulders'] == true);

      final upperBody = Path();
      if (isBack) {
        upperBody
          ..moveTo(centerX - 26, 84)
          ..quadraticBezierTo(centerX, 100, centerX + 26, 84)
          ..lineTo(centerX + 22, 130)
          ..quadraticBezierTo(centerX, 147, centerX - 22, 130)
          ..close();
        drawPath(upperBody, active: highlightedParts['Back'] == true);
      } else {
        upperBody
          ..moveTo(centerX - 23, 87)
          ..quadraticBezierTo(centerX - 7, 81, centerX, 95)
          ..quadraticBezierTo(centerX + 7, 81, centerX + 23, 87)
          ..lineTo(centerX + 20, 119)
          ..quadraticBezierTo(centerX, 126, centerX - 20, 119)
          ..close();
        drawPath(upperBody, active: highlightedParts['Chest'] == true);
      }

      final core = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(centerX, 145),
              width: 24,
              height: 42,
            ),
            const Radius.circular(8),
          ),
        );
      drawPath(core, active: highlightedParts['Core'] == true);

      final legs = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(centerX - 24, 190, 18, 48),
            const Radius.circular(7),
          ),
        )
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(centerX + 6, 190, 18, 48),
            const Radius.circular(7),
          ),
        );
      drawPath(legs, active: highlightedParts['Legs'] == true);
    }

    drawFigure(85, isBack: false);
    drawFigure(215, isBack: true);

    void drawLabel(String text, double centerX) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(centerX - painter.width / 2, 2));
    }

    drawLabel('FRONT', 85);
    drawLabel('BACK', 215);
    canvas.restore();
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
