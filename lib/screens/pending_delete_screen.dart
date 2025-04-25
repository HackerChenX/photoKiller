import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../constants/text_styles.dart';
import '../models/photo.dart';
import '../providers/photo_provider.dart';
import '../widgets/loading_indicator.dart';
import 'cleanup_result_screen.dart';

class PendingDeleteScreen extends StatefulWidget {
  const PendingDeleteScreen({Key? key}) : super(key: key);

  @override
  State<PendingDeleteScreen> createState() => _PendingDeleteScreenState();
}

class _PendingDeleteScreenState extends State<PendingDeleteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('待删除照片'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              _confirmRemoveAll();
            },
            child: const Text(
              '清空',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          if (photoProvider.isLoading) {
            return LoadingIndicator(message: photoProvider.loadingMessage);
          }
          
          final pendingPhotos = photoProvider.pendingDeletePhotos;
          
          if (pendingPhotos.isEmpty) {
            return const Center(
              child: Text('暂无待删除照片'),
            );
          }
          
          return Column(
            children: [
              // 统计信息
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      '共 ${pendingPhotos.length} 张照片',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      '可释放: ${_calculateTotalSize(pendingPhotos)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 照片列表
              Expanded(
                child: ListView.builder(
                  itemCount: pendingPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = pendingPhotos[index];
                    return _buildPhotoItem(photo, photoProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          final pendingPhotos = photoProvider.pendingDeletePhotos;
          
          if (pendingPhotos.isEmpty) {
            return const SizedBox.shrink();
          }
          
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    '${pendingPhotos.length}张照片待删除',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: pendingPhotos.isNotEmpty ? _confirmDelete : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                    child: const Text('删除并释放空间'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildPhotoItem(Photo photo, PhotoProvider photoProvider) {
    return Dismissible(
      key: Key(photo.id),
      background: Container(
        color: AppColors.success,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(
          Icons.restore_from_trash,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        photoProvider.removeFromPendingDelete(photo);
      },
      child: ListTile(
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(photo.path),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          photo.fileName ?? '未知照片',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${photo.formattedDate} · ${photo.formattedSize}',
          style: AppTextStyles.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            photoProvider.removeFromPendingDelete(photo);
          },
        ),
      ),
    );
  }
  
  String _calculateTotalSize(List<Photo> photos) {
    final totalBytes = photos.fold<int>(0, (sum, photo) => sum + photo.size);
    
    if (totalBytes < 1024) {
      return '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  void _confirmRemoveAll() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空待删除列表吗？'),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('清空'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
        photoProvider.clearPendingDelete();
        Navigator.pop(context);
      }
    });
  }
  
  void _confirmDelete() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除所有待删除照片吗？此操作无法撤销。'),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('删除'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
        final result = await photoProvider.deletePendingPhotos();
        
        if (!mounted) return;
        
        // 显示结果页面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CleanupResultScreen(result: result),
          ),
        );
      }
    });
  }
} 