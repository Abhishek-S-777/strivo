/// Estimated one-rep max via the Epley formula: `weight × (1 + reps / 30)`.
///
/// For a single rep (or non-positive reps) the lifted weight is returned
/// unchanged. Pure and unit-agnostic — [weight] in, same unit out.
double estimatedOneRepMax(double weight, int reps) {
  if (reps <= 0) return weight;
  return weight * (1 + reps / 30);
}
