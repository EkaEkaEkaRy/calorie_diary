enum Gender { male, female }

enum Goal { lose, maintain, gain }

class CalorieCalculator {
  static double calculate({
    required Gender gender,
    required double weight,
    required double height,
    required int age,
    required double activityFactor,
    required Goal goal, // Добавляем цель
  }) {
    double bmr = (10 * weight) + (6.25 * height) - (5 * age);
    bmr = (gender == Gender.male) ? bmr + 5 : bmr - 161;
    double maintenance = bmr * activityFactor;

    switch (goal) {
      case Goal.lose:
        return maintenance * 0.85; // Дефицит 15%
      case Goal.gain:
        return maintenance * 1.15; // Профицит 15%
      case Goal.maintain:
        return maintenance;
    }
  }
}
