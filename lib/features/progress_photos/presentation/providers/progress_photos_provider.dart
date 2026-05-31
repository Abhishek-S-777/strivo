import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:strivo/core/utils/id_generator.dart';
import 'package:strivo/features/progress_photos/domain/entities/progress_photo.dart';

const String _boxName = 'progress_photos';

final progressPhotosProvider =
    StateNotifierProvider<ProgressPhotosNotifier, List<ProgressPhoto>>((ref) {
  return ProgressPhotosNotifier();
});

class ProgressPhotosNotifier extends StateNotifier<List<ProgressPhoto>> {
  late Box<String> _box;
  final ImagePicker _picker = ImagePicker();

  ProgressPhotosNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<String>(_boxName);
    _loadPhotos();
  }

  void _loadPhotos() {
    state = _box.values
        .map((json) =>
            ProgressPhoto.fromMap(jsonDecode(json) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<ProgressPhoto?> addPhoto({
    String? note,
    double? bodyWeight,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Save to app's document directory
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'strivo_photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final id = IdGenerator.generate();
      final ext = p.extension(image.path);
      final filename = 'photo_$id$ext';
      final savedPath = p.join(photosDir.path, filename);

      await File(image.path).copy(savedPath);

      final photo = ProgressPhoto(
        id: id,
        imagePath: savedPath,
        date: DateTime.now(),
        note: note,
        bodyWeight: bodyWeight,
      );

      await _box.put(photo.id, jsonEncode(photo.toMap()));
      _loadPhotos();
      return photo;
    } catch (e) {
      return null;
    }
  }

  Future<void> deletePhoto(String id) async {
    final photo = state.firstWhere((p) => p.id == id);
    // Delete the file
    try {
      final file = File(photo.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    await _box.delete(id);
    _loadPhotos();
  }

  Future<void> updatePhotoNote(String id, String note) async {
    final photo = state.firstWhere((p) => p.id == id);
    final updated = photo.copyWith(note: note);
    await _box.put(id, jsonEncode(updated.toMap()));
    _loadPhotos();
  }

  List<ProgressPhoto> getPhotosByMonth(int year, int month) {
    return state
        .where((p) => p.date.year == year && p.date.month == month)
        .toList();
  }
}
