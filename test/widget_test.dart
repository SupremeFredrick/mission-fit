// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mission_fit/main.dart';

void main() {
  testWidgets('first launch profile setup collects required information', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ProfileSetupScreen(onComplete: (_) async {})),
    );

    expect(find.text('Set up your profile'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mission-fit-setup-logo')),
      findsOneWidget,
    );
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('Mission Fit home screen renders the predicted dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MissionFitApp(skipOnboarding: true));

    expect(find.bySemanticsLabel('Mission Fit'), findsOneWidget);
    expect(find.textContaining('Welcome'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Workouts'), findsWidgets);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Quick Start'), findsOneWidget);
  });

  testWidgets('app header uses the Mission Fit logo asset', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MissionFitApp(skipOnboarding: true));

    final logo = tester.widget<Image>(
      find.byKey(const ValueKey('mission-fit-header-logo')),
    );

    expect(logo.image, isA<AssetImage>());
    expect(
      (logo.image as AssetImage).assetName,
      'src/assets/mission_fit_logo.png',
    );
  });

  testWidgets(
    'Mission Fit home screen uses circular progress rings and circular streak items',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MissionFitApp(skipOnboarding: true));

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
        findsWidgets,
      );
    },
  );

  testWidgets('Workout detail exposes per-set numeric weight and reps inputs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutDetailScreen(
          workoutName: 'Push Day',
          exercises: [
            WorkoutExercise(
              name: 'Bench Press',
              weight: '80',
              setEntries: [
                const WorkoutSetEntry(
                  weight: '80',
                  reps: '8',
                  isWon: false,
                  isComplete: false,
                ),
              ],
            ),
          ],
          onComplete: () {},
        ),
      ),
    );

    expect(find.text('Weight'), findsWidgets);
    expect(find.text('Reps'), findsWidgets);
    expect(find.byType(TextFormField), findsWidgets);
  });

  testWidgets('Run workout provides a start timer action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutDetailScreen(
          workoutName: 'Run',
          exercises: const [
            WorkoutExercise(
              name: 'Treadmill',
              weight: '0',
              setEntries: [
                WorkoutSetEntry(reps: '15', isWon: false, isComplete: false),
              ],
            ),
          ],
          onComplete: () {},
        ),
      ),
    );

    expect(find.text('Run timer'), findsOneWidget);
    expect(find.text('Start timer'), findsOneWidget);
  });

  testWidgets(
    'Workout tab includes the quick-start editor and updated creation label',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MissionFitApp(skipOnboarding: true));

      await tester.tap(find.text('Workouts').first);
      await tester.pumpAndSettle();

      expect(find.text('Create workout'), findsOneWidget);
      expect(find.text('Edit Quick Start'), findsOneWidget);
    },
  );

  testWidgets('Food tab uses the Food Log card with a circular add action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MissionFitApp(skipOnboarding: true));

    await tester.tap(find.text('Food').first);
    await tester.pumpAndSettle();

    expect(find.text('Food Log'), findsOneWidget);
    expect(find.text('Daily Calories'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      ),
      findsWidgets,
    );
  });

  testWidgets(
    'Workout builder removes completion checkboxes and centers header labels',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutBuilderScreen(onSave: (workoutName, exercises) {}),
        ),
      );

      expect(find.text('Set'), findsNothing);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Reps'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    },
  );

  testWidgets('Quick Start editor supports adding and removing exercises', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MissionFitApp(skipOnboarding: true));

    await tester.tap(find.text('Workouts').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Edit Quick Start'),
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Edit Quick Start'));
    await tester.pumpAndSettle();

    expect(find.text('Selected workout'), findsOneWidget);
    expect(find.text('Add Exercise'), findsWidgets);
  });

  testWidgets('Body map renders a human figure with highlighted regions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MissionFitApp(skipOnboarding: true));

    await tester.tap(find.text('Workouts').first);
    await tester.pumpAndSettle();

    expect(find.byType(CustomPaint), findsWidgets);
  });

  test(
    'imperial values convert to metric before BMR and TDEE calculations',
    () {
      expect(convertToMetricValue(70, 'in'), closeTo(177.8, 0.1));
      expect(convertToMetricValue(165, 'lbs'), closeTo(74.84, 0.1));
    },
  );

  test('Workout set entries support separate W and completed values', () {
    const entry = WorkoutSetEntry(
      weight: '80',
      reps: '8',
      isWon: false,
      isComplete: false,
    );

    expect(entry.isWon, isFalse);
    expect(entry.isComplete, isFalse);

    final toggled = entry.copyWith(isWon: true, isComplete: true);

    expect(toggled.isWon, isTrue);
    expect(toggled.isComplete, isTrue);
  });

  test(
    'saved meal presets support selection state for quick food-log adds',
    () {
      const meal = MealPreset(
        name: 'Post Workout',
        items: [
          FoodEntry(
            name: 'Protein shake',
            calories: 240,
            protein: 28,
            carbs: 12,
            fat: 4,
          ),
        ],
        isSelected: true,
      );

      expect(meal.isSelected, isTrue);
      expect(meal.copyWith(isSelected: false).isSelected, isFalse);
    },
  );
}
