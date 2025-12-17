import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 貓咪資料模型 ---
class Cat {
  String id;
  String name;
  int level;
  double currentExp;
  int intimacy; // 親密度
  DateTime lastIntimacyUpdate; // 上次更新親密度的時間

  // 心情數值不存檔，每次重開隨機產生
  String moodName = "開心";
  int moodValue = 100;

  Cat({
    required this.id,
    required this.name,
    this.level = 1,
    this.currentExp = 0,
    this.intimacy = 20,
    DateTime? lastIntimacyUpdate,
  }) : lastIntimacyUpdate = lastIntimacyUpdate ?? DateTime.now();

  // 升級所需經驗公式: level * 30 + 360
  double get maxExp => (level * 30 + 360).toDouble();

  // 轉為 JSON 存檔用
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'level': level,
    'currentExp': currentExp,
    'intimacy': intimacy,
    'lastIntimacyUpdate': lastIntimacyUpdate.toIso8601String(),
  };

  // 從 JSON 讀檔
  factory Cat.fromJson(Map<String, dynamic> json) {
    return Cat(
      id: json['id'],
      name: json['name'],
      level: json['level'],
      currentExp: json['currentExp'],
      intimacy: json['intimacy'],
      lastIntimacyUpdate: DateTime.parse(json['lastIntimacyUpdate']),
    );
  }

  // --- 邏輯方法 ---

  // 隨機生成心情
  void randomizeMood() {
    int roll = Random().nextInt(100);
    if (roll < 50) { // 0-49 (50%)
      moodName = "開心";
      moodValue = 100;
    } else if (roll < 90) { // 50-89 (40%)
      moodName = "貪玩";
      moodValue = 300;
    } else { // 90-99 (10%)
      moodName = "想陪伴";
      moodValue = 1000;
    }
  }

  // 更新親密度 (每小時 +1)
  void updateIntimacy() {
    final now = DateTime.now();
    final difference = now.difference(lastIntimacyUpdate).inHours;
    if (difference >= 1) {
      int increase = difference; // 幾個小時就加幾點
      intimacy = (intimacy + increase).clamp(0, 100); // 最高 100
      lastIntimacyUpdate = now;
    }
  }

  // 獲得經驗值
  bool addExp(double amount) {
    currentExp += amount;
    bool leveledUp = false;
    while (currentExp >= maxExp && level < 100) {
      currentExp -= maxExp;
      level++;
      leveledUp = true;
    }
    return leveledUp;
  }
}

// --- 全域資料管理器 (Provider) ---
class CatProvider extends ChangeNotifier {
  int currency = 0; // 遊戲時間貨幣
  List<Cat> myCats = []; // 擁有的貓
  String currentCatId = "cat_001"; // 當前選擇的貓 ID

  CatProvider() {
    _loadData(); // 初始化時讀取資料
  }

  Cat get currentCat => myCats.firstWhere((cat) => cat.id == currentCatId, orElse: () => myCats.first);

  // 讀取資料
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    currency = prefs.getInt('currency') ?? 0;

    // 讀取貓咪列表
    List<String>? catsJson = prefs.getStringList('my_cats');
    if (catsJson != null) {
      myCats = catsJson.map((str) => Cat.fromJson(jsonDecode(str))).toList();
    } else {
      // 如果沒資料，送一隻初始貓
      myCats = [Cat(id: "cat_001", name: "橘貓")];
    }

    // 初始化數值
    for (var cat in myCats) {
      cat.updateIntimacy();
      cat.randomizeMood();
    }

    notifyListeners();
  }

  // 儲存資料
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('currency', currency);

    List<String> catsJson = myCats.map((cat) => jsonEncode(cat.toJson())).toList();
    prefs.setStringList('my_cats', catsJson);
    notifyListeners();
  }

  // 增加貨幣
  void addCurrency(int amount) {
    currency += amount;
    saveData();
  }

  // 切換貓咪
  void selectCat(String id) {
    currentCatId = id;
    currentCat.randomizeMood();
    notifyListeners();
  }

  void gainInteractionExp() {
    //心情 * 0.3 + 親密度 * 30
    double expGain = (currentCat.moodValue * 0.3) + (currentCat.intimacy * 30);
    bool leveledUp = currentCat.addExp(expGain);

    if (leveledUp) {
      //保留項
    }
    saveData();
  }
}