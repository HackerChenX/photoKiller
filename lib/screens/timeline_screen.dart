import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../constants/text_styles.dart';
import '../models/photo.dart';
import '../providers/photo_provider.dart';
import '../widgets/loading_indicator.dart';
import 'photo_detail_screen.dart';

class TimelineScreen extends StatefulWidget {
  final TimelineViewType viewType;
  
  const TimelineScreen({
    Key? key, 
    this.viewType = TimelineViewType.all,
  }) : super(key: key);

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

enum TimelineViewType {
  all,         // 全部照片
  thisDay,     // 往年今日
  recentlyAdded // 最近新增
}

class _TimelineScreenState extends State<TimelineScreen> {
  bool _isLoading = false;
  Map<int, Map<int, List<Photo>>> _photosByYearAndMonth = {};
  List<Photo> _displayPhotos = [];
  
  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }
  
  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
      
      // 确保照片已加载
      if (photoProvider.allPhotos.isEmpty) {
        await photoProvider.loadAllPhotos();
      }
      
      // 根据视图类型筛选照片
      List<Photo> photosToProcess = [];
      
      switch (widget.viewType) {
        case TimelineViewType.thisDay:
          photosToProcess = _getThisDayPhotos(photoProvider.allPhotos);
          break;
        case TimelineViewType.recentlyAdded:
          photosToProcess = _getRecentlyAdded(photoProvider.allPhotos);
          break;
        case TimelineViewType.all:
        default:
          photosToProcess = photoProvider.allPhotos;
          break;
      }
      
      // 按年月组织照片
      if (widget.viewType == TimelineViewType.all) {
        _photosByYearAndMonth = _organizePhotosByYearAndMonth(photosToProcess);
      }
      
      _displayPhotos = photosToProcess;
    } catch (e) {
      print('加载照片失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 获取往年今日的照片
  List<Photo> _getThisDayPhotos(List<Photo> allPhotos) {
    final now = DateTime.now();
    return allPhotos.where((photo) {
      return photo.createTime.day == now.day && 
             photo.createTime.month == now.month && 
             photo.createTime.year < now.year;
    }).toList();
  }
  
  // 获取最近添加的照片（过去30天）
  List<Photo> _getRecentlyAdded(List<Photo> allPhotos) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return allPhotos.where((photo) => 
      photo.createTime.isAfter(thirtyDaysAgo)
    ).toList();
  }
  
  // 按年月组织照片
  Map<int, Map<int, List<Photo>>> _organizePhotosByYearAndMonth(List<Photo> photos) {
    final Map<int, Map<int, List<Photo>>> result = {};
    
    for (var photo in photos) {
      final year = photo.createTime.year;
      final month = photo.createTime.month;
      
      if (!result.containsKey(year)) {
        result[year] = {};
      }
      
      if (!result[year]!.containsKey(month)) {
        result[year]![month] = [];
      }
      
      result[year]![month]!.add(photo);
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    String title;
    
    switch (widget.viewType) {
      case TimelineViewType.thisDay:
        title = '往年今日';
        break;
      case TimelineViewType.recentlyAdded:
        title = '最近新增';
        break;
      case TimelineViewType.all:
      default:
        title = '时间线';
        break;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _isLoading 
        ? const LoadingIndicator(message: '加载照片中...')
        : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (_displayPhotos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到照片',
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
      );
    }
    
    // 不同视图类型使用不同的显示方式
    switch (widget.viewType) {
      case TimelineViewType.thisDay:
      case TimelineViewType.recentlyAdded:
        return _buildSimplePhotoGrid();
      case TimelineViewType.all:
      default:
        return _buildYearMonthTimeline();
    }
  }
  
  // 简单照片网格（用于往年今日和最近新增）
  Widget _buildSimplePhotoGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _displayPhotos.length,
      itemBuilder: (context, index) {
        final photo = _displayPhotos[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoDetailScreen(photo: photo),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(photo.path),
                fit: BoxFit.cover,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  color: Colors.black.withOpacity(0.5),
                  child: Text(
                    DateFormat('yyyy/MM/dd').format(photo.createTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 按年月组织的时间线
  Widget _buildYearMonthTimeline() {
    // 获取所有年份并排序（降序）
    final years = _photosByYearAndMonth.keys.toList()..sort((a, b) => b.compareTo(a));
    
    // 为每个年份预先构建月份结构，避免在ListView内构建大量子组件
    final List<Widget> yearSections = [];
    
    for (final year in years) {
      final months = _photosByYearAndMonth[year]!.keys.toList()..sort((a, b) => b.compareTo(a));
      
      // 添加年份标题
      yearSections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            '$year年',
            style: AppTextStyles.headline2,
          ),
        ),
      );
      
      // 添加每个月的照片
      for (final month in months) {
        final photosInMonth = _photosByYearAndMonth[year]![month]!;
        yearSections.add(_buildMonthSection(year, month, photosInMonth));
      }
    }
    
    return ListView(
      children: yearSections,
    );
  }
  
  // 构建月份区块
  Widget _buildMonthSection(int year, int month, List<Photo> photos) {
    final monthFormatter = DateFormat('MM');
    final monthName = monthFormatter.format(DateTime(year, month));
    
    // 准备照片网格的项目
    final List<Widget> photoItems = [];
    
    // 限制每个月显示的照片数量，避免过多照片导致性能问题
    final displayPhotos = photos.length > 16 ? photos.sublist(0, 16) : photos;
    
    for (final photo in displayPhotos) {
      photoItems.add(
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoDetailScreen(photo: photo),
              ),
            );
          },
          child: Image.file(
            File(photo.path),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    
    // 如果照片数量超过限制，添加"查看更多"按钮
    if (photos.length > 16) {
      photoItems.add(
        GestureDetector(
          onTap: () {
            // 打开包含该月所有照片的详细视图
            // 这里可以实现一个新页面来显示所有照片
          },
          child: Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Text(
                '查看全部 ${photos.length} 张',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 月份标题
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '$monthName月',
            style: AppTextStyles.headline3,
          ),
        ),
        // 使用自定义网格布局，而不是GridView.builder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = 4;
              final spacing = 2.0;
              final width = constraints.maxWidth;
              final itemWidth = (width - ((crossAxisCount - 1) * spacing)) / crossAxisCount;
              final itemHeight = itemWidth; // 正方形
              
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: photoItems.map((item) {
                  return SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: item,
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
} 