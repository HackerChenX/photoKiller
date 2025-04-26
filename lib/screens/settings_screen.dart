import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../constants/text_styles.dart';
import '../services/tutorial_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _cloudBackup = false;
  bool _notifications = true;
  
  // 重置所有教程并显示通知
  Future<void> _resetAllTutorials() async {
    await TutorialService.resetAllTutorials();
    
    if (mounted) {  // 确保组件仍然挂载
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有教程已重置，下次打开相关页面时将显示教程')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.settings),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // 基本设置
          _buildSectionHeader('基本设置'),
          _buildSwitchItem(
            icon: Icons.dark_mode,
            title: AppStrings.darkMode,
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          
          _buildSwitchItem(
            icon: Icons.cloud_upload,
            title: '云备份',
            subtitle: '自动备份删除的照片',
            value: _cloudBackup,
            onChanged: (value) {
              setState(() {
                _cloudBackup = value;
              });
            },
          ),
          
          _buildSwitchItem(
            icon: Icons.notifications,
            title: '推送通知',
            value: _notifications,
            onChanged: (value) {
              setState(() {
                _notifications = value;
              });
            },
          ),
          
          const Divider(),
          
          // 高级设置
          _buildSectionHeader('高级设置'),
          
          _buildNavigationItem(
            icon: Icons.storage,
            title: '本地存储',
            subtitle: '查看应用占用空间',
            onTap: () {
              // 导航到存储页面
            },
          ),
          
          _buildNavigationItem(
            icon: Icons.photo_album,
            title: '照片权限',
            subtitle: '管理照片访问权限',
            onTap: () {
              // 导航到权限页面
            },
          ),
          
          _buildNavigationItem(
            icon: Icons.sd_storage,
            title: '缓存管理',
            subtitle: '缓存占用: 23MB',
            onTap: () {
              // 导航到缓存页面
            },
            trailing: OutlinedButton(
              onPressed: () {
                // 清除缓存
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('缓存已清除')),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(80, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('清除'),
            ),
          ),
          
          _buildNavigationItem(
            icon: Icons.gesture,
            title: '手势教程',
            subtitle: '重置所有手势教程',
            onTap: () {}, // 不需要在点击行时执行操作，只通过按钮操作
            trailing: OutlinedButton(
              onPressed: _resetAllTutorials,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(80, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('重置'),
            ),
          ),
          
          const Divider(),
          
          // 关于和支持
          _buildSectionHeader('关于和支持'),
          
          _buildNavigationItem(
            icon: Icons.info,
            title: '关于应用',
            subtitle: '版本 1.0.0',
            onTap: () {
              // 显示关于页面
            },
          ),
          
          _buildNavigationItem(
            icon: Icons.feedback,
            title: '反馈问题',
            onTap: () {
              // 导航到反馈页面
            },
          ),
          
          _buildNavigationItem(
            icon: Icons.star,
            title: '给我们评分',
            onTap: () {
              // 打开应用商店评分页面
            },
          ),
          
          const SizedBox(height: 40),
          
          // 底部版权信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '© 2023 减法相册 版权所有',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.headline3.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }
  
  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTextStyles.bodySmall,
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
  
  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTextStyles.bodySmall,
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
} 