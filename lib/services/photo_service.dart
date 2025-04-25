import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/photo.dart';
import '../models/photo_group.dart';
import '../models/cleanup_result.dart';

class PhotoService {
  // 获取所有照片
  Future<List<Photo>> getAllPhotos() async {
    // 请求权限
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      throw Exception('没有相册访问权限');
    }
    
    // 获取所有资源
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.common,
    );
    
    if (albums.isEmpty) {
      return [];
    }
    
    // 获取所有照片资源
    final AssetPathEntity allPhotosAlbum = albums.first;
    final List<AssetEntity> assetList = await allPhotosAlbum.getAssetListRange(
      start: 0,
      end: await allPhotosAlbum.assetCountAsync,
    );
    
    // 转换为Photo对象
    List<Photo> photos = [];
    for (var asset in assetList) {
      final file = await asset.file;
      if (file != null) {
        final fileSize = await file.length();
        final fileName = path.basename(file.path);
        final format = path.extension(file.path).replaceFirst('.', '');
        
        PhotoType type = PhotoType.normal;
        
        // 判断照片类型
        if (asset.type == AssetType.video) {
          type = PhotoType.video;
        } else if (asset.type == AssetType.image && _isScreenshot(file.path, asset)) {
          type = PhotoType.screenshot;
        }
        
        // 获取缩略图
        final thumbnail = await asset.thumbnailDataWithSize(const ThumbnailSize(200, 200));
        String? thumbnailPath;
        
        if (thumbnail != null) {
          final tempDir = await getTemporaryDirectory();
          final thumbnailFile = File('${tempDir.path}/${asset.id}.jpg');
          await thumbnailFile.writeAsBytes(thumbnail);
          thumbnailPath = thumbnailFile.path;
        }
        
        photos.add(Photo(
          id: asset.id,
          path: file.path,
          thumbnailPath: thumbnailPath,
          createTime: asset.createDateTime,
          size: fileSize,
          type: type,
          resolution: '${asset.width}x${asset.height}',
          fileName: fileName,
          format: format,
          durationInSeconds: asset.type == AssetType.video ? asset.duration : null,
        ));
      }
    }
    
    return photos;
  }
  
  // 判断是否是截图
  bool _isScreenshot(String filePath, AssetEntity asset) {
    final fileName = path.basename(filePath).toLowerCase();
    
    // 检查文件名是否包含"截屏"或"screenshot"
    if (fileName.contains('截屏') || 
        fileName.contains('screenshot') || 
        fileName.contains('screen shot')) {
      return true;
    }
    
    // 检查尺寸比例是否接近屏幕比例
    final aspectRatio = asset.width / asset.height;
    if ((aspectRatio >= 1.7 && aspectRatio <= 1.8) || // 16:9
        (aspectRatio >= 1.3 && aspectRatio <= 1.4) || // 4:3
        (aspectRatio >= 1.99 && aspectRatio <= 2.1)) { // 18:9, 19.5:9, 20:9 等
      // 这里可以添加更多的启发式判断
      return true;
    }
    
    return false;
  }
  
  // 获取截图
  Future<List<Photo>> getScreenshots() async {
    final photos = await getAllPhotos();
    return photos.where((photo) => photo.type == PhotoType.screenshot).toList();
  }
  
  // 获取视频
  Future<List<Photo>> getVideos() async {
    final photos = await getAllPhotos();
    return photos.where((photo) => photo.type == PhotoType.video).toList();
  }
  
  // 识别重复照片（这里简化实现，实际项目中需要更复杂的算法）
  Future<List<PhotoGroup>> findDuplicatePhotos(List<Photo> photos) async {
    // 按照文件大小和创建时间分组，简化实现
    Map<String, List<Photo>> groups = {};
    
    for (var photo in photos) {
      // 创建一个简单的key，基于文件大小和分辨率
      // 实际项目中，应该使用图像哈希或更复杂的算法
      final key = '${photo.size}-${photo.resolution}';
      
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      
      groups[key]!.add(photo);
    }
    
    // 转换为PhotoGroup对象，只保留有多个照片的组
    List<PhotoGroup> duplicateGroups = [];
    int groupId = 0;
    
    groups.forEach((key, photoList) {
      if (photoList.length > 1) {
        // 对于重复照片，简单地将最新的照片作为推荐照片
        photoList.sort((a, b) => b.createTime.compareTo(a.createTime));
        
        duplicateGroups.add(PhotoGroup(
          id: groupId++,
          photos: photoList,
          groupType: PhotoType.duplicate,
          recommendedPhotoIndex: 0, // 推荐索引为0（最新的照片）
        ));
      }
    });
    
    return duplicateGroups;
  }
  
  // 识别相似照片（实际项目中需要更复杂的图像分析算法）
  Future<List<PhotoGroup>> findSimilarPhotos(List<Photo> photos) async {
    // 这里是简化实现，按照创建时间接近的照片分组
    // 实际项目中，应该使用计算机视觉算法对图像内容进行相似度分析
    
    // 先按日期排序
    photos.sort((a, b) => a.createTime.compareTo(b.createTime));
    
    List<PhotoGroup> similarGroups = [];
    List<Photo> currentGroup = [];
    int groupId = 0;
    
    for (int i = 0; i < photos.length; i++) {
      if (currentGroup.isEmpty) {
        currentGroup.add(photos[i]);
      } else {
        // 检查与当前组最后一张照片的时间差
        final timeDiff = photos[i].createTime.difference(currentGroup.last.createTime).inSeconds;
        
        // 如果时间差小于30秒，认为是相似照片（简化实现）
        if (timeDiff < 30) {
          currentGroup.add(photos[i]);
        } else {
          // 如果组内有多张照片，创建一个相似照片组
          if (currentGroup.length > 1) {
            // 为相似照片组选择推荐照片（这里简单地选择第一张）
            similarGroups.add(PhotoGroup(
              id: groupId++,
              photos: List.from(currentGroup),
              groupType: PhotoType.similar,
              recommendedPhotoIndex: 0,
            ));
          }
          
          // 开始新的组
          currentGroup = [photos[i]];
        }
      }
    }
    
    // 检查最后一组
    if (currentGroup.length > 1) {
      similarGroups.add(PhotoGroup(
        id: groupId,
        photos: currentGroup,
        groupType: PhotoType.similar,
        recommendedPhotoIndex: 0,
      ));
    }
    
    return similarGroups;
  }
  
  // 删除照片列表并返回结果
  Future<CleanupResult> deletePhotos(List<Photo> photos) async {
    int deletedCount = 0;
    int savedBytes = 0;
    Map<String, int> categoryCount = {};
    
    try {
      // 临时忽略权限检查，确保在后台运行时也能正常工作
      await PhotoManager.setIgnorePermissionCheck(true);
      
      // 获取所有照片的ID
      List<String> photoIds = photos.map((photo) => photo.id).toList();
      
      // 使用PhotoManager删除照片（从系统相册中删除）
      final List<String> deletedIds = await PhotoManager.editor.deleteWithIds(photoIds);
      
      // 计算删除的照片大小和类别信息
      if (deletedIds.isNotEmpty) {
        for (var photo in photos) {
          if (deletedIds.contains(photo.id)) {
            deletedCount++;
            savedBytes += photo.size;
            
            // 更新类别计数
            String category;
            switch (photo.type) {
              case PhotoType.screenshot:
                category = 'screenshot';
                break;
              case PhotoType.video:
                category = 'video';
                break;
              case PhotoType.similar:
                category = 'similar';
                break;
              case PhotoType.duplicate:
                category = 'duplicate';
                break;
              default:
                category = 'normal';
            }
            
            categoryCount[category] = (categoryCount[category] ?? 0) + 1;
          }
        }
      }
    } catch (e) {
      print('删除照片失败: $e');
    }
    
    return CleanupResult(
      totalPhotos: photos.length,
      deletedPhotos: deletedCount,
      savedBytes: savedBytes,
      categoryCount: categoryCount,
      cleanupTime: DateTime.now(),
    );
  }
} 