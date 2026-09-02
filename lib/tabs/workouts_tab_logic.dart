part of '../main.dart';

class WorkoutsTabLogic {
  static String dateString() {
    final now = DateTime.now();
    final weekday = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][now.weekday - 1];
    return '$weekday, ${now.day} ${HomeTabLogic.monthName(now.month)} ${now.year}';
  }

  static Map<String, bool> bodyMapStatus(List<WorkoutExercise> exercises) {
    return HomeTabLogic.bodyMapStatus(exercises);
  }
}
