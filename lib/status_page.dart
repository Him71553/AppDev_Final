import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cat_provider.dart';

class StatusPage extends StatelessWidget {
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 監聽資料變化
    return Consumer<CatProvider>(
      builder: (context, catData, child) {
        final cat = catData.currentCat;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white, // 狀態頁背景
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 頂部下拉選單
              _buildDropdown(context, catData),
              const SizedBox(height: 30),

              // 2. 貓咪基本資訊卡片
              _buildInfoCard("名字", cat.name, Icons.pets, Colors.orange),
              _buildInfoCard("等級", "Lv. ${cat.level}", Icons.star, Colors.yellow[700]!),

              const SizedBox(height: 20),

              // 3. 心情與親密度
              _buildStatRow("心情", "${cat.moodName} (數值:${cat.moodValue})", Icons.sentiment_satisfied_alt, Colors.pink),
              const SizedBox(height: 10),
              _buildStatRow("親密度", "${cat.intimacy} / 100", Icons.favorite, Colors.red),

              const SizedBox(height: 30),

              // 4. 經驗條
              Text("XP: ${cat.currentExp.toInt()} / ${cat.maxExp.toInt()}",
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: cat.currentExp / cat.maxExp,
                  minHeight: 20,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown(BuildContext context, CatProvider catData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: catData.currentCatId,
          isExpanded: true,
          items: catData.myCats.map((Cat cat) {
            return DropdownMenuItem<String>(
              value: cat.id,
              child: Text(cat.name, style: const TextStyle(fontSize: 18)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              catData.selectCat(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        trailing: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}