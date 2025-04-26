import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const String _hasSeenMainTutorialKey = 'hasSeenMainTutorial';
  static const String _hasSeenPhotoDetailTutorialKey = 'hasSeenPhotoDetailTutorial';
  static const String _hasSeenVideoTutorialKey = 'hasSeenVideoTutorial';
  static const String _hasSeenSelectionTutorialKey = 'hasSeenSelectionTutorial';
  static const String _hasSeenTimelineTutorialKey = 'hasSeenTimelineTutorial';
  static const String _hasSeenGestureDemoTutorialKey = 'hasSeenGestureDemoTutorial';
  
  // 检查用户是否已经看过主页引导
  static Future<bool> hasSeenMainTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenMainTutorialKey) ?? false;
  }
  
  // 检查用户是否已经看过照片详情页引导
  static Future<bool> hasSeenPhotoDetailTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenPhotoDetailTutorialKey) ?? false;
  }
  
  // 检查用户是否已经看过视频引导
  static Future<bool> hasSeenVideoTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenVideoTutorialKey) ?? false;
  }
  
  // 检查用户是否已经看过选择模式引导
  static Future<bool> hasSeenSelectionTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenSelectionTutorialKey) ?? false;
  }
  
  // 检查用户是否已经看过时间线页面引导
  static Future<bool> hasSeenTimelineTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenTimelineTutorialKey) ?? false;
  }
  
  // 检查用户是否已经看过手势教程演示页面引导
  static Future<bool> hasSeenGestureDemoTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenGestureDemoTutorialKey) ?? false;
  }
  
  // 标记用户已看过主页引导
  static Future<void> markMainTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenMainTutorialKey, true);
  }
  
  // 标记用户已看过照片详情页引导
  static Future<void> markPhotoDetailTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenPhotoDetailTutorialKey, true);
  }
  
  // 标记用户已看过视频引导
  static Future<void> markVideoTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenVideoTutorialKey, true);
  }
  
  // 标记用户已看过选择模式引导
  static Future<void> markSelectionTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenSelectionTutorialKey, true);
  }
  
  // 标记用户已看过时间线页面引导
  static Future<void> markTimelineTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenTimelineTutorialKey, true);
  }
  
  // 标记用户已看过手势教程演示页面引导
  static Future<void> markGestureDemoTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenGestureDemoTutorialKey, true);
  }
  
  // 重置所有引导状态（用于测试）
  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenMainTutorialKey, false);
    await prefs.setBool(_hasSeenPhotoDetailTutorialKey, false);
    await prefs.setBool(_hasSeenVideoTutorialKey, false);
    await prefs.setBool(_hasSeenSelectionTutorialKey, false);
    await prefs.setBool(_hasSeenTimelineTutorialKey, false);
    await prefs.setBool(_hasSeenGestureDemoTutorialKey, false);
  }
  
  // 重置手势演示教程状态
  static Future<void> resetGestureDemoTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenGestureDemoTutorialKey, false);
  }
} 