import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/photo.dart';
import '../models/photo_group.dart';
import '../models/cleanup_result.dart';
import '../services/photo_service.dart';

class PhotoProvider extends ChangeNotifier {
  final PhotoService _photoService = PhotoService();
  
  // 照片列表
  List<Photo> _allPhotos = [];
  List<Photo> _screenshots = [];
  List<Photo> _videos = [];
  
  // 照片组
  List<PhotoGroup> _duplicateGroups = [];
  List<PhotoGroup> _similarGroups = [];
  
  // 当前选择的照片
  List<Photo> _selectedPhotos = [];
  
  // 待删除的照片
  List<Photo> _pendingDeletePhotos = [];
  
  // 最后一个添加到待删除列表的照片
  Photo? _lastPendingDeletePhoto;
  
  // 加载状态
  bool _isLoading = false;
  String _loadingMessage = '';
  
  // 清理结果
  CleanupResult? _lastCleanupResult;
  
  // Getters
  List<Photo> get allPhotos => _allPhotos;
  List<Photo> get screenshots => _screenshots;
  List<Photo> get videos => _videos;
  List<PhotoGroup> get duplicateGroups => _duplicateGroups;
  List<PhotoGroup> get similarGroups => _similarGroups;
  List<Photo> get selectedPhotos => _selectedPhotos;
  List<Photo> get pendingDeletePhotos => _pendingDeletePhotos;
  int get pendingDeleteCount => _pendingDeletePhotos.length;
  Photo? get lastPendingDeletePhoto => _lastPendingDeletePhoto;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  CleanupResult? get lastCleanupResult => _lastCleanupResult;
  
  // 总照片数量
  int get totalPhotoCount => _allPhotos.length;
  
  // 各类型照片数量
  int get screenshotCount => _screenshots.length;
  int get videoCount => _videos.length;
  int get duplicateCount => _duplicateGroups.fold<int>(0, (sum, group) => sum + group.photos.length - 1);
  int get similarCount => _similarGroups.fold<int>(0, (sum, group) => sum + group.photos.length - 1);
  
  // 初始化加载所有照片
  Future<void> loadAllPhotos() async {
    _setLoading(true, '加载照片中...');
    try {
      _allPhotos = await _photoService.getAllPhotos();
      notifyListeners();
    } catch (e) {
      debugPrint('加载照片失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // 加载截图
  Future<void> loadScreenshots() async {
    _setLoading(true, '加载截图中...');
    try {
      _screenshots = await _photoService.getScreenshots();
      notifyListeners();
    } catch (e) {
      debugPrint('加载截图失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // 加载视频
  Future<void> loadVideos() async {
    _setLoading(true, '加载视频中...');
    try {
      _videos = await _photoService.getVideos();
      notifyListeners();
    } catch (e) {
      debugPrint('加载视频失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // 查找重复照片
  Future<void> findDuplicatePhotos() async {
    _setLoading(true, '分析重复照片中...');
    try {
      if (_allPhotos.isEmpty) {
        await loadAllPhotos();
      }
      
      _duplicateGroups = await _photoService.findDuplicatePhotos(_allPhotos);
      notifyListeners();
    } catch (e) {
      debugPrint('查找重复照片失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // 查找相似照片
  Future<void> findSimilarPhotos() async {
    _setLoading(true, '分析相似照片中...');
    try {
      if (_allPhotos.isEmpty) {
        await loadAllPhotos();
      }
      
      _similarGroups = await _photoService.findSimilarPhotos(_allPhotos);
      notifyListeners();
    } catch (e) {
      debugPrint('查找相似照片失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // 加载所有分类
  Future<void> loadAllCategories() async {
    _setLoading(true, '加载所有分类中...');
    try {
      await loadAllPhotos();
      await loadScreenshots();
      await loadVideos();
      await findDuplicatePhotos();
      await findSimilarPhotos();
    } catch (e) {
      debugPrint('加载所有分类失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // 添加照片到待删除列表
  void addToPendingDelete(Photo photo) {
    if (!_pendingDeletePhotos.any((p) => p.id == photo.id)) {
      _pendingDeletePhotos.add(photo);
      _lastPendingDeletePhoto = photo;
      notifyListeners();
    }
  }
  
  // 从待删除列表中移除照片
  void removeFromPendingDelete(Photo photo) {
    _pendingDeletePhotos.removeWhere((p) => p.id == photo.id);
    notifyListeners();
  }
  
  // 撤销最后一次添加到待删除列表的操作
  void undoLastPendingDelete() {
    if (_lastPendingDeletePhoto != null) {
      removeFromPendingDelete(_lastPendingDeletePhoto!);
      
      // 更新最后删除的照片为列表中的最后一个
      _lastPendingDeletePhoto = _pendingDeletePhotos.isNotEmpty 
          ? _pendingDeletePhotos.last 
          : null;
      
      notifyListeners();
    }
  }
  
  // 清空待删除列表
  void clearPendingDelete() {
    _pendingDeletePhotos.clear();
    _lastPendingDeletePhoto = null;
    notifyListeners();
  }
  
  // 判断照片是否在待删除列表中
  bool isPhotoPendingDelete(String photoId) {
    return _pendingDeletePhotos.any((p) => p.id == photoId);
  }
  
  // 获取当前照片的下一张照片
  Photo? getNextPhoto(Photo currentPhoto, PhotoType? type) {
    List<Photo> photoList;
    
    // 根据类型选择照片列表
    switch (type) {
      case PhotoType.screenshot:
        photoList = _screenshots;
        break;
      case PhotoType.video:
        photoList = _videos;
        break;
      case PhotoType.similar:
      case PhotoType.duplicate:
      default:
        photoList = _allPhotos;
        break;
    }
    
    if (photoList.isEmpty) return null;
    
    // 找到当前照片的索引
    final currentIndex = photoList.indexWhere((p) => p.id == currentPhoto.id);
    
    // 如果找不到当前照片，或者已经是最后一张，则返回null
    if (currentIndex == -1 || currentIndex >= photoList.length - 1) {
      return null;
    }
    
    // 返回下一张照片
    return photoList[currentIndex + 1];
  }
  
  // 获取当前照片的上一张照片
  Photo? getPreviousPhoto(Photo currentPhoto, PhotoType? type) {
    List<Photo> photoList;
    
    // 根据类型选择照片列表
    switch (type) {
      case PhotoType.screenshot:
        photoList = _screenshots;
        break;
      case PhotoType.video:
        photoList = _videos;
        break;
      case PhotoType.similar:
      case PhotoType.duplicate:
      default:
        photoList = _allPhotos;
        break;
    }
    
    if (photoList.isEmpty) return null;
    
    // 找到当前照片的索引
    final currentIndex = photoList.indexWhere((p) => p.id == currentPhoto.id);
    
    // 如果找不到当前照片，或者已经是第一张，则返回null
    if (currentIndex <= 0) {
      return null;
    }
    
    // 返回上一张照片
    return photoList[currentIndex - 1];
  }
  
  // 更新照片组中的照片选择状态
  void updatePhotoSelection(PhotoGroup group, String photoId, bool isSelected) {
    final updatedGroup = group.updatePhotoSelection(photoId, isSelected);
    
    if (group.groupType == PhotoType.duplicate) {
      final index = _duplicateGroups.indexWhere((g) => g.id == group.id);
      if (index != -1) {
        _duplicateGroups[index] = updatedGroup;
      }
    } else if (group.groupType == PhotoType.similar) {
      final index = _similarGroups.indexWhere((g) => g.id == group.id);
      if (index != -1) {
        _similarGroups[index] = updatedGroup;
      }
    }
    
    // 更新选中的照片列表
    _updateSelectedPhotos();
    
    notifyListeners();
  }
  
  // 选择或取消选择单张照片
  void togglePhotoSelection(Photo photo, bool isSelected) {
    final index = _selectedPhotos.indexWhere((p) => p.id == photo.id);
    
    if (isSelected && index == -1) {
      _selectedPhotos.add(photo.copyWith(isSelected: true));
    } else if (!isSelected && index != -1) {
      _selectedPhotos.removeAt(index);
    }
    
    notifyListeners();
  }
  
  // 全选或取消全选组内照片
  void selectAllInGroup(PhotoGroup group, bool isSelected) {
    if (group.groupType == PhotoType.duplicate) {
      final index = _duplicateGroups.indexWhere((g) => g.id == group.id);
      if (index != -1) {
        _duplicateGroups[index] = group.selectAll(isSelected);
      }
    } else if (group.groupType == PhotoType.similar) {
      final index = _similarGroups.indexWhere((g) => g.id == group.id);
      if (index != -1) {
        _similarGroups[index] = group.selectAll(isSelected);
      }
    }
    
    // 更新选中的照片列表
    _updateSelectedPhotos();
    
    notifyListeners();
  }
  
  // 更新选中的照片列表
  void _updateSelectedPhotos() {
    _selectedPhotos = [];
    
    // 从重复照片组中获取选中的照片
    for (var group in _duplicateGroups) {
      _selectedPhotos.addAll(group.selectedPhotos);
    }
    
    // 从相似照片组中获取选中的照片
    for (var group in _similarGroups) {
      _selectedPhotos.addAll(group.selectedPhotos);
    }
  }
  
  // 删除待删除照片
  Future<CleanupResult> deletePendingPhotos() async {
    _setLoading(true, '删除照片中...');
    try {
      if (_pendingDeletePhotos.isEmpty) {
        return CleanupResult(
          totalPhotos: 0,
          deletedPhotos: 0,
          savedBytes: 0,
          cleanupTime: DateTime.now(),
          categoryCount: {},
        );
      }
      
      final result = await _photoService.deletePhotos(_pendingDeletePhotos);
      
      // 更新最后的清理结果
      _lastCleanupResult = result;
      
      // 清空待删除照片
      _pendingDeletePhotos = [];
      
      // 重新加载照片（实际应用中可以优化，只移除已删除的照片）
      await loadAllCategories();
      
      return result;
    } catch (e) {
      debugPrint('删除照片失败: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // 删除选中的照片
  Future<CleanupResult> deleteSelectedPhotos() async {
    _setLoading(true, '删除照片中...');
    try {
      final result = await _photoService.deletePhotos(_selectedPhotos);
      
      // 更新最后的清理结果
      _lastCleanupResult = result;
      
      // 清空选中的照片
      _selectedPhotos = [];
      
      // 重新加载照片（实际应用中可以优化，只移除已删除的照片）
      await loadAllCategories();
      
      return result;
    } catch (e) {
      debugPrint('删除照片失败: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // 获取按月份分组的照片，每个月返回第一张照片
  Map<String, Photo> getPhotosByMonth() {
    // 按月份分组照片
    Map<String, List<Photo>> photosByMonth = {};
    
    // 对所有照片按时间倒序排序（最新的在前）
    List<Photo> sortedPhotos = List.from(_allPhotos);
    sortedPhotos.sort((a, b) => b.createTime.compareTo(a.createTime));
    
    // 按月份分组
    for (var photo in sortedPhotos) {
      // 格式化为年月，如"2023年04月"
      String monthKey = "${photo.createTime.year}年${photo.createTime.month.toString().padLeft(2, '0')}月";
      
      if (!photosByMonth.containsKey(monthKey)) {
        photosByMonth[monthKey] = [];
      }
      
      photosByMonth[monthKey]!.add(photo);
    }
    
    // 每个月取第一张照片（已按时间倒序排序，所以是该月最新的照片）
    Map<String, Photo> firstPhotoByMonth = {};
    photosByMonth.forEach((month, photos) {
      if (photos.isNotEmpty) {
        firstPhotoByMonth[month] = photos.first;
      }
    });
    
    return firstPhotoByMonth;
  }
  
  // 设置加载状态
  void _setLoading(bool loading, [String message = '']) {
    _isLoading = loading;
    _loadingMessage = message;
    notifyListeners();
  }
} 