/// Whether a completed set is a personal record against the lifter's prior
/// bests for that exercise: a heavier top weight OR a higher single-set volume
/// than anything recorded before.
///
/// Pure function shared by the active-workout PR check and analytics.
bool isPersonalRecord({
  required double weight,
  required double volume,
  required double previousMaxWeight,
  required double previousMaxVolume,
}) {
  return weight > previousMaxWeight || volume > previousMaxVolume;
}
