import 'package:flutter/material.dart';
import '../constants/colors.dart';

enum GestureDirection {
  up,
  down,
  left,
  right,
  tap,
}

class GestureTutorial extends StatefulWidget {
  final String text;
  final GestureDirection direction;
  final VoidCallback onDismiss;
  
  const GestureTutorial({
    Key? key,
    required this.text,
    required this.direction,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<GestureTutorial> createState() => _GestureTutorialState();
}

class _GestureTutorialState extends State<GestureTutorial> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  
  @override
  void initState() {
    super.initState();
    _initAnimation();
  }
  
  void _initAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // 根据方向设置动画
    switch (widget.direction) {
      case GestureDirection.up:
        _animation = Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(0, -0.2),
        ).animate(_controller);
        break;
      case GestureDirection.down:
        _animation = Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(0, 0.2),
        ).animate(_controller);
        break;
      case GestureDirection.left:
        _animation = Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(-0.2, 0),
        ).animate(_controller);
        break;
      case GestureDirection.right:
        _animation = Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(0.2, 0),
        ).animate(_controller);
        break;
      case GestureDirection.tap:
        // 对于点击，使用缩放动画
        _animation = Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(0, 0),
        ).animate(_controller);
        break;
    }
    
    // 重复动画
    _controller.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedIcon(),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                const Text(
                  '点击继续',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedIcon() {
    IconData iconData;
    Widget animatedWidget;
    
    switch (widget.direction) {
      case GestureDirection.up:
        iconData = Icons.arrow_upward;
        break;
      case GestureDirection.down:
        iconData = Icons.arrow_downward;
        break;
      case GestureDirection.left:
        iconData = Icons.arrow_back;
        break;
      case GestureDirection.right:
        iconData = Icons.arrow_forward;
        break;
      case GestureDirection.tap:
        iconData = Icons.touch_app;
        break;
    }
    
    if (widget.direction == GestureDirection.tap) {
      // 点击使用缩放动画
      animatedWidget = ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.8).animate(_controller),
        child: Icon(
          iconData,
          color: Colors.white,
          size: 60,
        ),
      );
    } else {
      // 其他方向使用位移动画
      animatedWidget = SlideTransition(
        position: _animation,
        child: Icon(
          iconData,
          color: Colors.white,
          size: 60,
        ),
      );
    }
    
    return animatedWidget;
  }
}

// 手势教程序列，管理多个教程步骤
class GestureTutorialSequence extends StatefulWidget {
  final List<Map<String, dynamic>> tutorialSteps;
  final VoidCallback onComplete;
  
  const GestureTutorialSequence({
    Key? key,
    required this.tutorialSteps,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<GestureTutorialSequence> createState() => _GestureTutorialSequenceState();
}

class _GestureTutorialSequenceState extends State<GestureTutorialSequence> {
  int _currentStep = 0;
  
  void _moveToNextStep() {
    if (_currentStep < widget.tutorialSteps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTutorial = widget.tutorialSteps[_currentStep];
    
    return GestureTutorial(
      text: currentTutorial['text'],
      direction: currentTutorial['direction'],
      onDismiss: _moveToNextStep,
    );
  }
}

// 用于快速演示手势教程的小部件
class GestureTutorialDemo extends StatefulWidget {
  const GestureTutorialDemo({Key? key}) : super(key: key);

  @override
  State<GestureTutorialDemo> createState() => _GestureTutorialDemoState();
}

class _GestureTutorialDemoState extends State<GestureTutorialDemo> {
  bool _showTutorial = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手势教程演示'),
      ),
      body: Stack(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showTutorial = true;
                });
              },
              child: const Text('显示教程'),
            ),
          ),
          if (_showTutorial)
            GestureTutorialSequence(
              tutorialSteps: [
                {
                  'direction': GestureDirection.up,
                  'text': '向上滑动可以浏览更多照片'
                },
                {
                  'direction': GestureDirection.left,
                  'text': '向左滑动可以查看下一张照片'
                },
                {
                  'direction': GestureDirection.right,
                  'text': '向右滑动可以查看上一张照片'
                },
                {
                  'direction': GestureDirection.down,
                  'text': '向下滑动可以删除照片'
                },
                {
                  'direction': GestureDirection.tap,
                  'text': '点击可以显示或隐藏照片信息'
                },
              ],
              onComplete: () {
                setState(() {
                  _showTutorial = false;
                });
              },
            ),
        ],
      ),
    );
  }
} 