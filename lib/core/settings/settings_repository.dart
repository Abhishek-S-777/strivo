import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/services/hive_service.dart';

/// Key-value store for small device-local user settings (rest timer default,
/// unit preferences, and similar). Backed by Hive; never synced to the cloud.
abstract interface class SettingsRepository {
  /// The stored value for [key], or null if unset.
  String? getString(String key);

  /// Persist [value] under [key].
  Future<void> setString(String key, String value);
}

/// [SettingsRepository] backed by the Hive settings box via [HiveService].
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl();

  @override
  String? getString(String key) => HiveService.getSetting(key);

  @override
  Future<void> setString(String key, String value) =>
      HiveService.saveSetting(key, value);
}

/// Supplies the app-wide [SettingsRepository] implementation.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return const SettingsRepositoryImpl();
});
