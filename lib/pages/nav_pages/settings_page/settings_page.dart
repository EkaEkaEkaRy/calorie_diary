import 'package:calorie_diary/pages/nav_pages/settings_page/calorie_test_page/calorie_test_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int? _dailyCalories;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalorieNorm();
  }

  Future<void> _loadCalorieNorm() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyCalories = prefs.getInt('daily_calorie_norm');
      _isLoading = false;
    });
  }

  Future<void> _navigateToTestPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CalorieTestPage()),
    );
    _loadCalorieNorm(); // Обновляем значение при возвращении
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Настройки',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // ЗАГОВОЛОК БЛОКА (Для структуры)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
                  child: Text(
                    "Профиль и цели".toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),

                // КОМПАКТНЫЙ БЛОК НАСТРОЙКИ КАЛОРИЙ
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ListTile(
                      onTap: _navigateToTestPage,
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(Icons.calculate_outlined,
                            color: colorScheme.primary),
                      ),
                      title: const Text(
                        'Дневная норма калорий',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      // Показываем текущее значение, если оно есть, либо текст "Рассчитать"
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _dailyCalories != null
                                ? '$_dailyCalories ккал'
                                : 'Рассчитать',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _dailyCalories != null
                                  ? colorScheme.primary
                                  : colorScheme.error,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right,
                              size: 20,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  ),
                ),

                // Сюда в будущем можно легко добавлять новые блоки ListTile:
                // _buildSectionHeader("Интерфейс"),
                // _buildSettingsTile(Icons.dark_mode, "Тёмная тема", ...),
              ],
            ),
    );
  }
}
