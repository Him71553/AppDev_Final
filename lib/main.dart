import 'dart:async';
import 'dart:math';
import 'package:appdev/dynamic_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'cat_provider.dart';
import 'status_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CatProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 3,
        child: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        title: Consumer<CatProvider>(
            builder: (context, data, child) => Text(
                "貨幣: ${data.currency} 分",
                style: const TextStyle(color: Colors.black, fontSize: 16)
            )
        ),
        bottom: const TabBar(
          labelColor: Colors.black,
          indicatorColor: Colors.orange,
          tabs: [
            Tab(text: "狀態"),
            Tab(text: "遊戲(主頁)"),
            Tab(text: "買貓"),
          ],
        ),
      ),
      body: const TabBarView(
        physics: NeverScrollableScrollPhysics(),
        children: [
          StatusPage(),
          CatImmersiveHome(),
          Center(child: Text("商店開發中...")),
        ],
      ),
    );
  }
}

class CatImmersiveHome extends StatefulWidget {
  const CatImmersiveHome({super.key});

  @override
  State<CatImmersiveHome> createState() => _CatImmersiveHomeState();
}

class _CatImmersiveHomeState extends State<CatImmersiveHome> with TickerProviderStateMixin {
  Timer? _currencyTimer;
  Timer? _interactionExpTimer;
  int _accumulatedInteractionSeconds = 0;
  Timer? _resetStatusTimer;
  DateTime? _lastPetTime;
  List<Widget> hearts = [];
  double screenWidth = 0;
  double screenHeight = 0;
  double catX = 0;
  double catY = 0;
  Color backgroundColor = Colors.blue;
  String timePeriodText = "Loading...";
  String catStatus = "idle";
  String idleAnimationType = "default";

  Timer? _timeCheckTimer;
  Timer? _movementTimer;
  Timer? _idleCheckTimer;
  int _secondsSinceLastAction = 0;

  // --- 初始化 ---
  @override
  void initState() {
    super.initState();
    _updateBackgroundByTime();
    _timeCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateBackgroundByTime();
    });
    _idleCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsSinceLastAction++;
      _checkIdleStatus();
    });
    _currencyTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // 使用 Provider 存錢
      context.read<CatProvider>().addCurrency(1);
    });
    _interactionExpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 如果貓咪處於互動狀態 (interacting)
      if (catStatus == "interacting") {
        _accumulatedInteractionSeconds++;
        // 每滿 10 秒
        if (_accumulatedInteractionSeconds >= 10) {
          _accumulatedInteractionSeconds = 0;
          // 加經驗值
          context.read<CatProvider>().gainInteractionExp();

          // 可以在這裡加一個飄飛文字特效: "+EXP" (進階)
          debugPrint("獲得經驗值！");
        }
      } else {
        // 如果中斷互動，是否要重置？通常為了體驗，可以不用馬上重置，或是累積制
        // 這裡暫時不重置，讓玩家可以分段摸
      }
    });
    _startRandomMovement();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    if (catX == 0 && catY == 0) {
      catX = screenWidth / 2 - 50;
      catY = screenHeight / 2 - 50;
    }
  }

  @override
  void dispose() {
    _currencyTimer?.cancel();
    _interactionExpTimer?.cancel();
    _timeCheckTimer?.cancel();
    _movementTimer?.cancel();
    _idleCheckTimer?.cancel();
    super.dispose();
  }

  // --- 邏輯函數 ---
  void _updateBackgroundByTime() {
    final now = DateTime.now();
    final hour = now.hour;
    setState(() {
      if (hour >= 6 && hour < 11) {
        backgroundColor = const Color(0xFF87CEEB);
        timePeriodText = "早安";
      } else if (hour >= 11 && hour < 14) {
        backgroundColor = const Color(0xFFFFD700);
        timePeriodText = "午安";
      } else if (hour >= 14 && hour < 18) {
        backgroundColor = const Color(0xFFFFA07A);
        timePeriodText = "下午好";
      } else {
        backgroundColor = const Color(0xFF2C3E50);
        timePeriodText = "晚安";
      }
    });
  }

  void _startRandomMovement() {
    _movementTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (catStatus == "interacting") return;
      if (Random().nextBool() && Random().nextBool()) {
        _moveCatRandomly();
      }
    });
  }
  void _handlePetting() {
    // --- 1. 狀態控制 (解決閃爍問題的核心) ---

    // 只要手指還在動，就先「取消」變回原狀的命令
    _resetStatusTimer?.cancel();

    setState(() {
      catStatus = "interacting"; // 強制設定為愛心狀態
      idleAnimationType = "default"; // 確保不會卡在睡覺動畫
      _secondsSinceLastAction = 0;   // 重置閒置計時
    });

    // 重新設定倒數：只有當你「停手」滿 0.5 秒後，貓咪才會變回原狀
    _resetStatusTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        catStatus = "idle";
      });
    });

    // --- 2. 愛心特效 (保持冷卻，避免愛心太多) ---
    final now = DateTime.now();
    if (_lastPetTime == null || now.difference(_lastPetTime!) > const Duration(milliseconds: 300)) {
      _lastPetTime = now;
      _spawnHeart(); // 生成飄飛愛心
    }
  }

  // 生成一顆愛心放到列表裡
  void _spawnHeart() {
    final id = UniqueKey(); // 給每個愛心一個唯一 ID
    setState(() {
      hearts.add(
        Positioned(
          key: id,
          left: catX + 35,
          top: catY - 20,
          child: FloatingHeart(
            onComplete: () {
              setState(() {
                hearts.removeWhere((element) => element.key == id);
              });
            },
          ),
        ),
      );
    });
  }
  void _moveCatRandomly() {
    setState(() {
      catStatus = "moving";
      idleAnimationType = "default";
      double margin = 50.0;
      double minHeight = screenHeight * 0.6;
      double maxHeight = screenHeight - margin - 100;

      catX = margin + Random().nextDouble() * (screenWidth - margin * 2);
      catY = minHeight + Random().nextDouble() * (maxHeight - minHeight);
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (catStatus == "moving") {
        setState(() {
          catStatus = "idle";
        });
      }
    });
  }

  void _checkIdleStatus() {
    if (_secondsSinceLastAction > 10 && catStatus != "deep_idle") {
      _triggerRandomIdleAnimation();
    }
  }

  void _triggerRandomIdleAnimation() {
    setState(() {
      catStatus = "deep_idle";
      int randomAnim = Random().nextInt(3) + 1;
      idleAnimationType = "idle_anim_$randomAnim";
    });
  }

  void _onCatTap() {
    setState(() {
      _secondsSinceLastAction = 0;
      catStatus = "interacting";
      idleAnimationType = "default";
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        catStatus = "idle";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // 獲取當前小時
    final int currentHour = DateTime.now().hour;

    return Scaffold(
      body: Stack(
        children: [
          // 1. 背景顏色
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            width: double.infinity,
            height: double.infinity,
            color: backgroundColor,
          ),

          // 2. 動態背景
          DynamicBackground(currentHour: currentHour),

          // 3. 貓咪
          AnimatedPositioned(
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            left: catX,
            top: catY,
            child: GestureDetector(
              onTap: () {
                _spawnHeart();
                _onCatTap();
              },
              onPanUpdate: (details) {
                _handlePetting();
              },
              // ---------------------------------
              child: _buildCatWidget(),
            ),
          ),
          ...hearts,
        ],
      ),
    );
  }

  Widget _buildCatWidget() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (catStatus == "interacting")
            const Icon(Icons.favorite, color: Colors.red, size: 40)
          else if (catStatus == "deep_idle")
            _getIdleIcon()
          else if (catStatus == "moving")
              const Icon(Icons.directions_walk, color: Colors.black54, size: 40)
            else
              const Icon(Icons.pets, color: Colors.orange, size: 40),
          const SizedBox(height: 5),
          Text(
            catStatus == "deep_idle" ? idleAnimationType : "Meow",
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  Widget _getIdleIcon() {
    switch (idleAnimationType) {
      case "idle_anim_1":
        return const Icon(Icons.nightlight_round, color: Colors.blue, size: 40);
      case "idle_anim_2":
        return const Icon(Icons.cleaning_services,
            color: Colors.purple, size: 40);
      case "idle_anim_3":
        return const Icon(Icons.accessibility_new,
            color: Colors.green, size: 40);
      default:
        return const Icon(Icons.bedtime, color: Colors.grey, size: 40);
    }
  }
}
// --- 新增：飄飛的愛心特效 ---
class FloatingHeart extends StatefulWidget {
  final VoidCallback onComplete;

  const FloatingHeart({super.key, required this.onComplete});

  @override
  State<FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<FloatingHeart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _positionAnim = Tween<double>(begin: 0, end: -100).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward().then((value) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _positionAnim.value),
          child: Opacity(
            opacity: _opacityAnim.value,
            child: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 30),
          ),
        );
      },
    );
  }
}