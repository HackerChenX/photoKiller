import 'package:intl/intl.dart';

enum PhotoType {
  normal,
  screenshot,
  similar,
  duplicate,
  video,
  blurry,
}

class Photo {
  final String id;
  final String path;
  final String? thumbnailPath;
  final DateTime createTime;
  final int size; // 文件大小，单位byte
  final PhotoType type;
  final String? resolution; // 例如 "1920x1080"
  final String? fileName;
  final String? format; // 例如 "jpg", "png", "heic" 等
  final bool isRecommended; // 是否为推荐的最佳照片（在相似组中）
  final bool isSelected; // 是否被选中用于删除
  final int? durationInSeconds; // 视频时长，单位秒
  final int? similarityGroupId; // 相似照片组ID
  final double? blurScore; // 照片模糊程度评分，值越高越模糊
  
  Photo({
    required this.id,
    required this.path,
    this.thumbnailPath,
    required this.createTime,
    required this.size,
    this.type = PhotoType.normal,
    this.resolution,
    this.fileName,
    this.format,
    this.isRecommended = false,
    this.isSelected = false,
    this.durationInSeconds,
    this.similarityGroupId,
    this.blurScore,
  });
  
  // 格式化创建日期
  String get formattedDate {
    return DateFormat('yyyy年M月d日 HH:mm').format(createTime);
  }
  
  // 格式化文件大小
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
  
  // 格式化视频时长
  String? get formattedDuration {
    if (durationInSeconds == null) return null;
    
    final minutes = durationInSeconds! ~/ 60;
    final seconds = durationInSeconds! % 60;
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  
  // 复制照片对象并修改其某些属性
  Photo copyWith({
    String? id,
    String? path,
    String? thumbnailPath,
    DateTime? createTime,
    int? size,
    PhotoType? type,
    String? resolution,
    String? fileName,
    String? format,
    bool? isRecommended,
    bool? isSelected,
    int? durationInSeconds,
    int? similarityGroupId,
    double? blurScore,
  }) {
    return Photo(
      id: id ?? this.id,
      path: path ?? this.path,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createTime: createTime ?? this.createTime,
      size: size ?? this.size,
      type: type ?? this.type,
      resolution: resolution ?? this.resolution,
      fileName: fileName ?? this.fileName,
      format: format ?? this.format,
      isRecommended: isRecommended ?? this.isRecommended,
      isSelected: isSelected ?? this.isSelected,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      similarityGroupId: similarityGroupId ?? this.similarityGroupId,
      blurScore: blurScore ?? this.blurScore,
    );
  }
} 