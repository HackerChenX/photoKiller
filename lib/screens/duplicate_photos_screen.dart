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

class DuplicatePhotosScreen extends StatefulWidget {
  const DuplicatePhotosScreen({Key? key}) : super(key: key);

  @override
  State<DuplicatePhotosScreen> createState() => _DuplicatePhotosScreenState();
}

class _DuplicatePhotosScreenState extends State<DuplicatePhotosScreen> {
  bool _selectAllMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadDuplicatePhotos();
  }

  Future<void> _loadDuplicatePhotos() async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    await photoProvider.findDuplicatePhotos();
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
  
  void _toggleSelectAllMode(PhotoProvider photoProvider) {
    setState(() {
      _selectAllMode = !_selectAllMode;
    });
    
    // 如果进入全选模式，则选择所有重复组中的非首张照片
    if (_selectAllMode) {
      for (var group in photoProvider.duplicateGroups) {
        for (int i = 1; i < group.photos.length; i++) {
          photoProvider.updatePhotoSelection(group, group.photos[i].id, true);
        }
      }
    } else {
      // 如果退出全选模式，则取消所有选择
      for (var group in photoProvider.duplicateGroups) {
        photoProvider.selectAllInGroup(group, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.duplicatePhotos),
        elevation: 0,
        actions: [
          Consumer<PhotoProvider>(
            builder: (context, photoProvider, child) {
              return TextButton.icon(
                onPressed: () {
                  _toggleSelectAllMode(photoProvider);
                },
                icon: Icon(
                  _selectAllMode ? Icons.deselect : Icons.select_all,
                  color: AppColors.primary,
                ),
                label: Text(
                  _selectAllMode ? '取消全选' : '全选副本',
                  style: TextStyle(
                    color: AppColors.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          if (photoProvider.isLoading) {
            return LoadingIndicator(message: photoProvider.loadingMessage);
          }

          final duplicateGroups = photoProvider.duplicateGroups;
          
          if (duplicateGroups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.copy,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '没有发现重复照片',
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
                      '共 ${duplicateGroups.length} 组',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: duplicateGroups.length,
                  itemBuilder: (context, index) {
                    return _buildDuplicatePhotoGroup(duplicateGroups[index], photoProvider);
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

  Widget _buildDuplicatePhotoGroup(PhotoGroup group, PhotoProvider photoProvider) {
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
                const Icon(Icons.copy, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '重复照片组 #${group.id + 1}',
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
                // 选中状态
                Text(
                  '已选择：${group.selectedPhotos.length}/${group.photos.length}',
                  style: AppTextStyles.bodySmall,
                ),
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
                final isFirst = index == 0; // 第一张照片（保留）
                
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
                              color: isFirst 
                                ? AppColors.success 
                                : photo.isSelected 
                                  ? AppColors.primary 
                                  : AppColors.border,
                              width: isFirst || photo.isSelected ? 2 : 0.5,
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
                      
                      // 首张标记（保留）
                      if (isFirst)
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
                              Icons.star,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      
                      // 选择框（除首张外）
                      if (!isFirst)
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
                OutlinedButton.icon(
                  onPressed: () {
                    // 选择除第一张外的所有照片
                    for (int i = 1; i < group.photos.length; i++) {
                      photoProvider.updatePhotoSelection(
                        group, 
                        group.photos[i].id, 
                        true,
                      );
                    }
                  },
                  icon: const Icon(Icons.auto_delete),
                  label: const Text('仅保留第一张'),
                  style: OutlinedButton.styleFrom(
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