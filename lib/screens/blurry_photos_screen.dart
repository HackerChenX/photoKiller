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

class BlurryPhotosScreen extends StatefulWidget {
  const BlurryPhotosScreen({Key? key}) : super(key: key);

  @override
  State<BlurryPhotosScreen> createState() => _BlurryPhotosScreenState();
}

class _BlurryPhotosScreenState extends State<BlurryPhotosScreen> {
  bool _selectionMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadBlurryPhotos();
  }
  
  Future<void> _loadBlurryPhotos() async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    await photoProvider.loadBlurryPhotos();
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
        title: const Text('模糊照片'),
        actions: [
          if (!_selectionMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
              tooltip: AppStrings.select,
            )
          else
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _toggleSelectionMode,
              tooltip: AppStrings.cancel,
            ),
        ],
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          if (photoProvider.isLoading) {
            return LoadingIndicator(message: photoProvider.loadingMessage);
          }
          
          final blurryPhotos = photoProvider.blurryPhotos;
          
          if (blurryPhotos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lens_blur,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '没有模糊照片',
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '您的照片都很清晰',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              // 标题栏
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '共 ${blurryPhotos.length} 项',
                      style: AppTextStyles.bodyMedium,
                    ),
                    Row(
                      children: [
                        const Text('按模糊度'),
                        const SizedBox(width: 8),
                        const Icon(Icons.sort, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 照片网格
              Expanded(
                child: PhotoGrid(
                  photos: blurryPhotos,
                  crossAxisCount: 3,
                  onPhotoTap: _selectionMode
                    ? null
                    : (photo) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhotoDetailScreen(
                              photo: photo,
                              extraInfo: '模糊度: ${(photo.blurScore ?? 0).toStringAsFixed(1)}',
                            ),
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
                final selectedCount = photoProvider.selectedCount;
                
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
                        TextButton.icon(
                          onPressed: () {
                            photoProvider.toggleSelectAllBlurryPhotos();
                          },
                          icon: Icon(
                            photoProvider.isAllBlurrySelected
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            photoProvider.isAllBlurrySelected
                                ? '取消全选'
                                : '全选',
                            style: TextStyle(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: selectedCount > 0 ? _deleteSelectedPhotos : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.delete),
                          label: Text('删除 ($selectedCount)'),
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