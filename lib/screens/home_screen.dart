import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../constants/text_styles.dart';
import '../providers/photo_provider.dart';
import '../widgets/loading_indicator.dart';
import '../models/photo.dart';
import 'screenshots_screen.dart';
import 'videos_screen.dart';
import 'similar_photos_screen.dart';
import 'duplicate_photos_screen.dart';
import 'settings_screen.dart';
import 'photo_detail_screen.dart';
import 'empty_albums_screen.dart';
import 'blurry_photos_screen.dart';
import 'timeline_screen.dart';
import 'gesture_tutorial_demo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 使用Provider加载照片数据
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    await photoProvider.loadAllCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("减法相册"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.gesture),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GestureTutorialDemo()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, photoProvider, child) {
          if (photoProvider.isLoading) {
            return LoadingIndicator(message: photoProvider.loadingMessage);
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 按月份分组的照片滑动视图
                  _buildMonthlyPhotosSection(photoProvider),
                  
                  // 快捷整理部分
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '快捷整理',
                          style: AppTextStyles.headline2,
                        ),
                        const SizedBox(height: 12),
                        
                        // 使用网格布局，每行两个
                        GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 120, // 固定高度
                          ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 6,
                          itemBuilder: (context, index) {
                            switch (index) {
                              case 0:
                                return _buildQuickCleanupCard(
                                  title: '截屏',
                                  count: photoProvider.screenshotCount,
                                  icon: Icons.screenshot,
                                  color: Colors.orange,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ScreenshotsScreen(),
                                    ),
                                  ),
                                );
                              case 1:
                                return _buildQuickCleanupCard(
                                  title: '视频',
                                  count: photoProvider.videoCount,
                                  icon: Icons.videocam,
                                  color: Colors.red,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const VideosScreen(),
                                    ),
                                  ),
                                );
                              case 2:
                                return _buildQuickCleanupCard(
                                  title: '相似照片',
                                  count: photoProvider.similarCount,
                                  icon: Icons.compare,
                                  color: Colors.green,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SimilarPhotosScreen(),
                                    ),
                                  ),
                                );
                              case 3:
                                return _buildQuickCleanupCard(
                                  title: '重复项',
                                  count: photoProvider.duplicateCount,
                                  icon: Icons.copy,
                                  color: Colors.blue,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const DuplicatePhotosScreen(),
                                    ),
                                  ),
                                );
                              case 4:
                                return _buildQuickCleanupCard(
                                  title: '空相册',
                                  count: photoProvider.emptyAlbumCount,
                                  icon: Icons.folder_off,
                                  color: Colors.purple,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EmptyAlbumsScreen(),
                                    ),
                                  ),
                                );
                              case 5:
                                return _buildQuickCleanupCard(
                                  title: '模糊照片',
                                  count: photoProvider.blurryCount,
                                  icon: Icons.lens_blur,
                                  color: Colors.teal,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const BlurryPhotosScreen(),
                                    ),
                                  ),
                                );
                              default:
                                return const SizedBox();
                            }
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // 最近整理结果
                        if (photoProvider.lastCleanupResult != null)
                          _buildLastCleanupCard(photoProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyPhotosSection(PhotoProvider photoProvider) {
    Map<String, Photo> photosByMonth = photoProvider.getPhotosByMonth();
    
    if (photosByMonth.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 获取月份列表并按时间排序
    List<String> months = photosByMonth.keys.toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
          child: Row(
            children: [
              Text(
                '开始整理',
                style: AppTextStyles.headline2,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TimelineScreen(viewType: TimelineViewType.thisDay),
                    ),
                  );
                },
                child: const Text(
                  '往年今日',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TimelineScreen(viewType: TimelineViewType.recentlyAdded),
                    ),
                  );
                },
                child: const Text(
                  '最近新增',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          margin: const EdgeInsets.only(bottom: 16), // 添加底部边距
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: months.length,
            itemBuilder: (context, index) {
              final month = months[index];
              final photo = photosByMonth[month]!;
              final count = photoProvider.allPhotos.where((p) => 
                p.createTime.year == photo.createTime.year && 
                p.createTime.month == photo.createTime.month
              ).length;
              
              // 格式化月份显示，例如"2023年04月"
              final formattedMonth = "${photo.createTime.year}年${photo.createTime.month.toString().padLeft(2, '0')}月";
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () {
                    // 跳转到照片详情页
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoDetailScreen(
                          photo: photo,
                          albumName: month,
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      // 照片卡片
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 160,
                          height: 160, // 减小高度，留出空间给底部文本
                          color: Colors.black,
                          child: Image.file(
                            File(photo.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // 底部信息
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60, // 减小高度
                          padding: const EdgeInsets.all(6), // 减少内边距
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20, // 减小字体大小
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formattedMonth,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12, // 减小字体大小
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCleanupCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                '点击整理',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastCleanupCard(PhotoProvider photoProvider) {
    final result = photoProvider.lastCleanupResult!;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Container(
        height: 100, // 设置固定高度
        padding: const EdgeInsets.all(12.0), // 减少内边距
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_delete, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '最近整理',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Divider(height: 16), // 减少分隔线高度
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    label: '删除照片',
                    value: result.deletedPhotos.toString(),
                  ),
                  _buildStatItem(
                    label: '释放空间',
                    value: result.formattedSavedSpace,
                  ),
                  _buildStatItem(
                    label: '清理率',
                    value: result.formattedCleanupRate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
} 