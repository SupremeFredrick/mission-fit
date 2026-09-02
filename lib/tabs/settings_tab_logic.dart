part of '../main.dart';

class SettingsTabLogic {
  static double parseNumericValue(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  static double convertToMetric(double value, String unit) =>
      convertToMetricValue(value, unit);
}
