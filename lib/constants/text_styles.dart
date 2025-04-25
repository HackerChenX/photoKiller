import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  // 标题样式
  static const TextStyle headline1 = TextStyle(
    fontFamily: 'PingFang',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontFamily: 'PingFang',
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontFamily: 'PingFang',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  
  // 正文样式
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'PingFang',
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'PingFang',
    fontSize: 14,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'PingFang',
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  
  // 按钮文本样式
  static const TextStyle buttonText = TextStyle(
    fontFamily: 'PingFang',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
  
  // 标签样式
  static const TextStyle label = TextStyle(
    fontFamily: 'PingFang',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  
  // 数字统计样式
  static const TextStyle statNumber = TextStyle(
    fontFamily: 'PingFang',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle statLabel = TextStyle(
    fontFamily: 'PingFang',
    fontSize: 12,
    color: AppColors.textSecondary,
  );
} 