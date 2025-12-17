import 'dart:math';
import 'package:flutter/material.dart';

class DynamicBackground extends StatefulWidget {
  final int currentHour;

  const DynamicBackground({super.key, required this.currentHour});

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground> {
  List<Widget> _cachedStars = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_cachedStars.isEmpty) {
      _generateStars();
    }
  }

  void _generateStars() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final random = Random();

    List<Widget> stars = [];
    for (int i = 0; i < 20; i++) {
      stars.add(
        Positioned(
          // 使用螢幕寬高來計算分佈
          left: random.nextDouble() * screenWidth,
          top: random.nextDouble() * (screenHeight * 0.6), // 讓星星集中在上半部天空
          child: TwinklingStar(
            size: random.nextDouble() * 3 + 2, // 大小 2~5
            duration: Duration(milliseconds: random.nextInt(1000) + 1000), // 隨機閃爍速度
          ),
        ),
      );
    }

    _cachedStars = stars;
  }

  @override
  Widget build(BuildContext context) {
    bool isDayTime = widget.currentHour >= 6 && widget.currentHour < 18;

    return Stack(
      children: [
        if (isDayTime)
          ..._buildClouds()
        else
          ..._cachedStars,
      ],
    );
  }

  List<Widget> _buildClouds() {
    return [
      const MovingCloud(startX: 0.1, startY: 0.1, speed: 40, size: 60),
      const MovingCloud(startX: 0.5, startY: 0.2, speed: 60, size: 80),
      const MovingCloud(startX: 0.8, startY: 0.05, speed: 30, size: 50),
      const MovingCloud(startX: 0.2, startY: 0.3, speed: 50, size: 70),
    ];
  }
}
class MovingCloud extends StatefulWidget {
  final double startX;
  final double startY;
  final double speed;
  final double size;

  const MovingCloud({
    super.key,
    required this.startX,
    required this.startY,
    required this.speed,
    required this.size,
  });

  @override
  State<MovingCloud> createState() => _MovingCloudState();
}

class _MovingCloudState extends State<MovingCloud> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double screenWidth = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: widget.speed.toInt()),
      vsync: this,
    )..repeat(); // 讓動畫無限循環
    _animation = Tween<double>(begin: -0.3, end: 1.3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double currentVal = (_animation.value + widget.startX);
        if (currentVal > 1.3) currentVal -= 1.6;

        return Positioned(
          left: currentVal * screenWidth,
          top: widget.startY * screenHeight,
          child: Icon(
            Icons.cloud,
            color: Colors.white.withOpacity(0.7),
            size: widget.size,
          ),
        );
      },
    );
  }
}
class TwinklingStar extends StatefulWidget {
  final double size;
  final Duration duration;

  const TwinklingStar({super.key, required this.size, required this.duration});

  @override
  State<TwinklingStar> createState() => _TwinklingStarState();
}

class _TwinklingStarState extends State<TwinklingStar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _opacityAnim = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: Icon(Icons.star, color: Colors.white, size: widget.size),
    );
  }
}