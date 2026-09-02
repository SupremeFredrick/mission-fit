part of '../main.dart';

class HomeTabLogic {
  static String monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  static int workoutStreakCount(List<DateTime> completedWorkoutDates) {
    if (completedWorkoutDates.isEmpty) return 0;

    final normalized =
        completedWorkoutDates
            .map((date) => DateTime(date.year, date.month, date.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    var streak = 0;
    var cursor = DateTime.now();
    while (normalized.contains(
      DateTime(cursor.year, cursor.month, cursor.day),
    )) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static List<bool> weekActivity(
    DateTime today,
    List<DateTime> completedWorkoutDates,
  ) {
    return List<bool>.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final normalized = DateTime(date.year, date.month, date.day);
      return completedWorkoutDates.any(
        (entry) => DateTime(
          entry.year,
          entry.month,
          entry.day,
        ).isAtSameMomentAs(normalized),
      );
    });
  }

  static Map<String, bool> bodyMapStatus(List<WorkoutExercise> exercises) {
    final map = {
      'Chest': false,
      'Back': false,
      'Legs': false,
      'Core': false,
      'Shoulders': false,
    };

    for (final exercise in exercises) {
      if (exercise.setEntries.isEmpty ||
          !exercise.setEntries.every((set) => set.isComplete)) {
        continue;
      }
      final name = exercise.name.toLowerCase();
      if (name.contains('bench') ||
          name.contains('press') ||
          name.contains('fly') ||
          name.contains('chest')) {
        map['Chest'] = true;
      }
      if (name.contains('row') ||
          name.contains('pull') ||
          name.contains('back')) {
        map['Back'] = true;
      }
      if (name.contains('squat') ||
          name.contains('lunge') ||
          name.contains('leg') ||
          name.contains('deadlift') ||
          name.contains('run') ||
          name.contains('treadmill')) {
        map['Legs'] = true;
      }
      if (name.contains('core') ||
          name.contains('plank') ||
          name.contains('crunch') ||
          name.contains('abs')) {
        map['Core'] = true;
      }
      if (name.contains('shoulder') || name.contains('raise')) {
        map['Shoulders'] = true;
      }
    }

    return map;
  }
}
