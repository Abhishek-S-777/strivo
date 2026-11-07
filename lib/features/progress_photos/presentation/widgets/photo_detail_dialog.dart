import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:strivo/core/theme/app_colors.dart';
import 'package:strivo/features/progress_photos/domain/entities/progress_photo.dart';

/// Full-screen, swipeable progress-photo viewer with date/weight header, a
/// delete action, a page indicator, and an optional note overlay.
class PhotoDetailDialog extends StatefulWidget {
  const PhotoDetailDialog({
    required this.photos,
    required this.initialIndex,
    required this.onDelete,
    super.key,
  });
  final List<ProgressPhoto> photos;
  final int initialIndex;
  final void Function(String) onDelete;

  @override
  State<PhotoDetailDialog> createState() => _PhotoDetailDialogState();
}

class _PhotoDetailDialogState extends State<PhotoDetailDialog> {
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
