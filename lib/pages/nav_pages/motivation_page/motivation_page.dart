import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:calorie_diary/data/facts_list.dart';
import 'package:calorie_diary/pages/nav_pages/motivation_page/components/breathing_exercise.dart';
import 'package:calorie_diary/pages/nav_pages/motivation_page/components/bubble_item.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class MotivationPage extends StatefulWidget {
  const MotivationPage({super.key});

  @override
  State<MotivationPage> createState() => _MotivationPageState();
}

class _MotivationPageState extends State<MotivationPage> {
  Timer? _timer;
  int _start = 900; // 15 минут в секундах
  bool _isTimerRunning = false;
  int _factIndex = Random().nextInt(facts.length);

  final AudioPlayer _commonPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Предзагружаем звук один раз
    _commonPlayer.setSource(AssetSource('music/bubble.mp3'));
    // Отключаем лишний спам в консоль
    _commonPlayer.setReleaseMode(ReleaseMode.stop);
  }

  // Метод для воспроизведения
  void _playPopSound() {
    _commonPlayer.stop(); // Мгновенно сбрасываем, если звук уже идет
    _commonPlayer.resume(); // Играем заново
  }

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
      _start = 900;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _timer?.cancel();
          _isTimerRunning = false;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _commonPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Поддержка'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // БЛОК ТАЙМЕРА
          _buildTimerCard(colorScheme),
          const SizedBox(height: 15),

          // КНОПКА ДЫХАНИЯ
          _buildActionCard(
            colorScheme,
            title: "Техника «Квадратное дыхание»",
            subtitle: "Поможет успокоить нервную систему за 1 минуту",
            icon: Icons.air_rounded,
            onTap: () => _showBreathingDialog(context),
          ),
          const SizedBox(height: 10),

          _buildWaterCard(colorScheme),

          const SizedBox(height: 10),

          _buildDistractionCard(colorScheme),

          const SizedBox(height: 10),

          _buildPopItCard(colorScheme),

          const SizedBox(height: 50),

          // КНОПКА ВОДЫ
          // _buildActionCard(
          //   colorScheme,
          //   title: "Выпить стакан воды",
          //   subtitle: "Иногда мозг путает жажду с голодом",
          //   icon: Icons.local_drink_rounded,
          //   onTap: () {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(
          //           content: Text('Отлично! Ты на шаг ближе к цели 💧')),
          //     );
          //     Navigator.pop(context); // Возвращаемся на главный экран
          //   },
          // ),
        ],
      ),
    );
  }

  // Внутри _MotivationPageState добавим переменную состояния
  bool _isDrinkingWater = false;

// Обновленный метод сборки карточки
  Widget _buildWaterCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: _isDrinkingWater
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _isDrinkingWater
                      ? colorScheme.primary
                      : colorScheme.secondaryContainer,
                  child: Icon(Icons.local_drink_rounded,
                      color: _isDrinkingWater
                          ? Colors.white
                          : colorScheme.onSecondaryContainer),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isDrinkingWater
                            ? "Пьешь воду прямо сейчас?"
                            : "Выпить стакан воды",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _isDrinkingWater
                            ? "Не спеши, делай маленькие глотки..."
                            : "Иногда мозг путает жажду с голодом",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!_isDrinkingWater)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton(
                  onPressed: () => setState(() => _isDrinkingWater = true),
                  child: const Text("Иду на кухню"),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Готово, стакан пуст!"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard(ColorScheme colorScheme) {
    return Card(
      color: colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Правило 15 минут",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Договорись с собой подождать совсем немного. Если через 15 минут желание останется — ты решишь, что делать.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _formatTime(_start),
              style: TextStyle(
                fontSize: 45,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: !_isTimerRunning
                  ? ElevatedButton(
                      onPressed: _startTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 50),
                      ),
                      child: const Text("Я подожду"),
                    )
                  : const Text("Просто дыши и отвлекись...",
                      style: TextStyle(fontStyle: FontStyle.italic)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(ColorScheme colorScheme,
      {required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }

  void _showBreathingDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => const BreathingExercise(),
    );
  }

  Widget _buildDistractionCard(ColorScheme colorScheme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Image.network(
            facts[_factIndex]['img']!,
            fit: BoxFit.cover,
            height: 200,
            width: double.infinity,

            // Что показывать, пока картинка скачивается
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child; // Если загружено, показываем картинку
              }
              return Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300], // Серый фон
                child: Center(
                  child: Icon(Icons.broken_image,
                      color: Colors.grey[600], size: 40),
                ),
              );
            },

            // Что показывать, если произошла ошибка (нет сети или плохая ссылка)
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: Center(
                  child: Icon(Icons.broken_image,
                      color: Colors.grey[600], size: 40),
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black54,
            width: double.infinity,
            child: Text(
              facts[_factIndex]['text']!,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              onPressed: () => setState(() {
                // _factIndex = (1 + _factIndex) % facts.length;
                _factIndex = Random().nextInt(facts.length);
              }),
              icon: const Icon(Icons.refresh),
            ),
          )
        ],
      ),
    );
  }

// 2. БЛОК: Мини-игра "Пузырьки" (Антистресс)
  Widget _buildPopItCard(ColorScheme colorScheme) {
    return Card(
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Просто лопай пузырьки",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(
                  12,
                  (index) => BubbleItem(
                        colorScheme: colorScheme,
                        onPop: _playPopSound,
                      )),
            ),
          ],
        ),
      ),
    );
  }
}
