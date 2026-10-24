import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/core/theme/app_spacing.dart';
import 'package:strivo/features/progress_photos/domain/entities/progress_photo.dart';
import 'package:strivo/features/progress_photos/presentation/providers/progress_photos_provider.dart';

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
                    return _PhotoThumbnail(
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
                    child: _PhotoSourceButton(
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
                    child: _PhotoSourceButton(
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
        builder: (ctx) => _PhotoDetailDialog(
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

// ── Photo Thumbnail ──
class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.photo,
    required this.onTap,
    required this.onLongPress,
  });
  final ProgressPhoto photo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photo.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, e, st) => const ColoredBox(
                color: AppColors.surfaceLight,
                child: Icon(
                  LucideIcons.imageOff,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            // Date overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withAlpha(180),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  DateFormat('MMM d').format(photo.date),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Body weight badge
            if (photo.bodyWeight != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${photo.bodyWeight!.toStringAsFixed(1)}kg',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Photo Source Button ──
class _PhotoSourceButton extends StatelessWidget {
  const _PhotoSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Photo Detail Dialog (Full screen viewer with swipe) ──
class _PhotoDetailDialog extends StatefulWidget {
  const _PhotoDetailDialog({
    required this.photos,
    required this.initialIndex,
    required this.onDelete,
  });
  final List<ProgressPhoto> photos;
  final int initialIndex;
  final void Function(String) onDelete;

  @override
  State<_PhotoDetailDialog> createState() => _PhotoDetailDialogState();
}

class _PhotoDetailDialogState extends State<_PhotoDetailDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // Photo viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              return InteractiveViewer(
                child: Center(
                  child: Image.file(
                    File(photo.imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (_, e, st) => const Icon(
                      LucideIcons.imageOff,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              );
            },
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        Text(
                          DateFormat(
                            'MMMM d, yyyy',
                          ).format(widget.photos[_currentIndex].date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (widget.photos[_currentIndex].bodyWeight != null)
                          Text(
                            '${widget.photos[_currentIndex].bodyWeight!.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.trash2,
                        color: AppColors.error,
                        size: 20,
                      ),
                      onPressed: () =>
                          widget.onDelete(widget.photos[_currentIndex].id),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Page indicator
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentIndex + 1} / ${widget.photos.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Note overlay
          if (widget.photos[_currentIndex].note?.isNotEmpty ?? false)
            Positioned(
              bottom: 70,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.photos[_currentIndex].note!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
