class Validators {
  Validators._();

  static bool isNotBlank(String? value) => value != null && value.trim().isNotEmpty;

  static bool withinMaxLength(String value, int max) => value.trim().length <= max;

  static bool isNonNegative(num value) => value >= 0;

  static bool isPositive(num value) => value > 0;
}
