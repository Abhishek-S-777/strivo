import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strivo/core/services/firestore_sync_service.dart';

/// Account-level cloud sync operations used around sign-in / sign-up and the
/// manual "back up now" action. Presentation depends on this interface; the
/// Firestore implementation lives behind it.
abstract interface class CloudSyncRepository {
  /// Pull all cloud data into local storage. Returns the merged counts.
  Future<({int sessions, int routines})> restoreFromCloud();

  /// Push all local data up to the cloud.
  Future<void> pushAllLocal();

  /// Create or update the user's profile document.
  Future<void> saveUserProfile({String? displayName, String? email});
}

/// [CloudSyncRepository] backed by [FirestoreSyncService].
class CloudSyncRepositoryImpl implements CloudSyncRepository {
  const CloudSyncRepositoryImpl(this._sync);

  final FirestoreSyncService _sync;

  @override
  Future<({int sessions, int routines})> restoreFromCloud() =>
      _sync.restoreFromCloud();

  @override
  Future<void> pushAllLocal() => _sync.pushAllLocal();

  @override
  Future<void> saveUserProfile({String? displayName, String? email}) =>
      _sync.saveUserProfile(displayName: displayName, email: email);
}

/// Supplies the app-wide [CloudSyncRepository] implementation.
final cloudSyncRepositoryProvider = Provider<CloudSyncRepository>((ref) {
  return CloudSyncRepositoryImpl(ref.watch(firestoreSyncProvider));
});
