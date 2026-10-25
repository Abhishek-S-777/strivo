import 'package:flutter_test/flutter_test.dart';
import 'package:strivo/features/analytics/domain/one_rep_max.dart';

void main() {
  group('estimatedOneRepMax (Epley)', () {
    test('returns the weight unchanged for a single rep', () {
      expect(estimatedOneRepMax(100, 1), closeTo(103.33, 0.01));
    });

    test('returns the weight unchanged for zero or negative reps', () {
      expect(estimatedOneRepMax(100, 0), 100);
      expect(estimatedOneRepMax(100, -3), 100);
    });

    test('applies weight x (1 + reps / 30)', () {
      // 100 * (1 + 10/30) = 133.33...
      expect(estimatedOneRepMax(100, 10), closeTo(133.33, 0.01));
      // 60 * (1 + 5/30) = 70
      expect(estimatedOneRepMax(60, 5), closeTo(70, 0.0001));
    });
  });
}
