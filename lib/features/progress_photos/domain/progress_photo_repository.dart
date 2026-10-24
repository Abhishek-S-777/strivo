import 'package:strivo/features/progress_photos/domain/entities/progress_photo.dart';

/// Persistence boundary for [ProgressPhoto] metadata.
///
/// Presentation depends on this interface only; the Hive implementation lives
/// in the data layer. Photos are device-local (the image files live on disk and
/// their metadata in Hive); they are not synced to the cloud.
abstract interface class ProgressPhotoRepository {
  /// All stored photos, most recent first.
  Future<List<ProgressPhoto>> loadAll();

  /// Insert or update [photo].
  Future<void> save(ProgressPhoto photo);

  /// Remove the photo metadata with [id].
  Future<void> delete(String id);
}
