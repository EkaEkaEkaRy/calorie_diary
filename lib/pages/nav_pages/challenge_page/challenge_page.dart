import 'dart:math';

import 'package:calorie_diary/database/data/challenges_list.dart';
import 'package:calorie_diary/models/challenge_model.dart';
import 'package:flutter/material.dart';

class TreeChallengePage extends StatefulWidget {
  const TreeChallengePage({super.key});

  @override
  State<TreeChallengePage> createState() => _TreeChallengePageState();
}

class _TreeChallengePageState extends State<TreeChallengePage> {
  // Имитируем сохраненные данные из SharedPreferences

  int currentStage = 1; // Основная стадия роста (1 - 10)
  int wiltSubStage = 0; // Подстадия увядания (0 - норма, 1 - n.1, 2 - n.2)
  int missedWeeks = 0; // Количество пропущенных недель подряд (0 - 4)

  Map<String, int> calculateNextTreeState({
    required int currentStage,
    required int wiltSubStage,
    required int missedWeeks,
    required bool isChallengePassed,
  }) {
    int nextStage = currentStage;
    int nextSubStage = 0; // По умолчанию при успехе всегда возвращаемся в норму
    int nextMissedWeeks = missedWeeks;

    if (isChallengePassed) {
      // === СЦЕНАРИЙ УСПЕХА ===
      nextMissedWeeks = 0; // Сбрасываем пропуски

      if (wiltSubStage == 0) {
        // Если дерево было в норме — обычный рост вверх (максимум до 10)
        if (currentStage < 10) {
          nextStage = currentStage + 1;
        }
      } else if (wiltSubStage == 1) {
        // Если было n.1 — просто возвращаемся на текущую стадию n
        nextStage = currentStage;
      } else if (wiltSubStage == 2) {
        // Если было n.2 — смотрим на порог стадии 5
        if (currentStage > 5) {
          nextStage = 5; // Откат к 5 стадии
        } else {
          nextStage = currentStage; // Возврат к n, если n <= 5
        }
      }
      nextSubStage = 0; // Возврат в нормальное состояние без увядания
    } else {
      // === СЦЕНАРИЙ ПРОПУСКА ===
      nextMissedWeeks++;

      if (currentStage == 1) {
        // На 1 стадии правил увядания нет, оно просто не растет
        nextStage = 1;
        nextSubStage = 0;
      } else {
        // Начиная со 2 стадии включаются твои правила
        if (nextMissedWeeks == 1) {
          nextStage = currentStage;
          nextSubStage = 0; // n (всё остается как есть)
        } else if (nextMissedWeeks == 2) {
          nextStage = currentStage;
          nextSubStage = 1; // n.1 (первое увядание)
        } else if (nextMissedWeeks == 3) {
          nextStage = currentStage;
          nextSubStage = 2; // n.2 (сильное увядание)
        } else if (nextMissedWeeks >= 4) {
          nextStage = 1; // Сброс на стадию 1
          nextSubStage = 0;
          nextMissedWeeks = 0; // Сбрасываем счетчик после полного обнуления
        }
      }
    }

    return {
      'currentStage': nextStage,
      'wiltSubStage': nextSubStage,
      'missedWeeks': nextMissedWeeks,
    };
  }

  String getTreeAssetPath(int stage, int subStage) {
    // На первой стадии подстадий n.1 и n.2 не существует
    if (stage == 1 || subStage == 0) {
      return 'assets/images/tree/stage$stage.png';
    }
    // Собирает строки вида: assets/images/tree/stage3.1.png
    return 'assets/images/tree/stage$stage.$subStage.png';
  }

  void _simulateWeekResult(bool challengeCompleted) {
    setState(() {
      // Вызываем нашу функцию расчета нового состояния
      final nextState = calculateNextTreeState(
        currentStage: currentStage,
        wiltSubStage: wiltSubStage,
        missedWeeks: missedWeeks,
        isChallengePassed: challengeCompleted,
      );

      // Присваиваем новые значения переменным экрана
      currentStage = nextState['currentStage']!;
      wiltSubStage = nextState['wiltSubStage']!;
      missedWeeks = nextState['missedWeeks']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Древо Стойкости',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ГЛАВНЫЙ БЛОК ДЕРЕВА
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                  // Динамический текст статуса
                  Text(
                    wiltSubStage == 0
                        ? "Стадия роста: $currentStage из 10"
                        : "Дерево увядает!",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: wiltSubStage == 0
                            ? colorScheme.primary
                            : colorScheme.error),
                  ),
                  const SizedBox(height: 20),

                  // Отображение ТВОЕЙ сгенерированной картинки
                  Image.asset(
                    getTreeAssetPath(currentStage, wiltSubStage),
                    height: 200,
                    fit: BoxFit.contain,
                    // Заглушка на случай, если картинка не найдется в ассетах
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image, size: 100),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildWeeklyChallengeCard(colorScheme,
                challenge:
                    allChallenges[Random().nextInt(allChallenges.length)]),

            // БЛОК ТЕСТИРОВАНИЯ (Кнопки для проверки твоей теории)
            Card(
              color: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("Симулятор недель (для теста логики):",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _simulateWeekResult(true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white),
                            child: const Text("Успешная неделя"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _simulateWeekResult(false),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: Colors.white),
                            child: const Text("Пропуск недели"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChallengeCard(ColorScheme colorScheme,
      {required ChallengeModel challenge}) {
    // Список дней недели для трекера
    final List<String> weekDays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"];

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ВЕРХНЯЯ ЧАСТЬ: Иконка и описание челленджа
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer, // Твой FFFECB3
                child: Icon(challenge.icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ЧЕЛЛЕНДЖ ЭТОЙ НЕДЕЛИ",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            challenge.description,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),

          // РАЗДЕЛИТЕЛЬНАЯ ЛИНИЯ ВНУТРИ КАРТОЧКИ
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
                thickness: 1),
          ),

          // НИЖНЯЯ ЧАСТЬ: Сетка из 7 капель-дней
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              // Имитируем, что Пн и Вт закрашены, остальные пока пустые (для теста)
              // В будущем здесь будет проверка: _weeklyWaterStatus[index]
              bool isWatered = index < 2;

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isWatered
                          ? colorScheme
                              .secondaryContainer // Твой янтарный FFFECB3
                          : colorScheme
                              .surfaceContainer, // Белый фон карточки для контраста
                      borderRadius: BorderRadius.circular(12),
                      border: isWatered
                          ? Border.all(color: colorScheme.secondary, width: 1.5)
                          : Border.all(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.1),
                              width: 1),
                    ),
                    child: Icon(
                      Icons.water_drop_rounded,
                      size: 20,
                      color: isWatered
                          ? colorScheme.primary // Твой зеленый 4CAF50
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    weekDays[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: isWatered
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isWatered ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
