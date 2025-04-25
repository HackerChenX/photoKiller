import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../constants/text_styles.dart';
import '../models/cleanup_result.dart';

class CleanupResultScreen extends StatefulWidget {
  final CleanupResult result;
  
  const CleanupResultScreen({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  State<CleanupResultScreen> createState() => _CleanupResultScreenState();
}

class _CleanupResultScreenState extends State<CleanupResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // 启动动画
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          AppStrings.cleanupComplete,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // 顶部区域：动画和统计信息
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 烟花动画（实际应用中应该替换为实际的动画资源）
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
                      ),
                    ),
                    child: Column(
                      children: [
                        // 在实际应用中使用资源文件
                        // Lottie.asset('assets/animations/fireworks.json', height: 200),
                        // 这里使用简单图标代替
                        const Icon(
                          Icons.celebration,
                          color: Colors.white,
                          size: 100,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppStrings.congratulations,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.keepGoing,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 底部区域：统计卡片和按钮
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.cleanupStats,
                    style: AppTextStyles.headline2,
                  ),
                  const SizedBox(height: 24),
                  
                  // 统计卡片
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildStatCard(
                            icon: Icons.delete,
                            title: '删除了 ${widget.result.deletedPhotos} 个文件',
                            subtitle: '共 ${widget.result.totalPhotos} 个文件',
                            iconColor: AppColors.danger,
                          ),
                          _buildStatCard(
                            icon: Icons.save,
                            title: '释放了 ${widget.result.formattedSavedSpace} 空间',
                            subtitle: '帮你节省宝贵存储空间',
                            iconColor: AppColors.success,
                          ),
                          
                          // 分类统计
                          if (widget.result.categoryCount.isNotEmpty)
                            _buildCategoryStats(),
                            
                          // 提示文字
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 24.0,
                            ),
                            child: Text(
                              AppStrings.goToSystemAlbum,
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 底部按钮
                  SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // 返回首页
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(AppStrings.backToHome),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headline3,
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryStats() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.category,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '清理详情',
                  style: AppTextStyles.headline3,
                ),
              ],
            ),
            const Divider(height: 24),
            
            // 各分类统计
            ...widget.result.categoryCount.entries.map((entry) {
              IconData icon;
              String label;
              
              // 根据类别设置图标和标签
              switch (entry.key) {
                case 'screenshot':
                  icon = Icons.screenshot;
                  label = '截图';
                  break;
                case 'video':
                  icon = Icons.videocam;
                  label = '视频';
                  break;
                case 'similar':
                  icon = Icons.compare;
                  label = '相似照片';
                  break;
                case 'duplicate':
                  icon = Icons.copy;
                  label = '重复照片';
                  break;
                default:
                  icon = Icons.photo;
                  label = '照片';
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${entry.value}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
} 