import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/strings.dart';
import 'constants/theme.dart';
import 'providers/photo_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化应用
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
