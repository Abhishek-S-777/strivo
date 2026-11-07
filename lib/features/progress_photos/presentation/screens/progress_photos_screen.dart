import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/features/progress_photos/domain/entities/progress_photo.dart';
import 'package:strivo/features/progress_photos/presentation/providers/progress_photos_provider.dart';
import 'package:strivo/features/progress_photos/presentation/widgets/photo_detail_dialog.dart';
import 'package:strivo/features/progress_photos/presentation/widgets/photo_source_button.dart';
import 'package:strivo/features/progress_photos/presentation/widgets/photo_thumbnail.dart';

class ProgressPhotosScreen extends ConsumerWidget {
  const ProgressPhotosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(progressPhotosProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddPhotoSheet(context, ref),
                      icon: const Icon(LucideIcons.camera, size: 18),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (photos.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.camera,
                        size: 56,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No progress photos',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track your transformation over time',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddPhotoSheet(context, ref),
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('Add Photo'),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildTimeline(context, ref, photos),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    WidgetRef ref,
    List<ProgressPhoto> photos,
  ) {
    // Group photos by month
    final grouped = <String, List<ProgressPhoto>>{};
    for (final photo in photos) {
      final key = DateFormat('MMMM yyyy').format(photo.date);
      grouped.putIfAbsent(key, () => []).add(photo);
    }

    final months = grouped.keys.toList();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final monthKey = months[index];
            final monthPhotos = grouped[monthKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month header
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        monthKey,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${monthPhotos.length} photo${monthPhotos.length > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Photo grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: monthPhotos.length,
                  itemBuilder: (context, photoIndex) {
                    final photo = monthPhotos[photoIndex];
                    return PhotoThumbnail(
                      photo: photo,
                      onTap: () =>
                          _showPhotoDetail(context, ref, photo, photos),
                      onLongPress: () => _showPhotoOptions(context, ref, photo),
                    );
                  },
                ),

                if (index < months.length - 1) const SizedBox(height: 12),
              ],
            );
          },
          childCount: months.length,
        ),
      ),
    );
  }

  void _showAddPhotoSheet(BuildContext context, WidgetRef ref) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Progress Photo',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: PhotoSourceButton(
                      icon: LucideIcons.camera,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(ctx);
                        unawaited(
                          ref
                              .read(progressPhotosProvider.notifier)
                              .addPhoto(source: ImageSource.camera),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PhotoSourceButton(
                      icon: LucideIcons.image,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(ctx);
                        unawaited(
                          ref.read(progressPhotosProvider.notifier).addPhoto(),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotoDetail(
    BuildContext context,
    WidgetRef ref,
    ProgressPhoto photo,
    List<ProgressPhoto> allPhotos,
  ) {
    final index = allPhotos.indexOf(photo);

    unawaited(
      showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (ctx) => PhotoDetailDialog(
          photos: allPhotos,
          initialIndex: index,
          onDelete: (id) {
            unawaited(
              ref.read(progressPhotosProvider.notifier).deletePhoto(id),
            );
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  void _showPhotoOptions(
    BuildContext context,
    WidgetRef ref,
    ProgressPhoto photo,
  ) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: AppColors.error),
                title: const Text(
                  'Delete Photo',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(
                    ref
                        .read(progressPhotosProvider.notifier)
                        .deletePhoto(photo.id),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
