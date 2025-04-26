import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../constants/text_styles.dart';
import '../models/album.dart';
import '../providers/photo_provider.dart';
import '../widgets/loading_indicator.dart';
import 'cleanup_result_screen.dart';

class EmptyAlbumsScreen extends StatefulWidget {
  const EmptyAlbumsScreen({Key? key}) : super(key: key);

  @override
  State<EmptyAlbumsScreen> createState() => _EmptyAlbumsScreenState();
}

class _EmptyAlbumsScreenState extends State<EmptyAlbumsScreen> {
  bool _selectionMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadEmptyAlbums();
  }
  
  Future<void> _loadEmptyAlbums() async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    await photoProvider.loadEmptyAlbums();
  }
  
  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
    });
  }
  
  Future<void> _deleteSelectedAlbums() async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final result = await photoProvider.deleteSelectedAlbums();
    
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
        title: const Text(AppStrings.emptyAlbums),
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
          
          final emptyAlbums = photoProvider.emptyAlbums;
          
          if (emptyAlbums.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.folder_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '没有空相册',
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '您的相册都包含照片',
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
                      '共 ${emptyAlbums.length} 个空相册',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              
              // 空相册列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: emptyAlbums.length,
                  itemBuilder: (context, index) {
                    final album = emptyAlbums[index];
                    return _buildAlbumItem(album, photoProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _selectionMode
          ? Consumer<PhotoProvider>(
              builder: (context, photoProvider, child) {
                final selectedCount = photoProvider.selectedAlbumCount;
                
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
                            photoProvider.toggleSelectAllAlbums();
                          },
                          icon: Icon(
                            photoProvider.isAllAlbumsSelected
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            photoProvider.isAllAlbumsSelected
                                ? '取消全选'
                                : '全选',
                            style: TextStyle(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: selectedCount > 0 ? _deleteSelectedAlbums : null,
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
  
  Widget _buildAlbumItem(Album album, PhotoProvider photoProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: const Icon(
            Icons.folder_open,
            color: Colors.grey,
            size: 30,
          ),
        ),
        title: Text(
          album.name,
          style: AppTextStyles.bodyLarge,
        ),
        subtitle: Text(
          '创建于: ${album.formattedCreateDate}',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.grey,
          ),
        ),
        trailing: _selectionMode
            ? Checkbox(
                value: album.isSelected,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  photoProvider.toggleAlbumSelection(album, value ?? false);
                },
              )
            : IconButton(
                icon: const Icon(Icons.delete),
                color: AppColors.danger,
                onPressed: () {
                  _confirmDeleteAlbum(album);
                },
              ),
      ),
    );
  }
  
  void _confirmDeleteAlbum(Album album) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除空相册'),
        content: Text('确定要删除"${album.name}"相册吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAlbum(album);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteAlbum(Album album) async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    await photoProvider.deleteSingleAlbum(album);
  }
} 