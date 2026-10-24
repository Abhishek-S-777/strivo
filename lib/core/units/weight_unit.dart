import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/settings/settings_repository.dart';

/// The user's preferred weight unit. All weights are STORED in kilograms;
/// this only affects display and input.
enum WeightUnit { kg, lbs }

const double _lbsPerKg = 2.2046226218;

/// Device-local settings store. Used statically here because [Units] is a
/// synchronous mirror consumed without a [WidgetRef].
const SettingsRepository _settings = SettingsRepositoryImpl();

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
      _settings.getString('weight_unit') == WeightUnit.lbs.name
      ? WeightUnit.lbs
      : WeightUnit.kg;

  static bool get isLbs => unit == WeightUnit.lbs;
  static String get label => isLbs ? 'lbs' : 'kg';

  // ── Stepper increment ──────────────────────────────────────────
  // Stored per-unit (in display units) so each unit keeps a sensible value.
  static double? _incKg = _loadInc('inc_kg');
  static double? _incLbs = _loadInc('inc_lbs');

  static double? _loadInc(String key) {
    final v = _settings.getString(key);
    return v == null ? null : double.tryParse(v);
  }

  /// What the +/- stepper adds in the *display* unit (default 2.5 kg / 5 lbs).
  static double get stepDisplay => isLbs ? (_incLbs ?? 5.0) : (_incKg ?? 2.5);

  /// Stepper micro-increment expressed in kg.
  static double get stepKg => toKg(stepDisplay);

  /// Increment label for the settings row, e.g. "2.5 kg" / "5 lbs".
  static String get incrementLabel => '${_trim(stepDisplay)} $label';

  /// Sensible increment choices for the current unit.
  static List<double> get incrementOptions =>
      isLbs ? const [1.0, 2.5, 5.0, 10.0] : const [0.5, 1.0, 2.5, 5.0];

  static void setIncrementDisplay(double v) {
    if (isLbs) {
      _incLbs = v;
      unawaited(_settings.setString('inc_lbs', v.toString()));
    } else {
      _incKg = v;
      unawaited(_settings.setString('inc_kg', v.toString()));
    }
  }

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
    unawaited(_settings.setString('weight_unit', u.name));
    state = u;
  }
}

/// Drives rebuilds when the +/- stepper increment changes. UI reads the
/// formatted value from [Units] (single source of truth); this just signals.
final weightIncrementProvider =
    StateNotifierProvider<WeightIncrementNotifier, double>((ref) {
      return WeightIncrementNotifier();
    });

class WeightIncrementNotifier extends StateNotifier<double> {
  WeightIncrementNotifier() : super(Units.stepDisplay);

  void setIncrement(double displayValue) {
    Units.setIncrementDisplay(displayValue);
    state = displayValue;
  }
}
