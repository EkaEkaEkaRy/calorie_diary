import 'package:flutter/material.dart';

enum ChallengeType {
  cleanMind, // Неделя без алкоголя
  rainbowPlate, // Фрукты и овощи
  cleanEvening, // Без ночных перекусов
  inBullseye, // Удержание нормы калорий
  honestDiary, // Честный дневник (3 приема пищи)
  sugarDetox, // Сахарный детокс
  homeKitchen, // Домашняя кухня (Без фастфуда)
  lightEvening, // Легкий вечер (Ужин <= 30%)
}

class ChallengeModel {
  final int id;
  final String title;
  final String description;
  final IconData icon;
  final ChallengeType type; // Какое действие/проверку запускать

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
  });
}
