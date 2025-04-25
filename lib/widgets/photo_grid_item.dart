import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/photo.dart';

class PhotoGridItem extends StatelessWidget {
  final Photo photo;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback? onTap;
  final Function(bool)? onSelectChanged;
  
  const PhotoGridItem({
    Key? key,
    required this.photo,
    this.isSelected = false,
    this.isRecommended = false,
    this.onTap,
    this.onSelectChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // 照片
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected 
                  ? AppColors.primary 
                  : isRecommended 
                    ? AppColors.success 
                    : AppColors.border,
                width: isSelected || isRecommended ? 2 : 0.5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: photo.thumbnailPath != null
                ? Image.file(
                    File(photo.thumbnailPath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Container(
                    color: AppColors.background,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppColors.textSecondary,
                    ),
                  ),
            ),
          ),
          
          // 视频时长标记
          if (photo.type == PhotoType.video && photo.durationInSeconds != null)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  photo.formattedDuration!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          
          // 文件大小标记
          if (photo.size > 0)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  photo.formattedSize,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          
          // 推荐标记
          if (isRecommended)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          
          // 选择框
          if (onSelectChanged != null)
            Positioned(
              bottom: 4,
              left: 4,
              child: GestureDetector(
                onTap: () => onSelectChanged?.call(!isSelected),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1.5,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 