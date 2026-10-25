import 'package:flutter_test/flutter_test.dart';
import 'package:strivo/features/workout/domain/personal_record.dart';

void main() {
  group('isPersonalRecord', () {
    test('true when the weight beats the previous max', () {
      expect(
        isPersonalRecord(
          weight: 105,
          volume: 300,
          previousMaxWeight: 100,
          previousMaxVolume: 500,
        ),
        isTrue,
      );
    });

    test('true when the volume beats the previous max', () {
      expect(
        isPersonalRecord(
          weight: 80,
          volume: 900,
          previousMaxWeight: 100,
          previousMaxVolume: 500,
        ),
        isTrue,
      );
    });

    test('false when neither weight nor volume beats the previous best', () {
      expect(
        isPersonalRecord(
          weight: 100,
          volume: 500,
          previousMaxWeight: 100,
          previousMaxVolume: 500,
        ),
        isFalse,
      );
    });

    test('true against a fresh exercise (no prior bests)', () {
      expect(
        isPersonalRecord(
          weight: 20,
          volume: 100,
          previousMaxWeight: 0,
          previousMaxVolume: 0,
        ),
        isTrue,
      );
    });
  });
}
