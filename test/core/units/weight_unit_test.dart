import 'package:flutter_test/flutter_test.dart';
import 'package:strivo/core/units/weight_unit.dart';

/// [Units] is a synchronous static mirror of the user's unit preference. Its
/// backing fields hydrate from Hive on first read, so each test assigns
/// [Units.unit] up front (assignment skips the lazy Hive initializer) and
/// exercises only the pure conversion/formatting helpers.
void main() {
  group('Units in kilograms', () {
    setUp(() => Units.unit = WeightUnit.kg);

    test('reports kg as the active unit', () {
      expect(Units.isLbs, isFalse);
      expect(Units.label, 'kg');
    });

    test('fromKg and toKg are the identity', () {
      expect(Units.fromKg(100), 100);
      expect(Units.toKg(100), 100);
    });

    test('weight trims whole numbers and keeps one decimal otherwise', () {
      expect(Units.weight(102), '102');
      expect(Units.weight(102.5), '102.5');
    });

    test('weightLabel appends the unit', () {
      expect(Units.weightLabel(60), '60 kg');
    });

    test('volumeValue switches to k and M suffixes at the thresholds', () {
      expect(Units.volumeValue(500), '500');
      expect(Units.volumeValue(9999), '9999');
      expect(Units.volumeValue(10000), '10.0k');
      expect(Units.volumeValue(12345), '12.3k');
      expect(Units.volumeValue(1000000), '1.00M');
      expect(Units.volumeValue(2500000), '2.50M');
    });

    test('volumeLabel appends the unit', () {
      expect(Units.volumeLabel(12345), '12.3k kg');
    });
  });

  group('Units in pounds', () {
    setUp(() => Units.unit = WeightUnit.lbs);

    test('reports lbs as the active unit', () {
      expect(Units.isLbs, isTrue);
      expect(Units.label, 'lbs');
    });

    test('fromKg converts kilograms to pounds', () {
      expect(Units.fromKg(100), closeTo(220.462, 0.001));
    });

    test('toKg converts pounds back to kilograms', () {
      expect(Units.toKg(220.462), closeTo(100, 0.001));
    });

    test('fromKg and toKg round-trip', () {
      expect(Units.toKg(Units.fromKg(80)), closeTo(80, 1e-9));
    });

    test('weight formats the converted value', () {
      expect(Units.weight(100), '220.5');
      expect(Units.weightLabel(100), '220.5 lbs');
    });

    test('volumeValue converts before applying the k suffix', () {
      expect(Units.volumeValue(10000), '22.0k');
    });
  });
}
