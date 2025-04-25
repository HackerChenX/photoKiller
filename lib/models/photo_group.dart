import 'photo.dart';

class PhotoGroup {
  final int id;
  final List<Photo> photos;
  final PhotoType groupType;
  final int? recommendedPhotoIndex; // 推荐照片的索引，如果有的话
  
  PhotoGroup({
    required this.id,
    required this.photos,
    required this.groupType,
    this.recommendedPhotoIndex,
  });
  
  // 获取推荐的照片
  Photo? get recommendedPhoto {
    if (recommendedPhotoIndex != null &&
        recommendedPhotoIndex! >= 0 &&
        recommendedPhotoIndex! < photos.length) {
      return photos[recommendedPhotoIndex!];
    }
    return null;
  }
  
  // 获取组内照片的总大小
  int get totalSize {
    return photos.fold(0, (previousValue, photo) => previousValue + photo.size);
  }
  
  // 获取已选择的照片
  List<Photo> get selectedPhotos {
    return photos.where((photo) => photo.isSelected).toList();
  }
  
  // 获取格式化的总大小
  String get formattedTotalSize {
    final totalBytes = totalSize;
    
    if (totalBytes < 1024) {
      return '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(2)} KB';
    } else if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
  
  // 复制照片组并修改其属性
  PhotoGroup copyWith({
    int? id,
    List<Photo>? photos,
    PhotoType? groupType,
    int? recommendedPhotoIndex,
  }) {
    return PhotoGroup(
      id: id ?? this.id,
      photos: photos ?? this.photos,
      groupType: groupType ?? this.groupType,
      recommendedPhotoIndex: recommendedPhotoIndex ?? this.recommendedPhotoIndex,
    );
  }
  
  // 更新组内特定照片的选择状态
  PhotoGroup updatePhotoSelection(String photoId, bool isSelected) {
    final updatedPhotos = photos.map((photo) {
      if (photo.id == photoId) {
        return photo.copyWith(isSelected: isSelected);
      }
      return photo;
    }).toList();
    
    return copyWith(photos: updatedPhotos);
  }
  
  // 全选或取消全选组内所有照片
  PhotoGroup selectAll(bool isSelected) {
    final updatedPhotos = photos.map((photo) {
      return photo.copyWith(isSelected: isSelected);
    }).toList();
    
    return copyWith(photos: updatedPhotos);
  }
} 