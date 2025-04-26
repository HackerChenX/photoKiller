import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/strings.dart';
import '../models/photo.dart';
import '../providers/photo_provider.dart';
import '../services/tutorial_service.dart';
import '../widgets/gesture_tutorial.dart';
import 'cleanup_result_screen.dart';
import 'pending_delete_screen.dart';

class PhotoDetailScreen extends StatefulWidget {
  final Photo photo;
  final String? albumName;
  final String? extraInfo;
  
  const PhotoDetailScreen({
    Key? key,
    required this.photo,
    this.albumName,
    this.extraInfo,
  }) : super(key: key);

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  // 用于处理滑动手势
  late DragStartDetails _startDetails;
  late DragUpdateDetails _updateDetails;
  bool _isDeleting = false;
  double _deleteProgress = 0;
  bool _showDetails = false;
  
  // 当前显示的照片
  late Photo _currentPhoto;
  
  // 是否显示手势教程
  bool _showTutorial = false;
  
  @override
  void initState() {
    super.initState();
    _currentPhoto = widget.photo;
    _checkIfTutorialNeeded();
  }
  
  Future<void> _checkIfTutorialNeeded() async {
    // 检查用户是否已经看过照片详情页手势教程
    final hasSeenTutorial = await TutorialService.hasSeenPhotoDetailTutorial();
    
    if (!hasSeenTutorial) {
      setState(() {
        _showTutorial = true;
      });
    }
  }
  
  // 返回确认对话框
  Future<bool> _showExitConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text(
                  '确定返回吗',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '已整理的进度将不会被记录，确定要返回吗？',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.grey)
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            '取消',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            '确认',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false;
  }
  
  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);
    final isPendingDelete = photoProvider.isPhotoPendingDelete(_currentPhoto.id);
    
    // 获取当前照片索引
    int currentIndex = 0;
    int totalPhotos = 0;
    
    List<Photo> photoList;
    switch (_currentPhoto.type) {
      case PhotoType.screenshot:
        photoList = photoProvider.screenshots;
        break;
      case PhotoType.video:
        photoList = photoProvider.videos;
        break;
      case PhotoType.similar:
      case PhotoType.duplicate:
      default:
        photoList = photoProvider.allPhotos;
        break;
    }
    
    if (photoList.isNotEmpty) {
      currentIndex = photoList.indexWhere((p) => p.id == _currentPhoto.id) + 1;
      totalPhotos = photoList.length;
    }
    
    return WillPopScope(
      onWillPop: () async {
        // 如果有待删除的照片，显示确认对话框
        if (photoProvider.pendingDeleteCount > 0) {
          final confirmed = await _showExitConfirmDialog();
          if (confirmed) {
            // 清空待删除列表
            photoProvider.clearPendingDelete();
          }
          return confirmed;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.8),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black),
            onPressed: () async {
              // 如果有待删除的照片，显示确认对话框
              if (photoProvider.pendingDeleteCount > 0) {
                final confirmed = await _showExitConfirmDialog();
                if (confirmed) {
                  // 清空待删除列表
                  photoProvider.clearPendingDelete();
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.albumName ?? '四月',
                    style: const TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$currentIndex/$totalPhotos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          titleSpacing: 0,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 4),
              height: 32,
              child: TextButton(
                onPressed: () {
                  // 查看相册
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: const Size(10, 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '查看相册', 
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              height: 32,
              child: TextButton(
                onPressed: () {
                  // 完成操作，如果有待删除照片，跳转到删除确认页面
                  if (photoProvider.pendingDeleteCount > 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PendingDeleteScreen(),
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: const Size(10, 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '完成', 
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            GestureDetector(
              onHorizontalDragEnd: (details) {
                // 检测左右滑动
                if (details.primaryVelocity == null) return;
                
                // 左滑：下一张
                if (details.primaryVelocity! < 0) {
                  _navigateToNextPhoto();
                  // 如果是最后一张，则跳转到完成页面
                  if (currentIndex == totalPhotos) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PendingDeleteScreen(),
                      ),
                    );
                  }
                } 
                // 右滑：回到上一张并撤销删除
                else if (details.primaryVelocity! > 0) {
                  _undoAndNavigateToPrevious();
                }
              },
              onVerticalDragStart: (details) {
                _startDetails = details;
              },
              onVerticalDragUpdate: (details) {
                _updateDetails = details;
                final deltaY = details.globalPosition.dy - _startDetails.globalPosition.dy;
                
                // 下滑处理待删除照片
                if (deltaY > 50) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final progress = (deltaY - 50) / (screenHeight / 3);
                  
                  setState(() {
                    _isDeleting = true;
                    _deleteProgress = progress.clamp(0.0, 1.0);
                  });
                } else {
                  setState(() {
                    _isDeleting = false;
                    _deleteProgress = 0;
                  });
                }
              },
              onVerticalDragEnd: (details) {
                // 如果下拉达到阈值，则添加到待删除列表
                if (_isDeleting && _deleteProgress > 0.5) {
                  _addToPendingDelete();
                }
                
                // 重置状态
                setState(() {
                  _isDeleting = false;
                  _deleteProgress = 0;
                });
              },
              child: Stack(
                children: [
                  // 照片查看区
                  Center(
                    child: Hero(
                      tag: 'photo_${_currentPhoto.id}',
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            isPendingDelete 
                                ? Colors.grey.withOpacity(0.7) 
                                : Colors.transparent,
                            BlendMode.srcATop,
                          ),
                          child: Image.file(
                            File(_currentPhoto.path),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // 删除指示器
                  if (_isDeleting)
                    Positioned.fill(
                      child: Container(
                        color: AppColors.danger.withOpacity(0.3 * _deleteProgress),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPendingDelete ? Icons.restore : Icons.delete,
                                color: Colors.white,
                                size: 48 * _deleteProgress,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isPendingDelete ? '撤销删除' : '添加到删除',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20 * _deleteProgress,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                  // 待删除标记
                  if (isPendingDelete)
                    Positioned(
                      top: 80,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '待删除',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // 显示手势教程
            if (_showTutorial)
              GestureTutorialSequence(
                tutorialSteps: [
                  {
                    'direction': GestureDirection.left,
                    'text': '向左滑动可以查看下一张照片',
                  },
                  {
                    'direction': GestureDirection.right,
                    'text': '向右滑动可以查看上一张照片',
                  },
                  {
                    'direction': GestureDirection.down,
                    'text': '向下滑动可以删除当前照片',
                  },
                ],
                onComplete: () {
                  setState(() {
                    _showTutorial = false;
                  });
                  TutorialService.markPhotoDetailTutorialAsSeen();
                },
              ),
          ],
        ),
        bottomNavigationBar: Container(
          color: Colors.white.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 撤销按钮
                IconButton(
                  icon: const Icon(Icons.refresh),
                  color: Colors.amber,
                  onPressed: () {
                    _undoAndNavigateToPrevious();
                  },
                ),
                // 删除按钮
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.black,
                  onPressed: () {
                    if (isPendingDelete) {
                      photoProvider.removeFromPendingDelete(_currentPhoto);
                    } else {
                      _addToPendingDelete();
                    }
                  },
                ),
                // 分享按钮
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  color: Colors.blue,
                  onPressed: () {
                    _navigateToNextPhoto();
                  },
                ),
                // 更多按钮
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      color: Colors.blue,
                      onPressed: () {
                        if (photoProvider.pendingDeleteCount > 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PendingDeleteScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    if (photoProvider.pendingDeleteCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${photoProvider.pendingDeleteCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 添加到待删除列表并切换到下一张照片
  void _addToPendingDelete() {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final isPendingDelete = photoProvider.isPhotoPendingDelete(_currentPhoto.id);
    
    if (isPendingDelete) {
      photoProvider.removeFromPendingDelete(_currentPhoto);
    } else {
      photoProvider.addToPendingDelete(_currentPhoto);
      
      // 自动切换到下一张照片
      _navigateToNextPhoto();
    }
  }
  
  // 撤销并导航到上一张照片
  void _undoAndNavigateToPrevious() {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final previousPhoto = photoProvider.getPreviousPhoto(_currentPhoto, _currentPhoto.type);
    
    if (previousPhoto != null) {
      // 先导航到上一张照片
      setState(() {
        _currentPhoto = previousPhoto;
      });
      
      // 检查上一张照片是否在待删除列表中，如果是则移除
      if (photoProvider.isPhotoPendingDelete(previousPhoto.id)) {
        photoProvider.removeFromPendingDelete(previousPhoto);
      }
    } else {
      // 如果没有上一张照片，尝试撤销最后一次删除操作
      if (photoProvider.lastPendingDeletePhoto != null) {
        photoProvider.undoLastPendingDelete();
      }
    }
  }
  
  // 导航到下一张照片
  void _navigateToNextPhoto() {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final nextPhoto = photoProvider.getNextPhoto(_currentPhoto, _currentPhoto.type);
    
    if (nextPhoto != null) {
      setState(() {
        _currentPhoto = nextPhoto;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已经是最后一张照片')),
      );
    }
  }
  
  // 导航到上一张照片
  void _navigateToPreviousPhoto() {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final previousPhoto = photoProvider.getPreviousPhoto(_currentPhoto, _currentPhoto.type);
    
    if (previousPhoto != null) {
      setState(() {
        _currentPhoto = previousPhoto;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已经是第一张照片')),
      );
    }
  }

  Widget _buildMetadata() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _showDetails ? 220 : 0,
      color: Colors.black.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '照片信息',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('文件名', _currentPhoto.fileName ?? '未知'),
            _buildInfoRow('大小', _currentPhoto.formattedSize),
            _buildInfoRow('拍摄时间', _currentPhoto.formattedDate),
            _buildInfoRow('分辨率', _currentPhoto.resolution ?? '未知'),
            _buildInfoRow('格式', _currentPhoto.format?.toUpperCase() ?? '未知'),
            if (widget.extraInfo != null)
              _buildInfoRow('其他信息', widget.extraInfo!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
} 