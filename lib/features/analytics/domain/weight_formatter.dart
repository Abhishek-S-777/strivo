/// Formats kilogram-stored weights into the user's display unit for insight
/// copy. Implemented in the presentation layer (over `Units`) and injected into
/// rules so the domain stays free of UI/formatting dependencies and testable.
abstract interface class WeightFormatter {
  /// The active unit's short label, e.g. `kg` or `lbs`.
  String get unitLabel;

  /// Convert a kilogram value to the display unit (no formatting).
  double fromKg(double kg);

  /// Display-unit weight number only, e.g. `102`.
  String weight(double kg);

  /// Display-unit weight with its unit, e.g. `102 kg`.
  String weightLabel(double kg);
}
