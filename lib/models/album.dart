import 'package:intl/intl.dart';

class Album {
  final String id;
  final String name;
  final DateTime createTime;
  final int? assetCount; // 相册中的资产数量
  final bool isSelected; // 是否被选中
  final String? coverPath; // 封面图片路径
  
  Album({
    required this.id,
    required this.name,
    required this.createTime,
    this.assetCount = 0, 
    this.isSelected = false,
    this.coverPath,
  });
  
  // 格式化创建日期
  String get formattedCreateDate {
    return DateFormat('yyyy年M月d日').format(createTime);
  }
  
  // 检查是否为空相册
  bool get isEmpty {
    return assetCount == null || assetCount == 0;
  }
  
  // 复制对象并修改属性
  Album copyWith({
    String? id,
    String? name,
    DateTime? createTime,
    int? assetCount,
    bool? isSelected,
    String? coverPath,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      createTime: createTime ?? this.createTime,
      assetCount: assetCount ?? this.assetCount,
      isSelected: isSelected ?? this.isSelected,
      coverPath: coverPath ?? this.coverPath,
    );
  }
} 