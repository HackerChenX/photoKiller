import 'package:flutter/material.dart';
import '../models/photo.dart';
import '../constants/strings.dart';
import 'photo_grid_item.dart';

class PhotoGrid extends StatelessWidget {
  final List<Photo> photos;
  final Function(Photo)? onPhotoTap;
  final Function(Photo, bool)? onPhotoSelectChanged;
  final int crossAxisCount;
  final double spacing;
  
  const PhotoGrid({
    Key? key,
    required this.photos,
    this.onPhotoTap,
    this.onPhotoSelectChanged,
    this.crossAxisCount = 3,
    this.spacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noPhotos,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: EdgeInsets.all(spacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.0,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return PhotoGridItem(
          photo: photo,
          isSelected: photo.isSelected,
          isRecommended: photo.isRecommended,
          onTap: () => onPhotoTap?.call(photo),
          onSelectChanged: onPhotoSelectChanged != null
              ? (selected) => onPhotoSelectChanged!(photo, selected)
              : null,
        );
      },
    );
  }
} 