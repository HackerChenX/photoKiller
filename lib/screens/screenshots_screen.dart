import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../constants/text_styles.dart';
import '../models/photo.dart';
import '../providers/photo_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/photo_grid.dart';
import 'photo_detail_screen.dart';
import 'cleanup_result_screen.dart';

class ScreenshotsScreen extends StatefulWidget {
  const ScreenshotsScreen({Key? key}) : super(key: key);

  @override
  State<ScreenshotsScreen> createState() => _ScreenshotsScreenState();
}

class _ScreenshotsScreenState extends State<ScreenshotsScreen> {
  bool _selectionMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadScreenshots();
  }
  
  Future<void> _loadScreenshots() async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    await photoProvider.loadScreenshots();
  }
  
  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
    });
  }
  
  Future<void> _deleteSelectedPhotos() async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final result = await photoProvider.deleteSelectedPhotos();
    
    if (!mounted) return;
    
    // 切换回非选择模式
    setState(() {
      _selectionMode = false;
    });
    
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
        title: Text(AppStrings.screenshots),
        elevation: 0,
        leading: _selectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            )
          : null,
        actions: [
          if (!_selectionMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
            ),
        ],
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          if (photoProvider.isLoading) {
            return LoadingIndicator(message: photoProvider.loadingMessage);
          }
          
          final screenshots = photoProvider.screenshots;
          
          return Column(
            children: [
              // 筛选条件部分
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '共 ${screenshots.length} 项',
                      style: AppTextStyles.bodyMedium,
                    ),
                    // 这里可以添加筛选按钮
                  ],
                ),
              ),
              
              // 照片网格
              Expanded(
                child: PhotoGrid(
                  photos: screenshots,
                  onPhotoTap: _selectionMode
                    ? null
                    : (photo) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhotoDetailScreen(photo: photo),
                          ),
                        );
                      },
                  onPhotoSelectChanged: _selectionMode
                    ? (photo, isSelected) {
                        photoProvider.togglePhotoSelection(photo, isSelected);
                      }
                    : null,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _selectionMode
        ? Consumer<PhotoProvider>(
            builder: (context, photoProvider, child) {
              final selectedCount = photoProvider.selectedPhotos.length;
              
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
          )
        : null,
    );
  }
} 