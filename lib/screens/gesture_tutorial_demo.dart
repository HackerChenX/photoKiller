import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gesture_tutorial.dart';
import '../services/tutorial_service.dart';

class GestureTutorialDemo extends StatefulWidget {
  const GestureTutorialDemo({Key? key}) : super(key: key);

  @override
  State<GestureTutorialDemo> createState() => _GestureTutorialDemoState();
}

class _GestureTutorialDemoState extends State<GestureTutorialDemo> {
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkIfTutorialNeeded();
  }

  Future<void> _checkIfTutorialNeeded() async {
    final hasSeenTutorial = await TutorialService.hasSeenGestureDemoTutorial();
    
    if (!hasSeenTutorial) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  void _resetTutorial() async {
    // 使用TutorialService提供的方法重置手势演示教程
    await TutorialService.resetGestureDemoTutorial();
    
    setState(() {
      _showTutorial = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手势引导演示'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetTutorial,
            tooltip: '重置教程',
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '这是主页面内容',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showTutorial = true;
                    });
                  },
                  child: const Text('显示手势教程'),
                ),
              ],
            ),
          ),
          if (_showTutorial)
            GestureTutorialSequence(
              tutorialSteps: [
                {
                  'direction': GestureDirection.up,
                  'text': '向上滑动可以查看更多内容',
                },
                {
                  'direction': GestureDirection.left,
                  'text': '向左滑动可以切换到下一张照片',
                },
                {
                  'direction': GestureDirection.right,
                  'text': '向右滑动可以返回上一张照片',
                },
                {
                  'direction': GestureDirection.tap,
                  'text': '点击照片可以查看详情',
                },
              ],
              onComplete: () {
                setState(() {
                  _showTutorial = false;
                });
                TutorialService.markGestureDemoTutorialAsSeen();
              },
            ),
        ],
      ),
    );
  }
} 