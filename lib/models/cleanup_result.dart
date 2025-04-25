class CleanupResult {
  final int totalPhotos; // 总共处理的照片数量
  final int deletedPhotos; // 删除的照片数量
  final int savedBytes; // 节省的存储空间，单位byte
  final DateTime cleanupTime; // 清理时间
  final Map<String, int> categoryCount; // 各类别清理数量 {'screenshots': 10, 'duplicates': 5, ...}
  
  CleanupResult({
    required this.totalPhotos,
    required this.deletedPhotos,
    required this.savedBytes,
    required this.cleanupTime,
    required this.categoryCount,
  });
  
  // 获取格式化的节省存储空间
  String get formattedSavedSpace {
    if (savedBytes < 1024) {
      return '$savedBytes B';
    } else if (savedBytes < 1024 * 1024) {
      return '${(savedBytes / 1024).toStringAsFixed(2)} KB';
    } else if (savedBytes < 1024 * 1024 * 1024) {
      return '${(savedBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(savedBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
  
  // 获取清理率（删除的照片占总照片的百分比）
  double get cleanupRate {
    if (totalPhotos == 0) return 0.0;
    return (deletedPhotos / totalPhotos) * 100;
  }
  
  // 格式化清理率
  String get formattedCleanupRate {
    return '${cleanupRate.toStringAsFixed(1)}%';
  }
  
  // 合并两个清理结果
  CleanupResult merge(CleanupResult other) {
    final mergedCategoryCount = Map<String, int>.from(categoryCount);
    
    // 合并类别计数
    other.categoryCount.forEach((key, value) {
      mergedCategoryCount[key] = (mergedCategoryCount[key] ?? 0) + value;
    });
    
    return CleanupResult(
      totalPhotos: totalPhotos + other.totalPhotos,
      deletedPhotos: deletedPhotos + other.deletedPhotos,
      savedBytes: savedBytes + other.savedBytes,
      cleanupTime: DateTime.now(), // 使用当前时间作为合并后的清理时间
      categoryCount: mergedCategoryCount,
    );
  }
} 