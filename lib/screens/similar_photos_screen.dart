import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../constants/text_styles.dart';
import '../models/photo.dart';
import '../models/photo_group.dart';
import '../providers/photo_provider.dart';
import '../widgets/loading_indicator.dart';
import 'photo_detail_screen.dart';
import 'cleanup_result_screen.dart';

class SimilarPhotosScreen extends StatefulWidget {
  const SimilarPhotosScreen({Key? key}) : super(key: key);

  @override
  State<SimilarPhotosScreen> createState() => _SimilarPhotosScreenState();
}

class _SimilarPhotosScreenState extends State<SimilarPhotosScreen> {
  @override
  void initState() {
    super.initState();
    _loadSimilarPhotos();
  }

  Future<void> _loadSimilarPhotos() async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    await photoProvider.findSimilarPhotos();
  }

  Future<void> _deleteSelectedPhotos() async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final result = await photoProvider.deleteSelectedPhotos();
    
    if (!mounted) return;
    
    // 显示结果页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CleanupResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.similarPhotos),
        elevation: 0,
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          if (photoProvider.isLoading) {
            return LoadingIndicator(message: photoProvider.loadingMessage);
          }

          final similarGroups = photoProvider.similarGroups;
          
          if (similarGroups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.compare,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '没有发现相似照片',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '共 ${similarGroups.length} 组',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: similarGroups.length,
                  itemBuilder: (context, index) {
                    return _buildSimilarPhotoGroup(similarGroups[index], photoProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          final selectedCount = photoProvider.selectedPhotos.length;
          
          if (selectedCount == 0) {
            return const SizedBox.shrink();
          }
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Text(
                    '已选择 $selectedCount 项',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: selectedCount > 0 ? _deleteSelectedPhotos : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      disabledBackgroundColor: AppColors.disabledButton,
                    ),
                    child: Text(AppStrings.delete),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSimilarPhotoGroup(PhotoGroup group, PhotoProvider photoProvider) {
    final recommendedPhoto = group.recommendedPhoto;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 组标题
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.compare, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '相似照片组 #${group.id + 1}',
                  style: AppTextStyles.headline3,
                ),
                const Spacer(),
                Text(
                  '${group.photos.length} 张',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          
          // 组统计信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(
                  Icons.photo_size_select_actual,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  group.formattedTotalSize,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(width: 16),
                if (recommendedPhoto != null) ...[
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '已推荐最佳照片',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 照片网格
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: group.photos.length,
              itemBuilder: (context, index) {
                final photo = group.photos[index];
                final isRecommended = recommendedPhoto != null && 
                                    photo.id == recommendedPhoto.id;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      // 照片
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoDetailScreen(photo: photo),
                            ),
                          );
                        },
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isRecommended 
                                ? AppColors.success 
                                : photo.isSelected 
                                  ? AppColors.primary 
                                  : AppColors.border,
                              width: isRecommended || photo.isSelected ? 2 : 0.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: photo.thumbnailPath != null
                              ? Image.file(
                                  File(photo.thumbnailPath!),
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
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
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            photoProvider.updatePhotoSelection(
                              group, 
                              photo.id, 
                              !photo.isSelected,
                            );
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: photo.isSelected ? AppColors.primary : Colors.white,
                              border: Border.all(
                                color: photo.isSelected 
                                  ? AppColors.primary 
                                  : AppColors.border,
                                width: 1.5,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: photo.isSelected
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
              },
            ),
          ),
          
          // 底部操作按钮
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 全选按钮
                OutlinedButton.icon(
                  onPressed: () {
                    photoProvider.selectAllInGroup(group, true);
                  },
                  icon: const Icon(Icons.select_all),
                  label: const Text('全选'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // 只保留推荐按钮
                if (recommendedPhoto != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      // 选择除推荐照片外的所有照片
                      for (var photo in group.photos) {
                        if (photo.id != recommendedPhoto.id) {
                          photoProvider.updatePhotoSelection(group, photo.id, true);
                        }
                      }
                    },
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('只保留推荐'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 