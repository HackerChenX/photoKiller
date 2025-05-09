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
  // 添加时间筛选
  String _timeFilter = 'all'; // 'all', '15days', '30days', '180days'
  
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
  
  void _setTimeFilter(String filter) {
    setState(() {
      _timeFilter = filter;
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
  
  // 根据时间筛选照片
  List<Photo> _filterPhotosByTime(List<Photo> photos) {
    final now = DateTime.now();
    
    switch (_timeFilter) {
      case '15days':
        final cutoffDate = now.subtract(const Duration(days: 15));
        return photos.where((photo) => photo.createTime.isBefore(cutoffDate)).toList();
      case '30days':
        final cutoffDate = now.subtract(const Duration(days: 30));
        return photos.where((photo) => photo.createTime.isBefore(cutoffDate)).toList();
      case '180days':
        final cutoffDate = now.subtract(const Duration(days: 180));
        return photos.where((photo) => photo.createTime.isBefore(cutoffDate)).toList();
      case 'all':
      default:
        return photos;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.screenshots),
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
          
          // 应用时间筛选
          final filteredScreenshots = _filterPhotosByTime(photoProvider.screenshots);
          
          return Column(
            children: [
              // 筛选条件部分
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '共 ${filteredScreenshots.length} 项',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 添加时间筛选选项卡
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('全部', 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip('15天以上', '15days'),
                          const SizedBox(width: 8),
                          _buildFilterChip('30天以上', '30days'),
                          const SizedBox(width: 8),
                          _buildFilterChip('180天以上', '180days'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 照片网格
              Expanded(
                child: PhotoGrid(
                  photos: filteredScreenshots,
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
                            photoProvider.toggleSelectAll();
                          },
                          icon: Icon(
                            photoProvider.isAllSelected
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            photoProvider.isAllSelected
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
  
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _timeFilter == value;
    
    return GestureDetector(
      onTap: () => _setTimeFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
} 