import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/services/hive_service.dart';

/// The user's preferred weight unit. All weights are STORED in kilograms;
/// this only affects display and input.
enum WeightUnit { kg, lbs }

const double _lbsPerKg = 2.2046226218;

/// Synchronously-readable active unit + formatting helpers.
///
/// Weights live in kg everywhere in the data model. [Units] is the single
/// place that converts kg → the user's display unit and formats it, so plain
/// widgets and providers can format without plumbing a [WidgetRef] through.
/// Screens still `ref.watch(weightUnitProvider)` so they rebuild when the
/// unit changes (the static mirror is kept in sync by the notifier).
class Units {
  Units._();

  static WeightUnit unit = _loadInitial();

  static WeightUnit _loadInitial() =>
      HiveService.getSetting('weight_unit') == WeightUnit.lbs.name
          ? WeightUnit.lbs
          : WeightUnit.kg;

  static bool get isLbs => unit == WeightUnit.lbs;
  static String get label => isLbs ? 'lbs' : 'kg';

  /// Stepper micro-increment, expressed in kg (2.5 kg, or 5 lbs in lbs mode).
  static double get stepKg => isLbs ? 5 / _lbsPerKg : 2.5;

  /// What the +/- stepper adds in the *display* unit (for labels like "±5 lbs").
  static double get stepDisplay => isLbs ? 5 : 2.5;

  static double fromKg(double kg) => isLbs ? kg * _lbsPerKg : kg;
  static double toKg(double display) => isLbs ? display / _lbsPerKg : display;

  static String _trim(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  /// Display-unit weight number only, e.g. "102" / "225".
  static String weight(double kg) => _trim(fromKg(kg));

  /// Weight with unit, e.g. "102 kg" / "225 lbs".
  static String weightLabel(double kg) => '${weight(kg)} $label';

  /// Volume number only (display unit) with k/M suffix, e.g. "12.3k".
  static String volumeValue(double kgVolume) {
    final v = fromKg(kgVolume);
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 10000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  /// Volume with k/M and unit, e.g. "12.3k kg" / "27.1k lbs".
  static String volumeLabel(double kgVolume) =>
      '${volumeValue(kgVolume)} $label';
}

final weightUnitProvider =
    StateNotifierProvider<WeightUnitNotifier, WeightUnit>((ref) {
  return WeightUnitNotifier();
});

class WeightUnitNotifier extends StateNotifier<WeightUnit> {
  WeightUnitNotifier() : super(Units.unit);

  void setUnit(WeightUnit u) {
    Units.unit = u;
    HiveService.saveSetting('weight_unit', u.name);
    state = u;
  }
}
