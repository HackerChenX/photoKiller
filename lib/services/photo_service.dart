import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/photo.dart';
import '../models/photo_group.dart';
import '../models/cleanup_result.dart';
import '../models/album.dart';

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
  
  // 获取所有相册
  Future<List<Album>> getAllAlbums() async {
    // 请求权限
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      throw Exception('没有相册访问权限');
    }
    
    // 获取所有相册
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );
    
    // 转换为Album对象
    List<Album> result = [];
    for (var albumEntity in albums) {
      final count = await albumEntity.assetCountAsync;
      String? coverPath;
      
      // 获取封面图片
      if (count > 0) {
        final assets = await albumEntity.getAssetListRange(start: 0, end: 1);
        if (assets.isNotEmpty) {
          final coverAsset = assets.first;
          final coverFile = await coverAsset.file;
          if (coverFile != null) {
            coverPath = coverFile.path;
          }
        }
      }
      
      result.add(Album(
        id: albumEntity.id,
        name: albumEntity.name,
        createTime: DateTime.now(), // 无法直接获取创建时间，用当前时间替代
        assetCount: count,
        coverPath: coverPath,
      ));
    }
    
    return result;
  }
  
  // 获取空相册
  Future<List<Album>> getEmptyAlbums() async {
    final albums = await getAllAlbums();
    return albums.where((album) => album.isEmpty).toList();
  }
  
  // 删除相册
  Future<bool> deleteAlbum(String albumId) async {
    try {
      // 获取相册
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList();
      final albumEntity = albums.firstWhere((album) => album.id == albumId);
      
      // 在手机系统中删除相册
      if (Platform.isIOS || Platform.isMacOS) {
        // iOS/macOS 使用 darwin.deletePath
        await PhotoManager.editor.darwin.deletePath(albumEntity);
      } else if (Platform.isAndroid) {
        // Android 平台没有直接删除相册的方法
        // 获取相册中所有资源并删除它们
        final assets = await albumEntity.getAssetListRange(
          start: 0, 
          end: await albumEntity.assetCountAsync
        );
        if (assets.isNotEmpty) {
          await PhotoManager.editor.deleteWithIds(assets.map((e) => e.id).toList());
        }
      }
      
      return true;
    } catch (e) {
      print('删除相册失败: $e');
      return false;
    }
  }
  
  // 批量删除相册
  Future<CleanupResult> deleteAlbums(List<Album> albums) async {
    int deletedCount = 0;
    Map<String, int> categoryCount = {'album': 0};
    
    try {
      for (var album in albums) {
        final success = await deleteAlbum(album.id);
        if (success) {
          deletedCount++;
          categoryCount['album'] = (categoryCount['album'] ?? 0) + 1;
        }
      }
    } catch (e) {
      print('批量删除相册失败: $e');
    }
    
    return CleanupResult(
      totalPhotos: albums.length,
      deletedPhotos: deletedCount,
      savedBytes: 0, // 相册本身不占用大量空间
      categoryCount: categoryCount,
      cleanupTime: DateTime.now(),
    );
  }
  
  // 获取模糊照片
  Future<List<Photo>> getBlurryPhotos() async {
    final photos = await getAllPhotos();
    
    // 过滤只保留图像类型，不包括视频和截图
    final imagePhotos = photos.where((photo) => 
      photo.type != PhotoType.video && 
      photo.type != PhotoType.screenshot
    ).toList();
    
    // 计算模糊分数
    List<Photo> processedPhotos = [];
    for (var photo in imagePhotos) {
      try {
        final blurScore = await _calculateBlurScore(photo.path);
        
        // 设置模糊阈值，高于此值认为是模糊照片
        if (blurScore > 100) { // 阈值可根据实际情况调整
          processedPhotos.add(photo.copyWith(
            type: PhotoType.blurry,
            blurScore: blurScore,
          ));
        }
      } catch (e) {
        print('计算模糊分数失败: $e');
      }
    }
    
    // 按照模糊分数排序，最模糊的在前面
    processedPhotos.sort((a, b) => 
      (b.blurScore ?? 0).compareTo(a.blurScore ?? 0)
    );
    
    return processedPhotos;
  }
  
  // 计算照片模糊分数的算法（使用拉普拉斯滤波器）
  Future<double> _calculateBlurScore(String imagePath) async {
    // 读取图像
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('无法解码图像');
    }
    
    // 如果图像太大，进行缩放以提高性能
    if (image.width > 1000 || image.height > 1000) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? 1000 : null,
        height: image.height >= image.width ? 1000 : null,
      );
    }
    
    // 转换为灰度图像
    final grayImage = img.grayscale(image);
    
    // 拉普拉斯滤波器核心
    const kernel = [
      0, 1, 0,
      1, -4, 1,
      0, 1, 0
    ];
    
    // 应用拉普拉斯滤波器
    img.Image laplacian = img.convolution(grayImage, filter: kernel);
    
    // 计算拉普拉斯变换后图像的方差
    double mean = 0;
    double squaredMean = 0;
    int pixelCount = 0;
    
    // 只取中心区域进行计算，避免边缘噪声
    int startX = laplacian.width ~/ 4;
    int startY = laplacian.height ~/ 4;
    int endX = laplacian.width * 3 ~/ 4;
    int endY = laplacian.height * 3 ~/ 4;
    
    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        var pixel = laplacian.getPixel(x, y);
        // 提取灰度值
        num gray = pixel.r; // 在灰度图像中，R=G=B
        
        mean += gray;
        squaredMean += gray * gray;
        pixelCount++;
      }
    }
    
    if (pixelCount > 0) {
      mean /= pixelCount;
      squaredMean /= pixelCount;
      
      // 方差 = E(X²) - (E(X))²
      double variance = squaredMean - (mean * mean);
      
      // 返回方差的对数，简化分数分布
      return math.log(variance + 1) * 100;
    }
    
    return 0.0; // 默认值
  }
} 