part of '../main.dart';

class FoodTabLogic {
  static double totalCalories(List<FoodEntry> entries) =>
      entries.fold<double>(0, (sum, item) => sum + item.calories);

  static double totalProtein(List<FoodEntry> entries) =>
      entries.fold<double>(0, (sum, item) => sum + item.protein);

  static double totalCarbs(List<FoodEntry> entries) =>
      entries.fold<double>(0, (sum, item) => sum + item.carbs);

  static double totalFat(List<FoodEntry> entries) =>
      entries.fold<double>(0, (sum, item) => sum + item.fat);

  static double calorieProgress({
    required List<FoodEntry> entries,
    required double calorieGoal,
  }) {
    if (calorieGoal <= 0) return 0;
    return (totalCalories(entries) / calorieGoal).clamp(0.0, 1.0);
  }
}
