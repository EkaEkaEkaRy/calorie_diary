import 'package:calorie_diary/models/calorie_calculator_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalorieTestPage extends StatefulWidget {
  const CalorieTestPage({super.key});

  @override
  State<CalorieTestPage> createState() => _CalorieTestPageState();
}

class _CalorieTestPageState extends State<CalorieTestPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6; // Теперь 6 шагов

  // Данные для расчета
  Gender? _gender;
  double _weight = 0;
  double _height = 0;
  int _age = 0;
  double _activityFactor = 1.2;
  Goal? _selectedGoal; // Новое поле

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.onSurface;
    final activeBlue = Theme.of(context).colorScheme.primary; // Тот самый синий
    final disabledGrey = Theme.of(
      context,
    ).colorScheme.secondary.withValues(alpha: 0.5); // Тусклый до выбора

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Тест: Норма калорий",
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(activeBlue),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentStep = i),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildGenderStep(),
                _buildInputStep(
                  "Ваш вес",
                  "кг",
                  (v) => _weight = v.toDouble(),
                ),
                _buildInputStep(
                  "Ваш рост",
                  "см",
                  (v) => _height = v.toDouble(),
                ),
                _buildInputStep(
                  "Ваш возраст",
                  "лет",
                  (v) => _age = v.toInt(),
                ),
                _buildActivityStep(),
                _buildGoalStep(), // Наш новый 6-й шаг
              ],
            ),
          ),

          // Нижний блок с кнопками
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              children: [
                _buildMainButton(activeBlue, disabledGrey),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease,
                    ),
                    child: Text(
                      "Назад",
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ваша цель",
          ),
          const SizedBox(height: 32),
          _buildGoalOption("Похудение", Goal.lose),
          const SizedBox(height: 12),
          _buildGoalOption(
            "Поддержание веса",
            Goal.maintain,
          ),
          const SizedBox(height: 12),
          _buildGoalOption("Набор массы", Goal.gain),
        ],
      ),
    );
  }

  Widget _buildGoalOption(String title, Goal goal) {
    final isSelected = _selectedGoal == goal;
    return InkWell(
      onTap: () => setState(() => _selectedGoal = goal),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              title,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton(Color activeColor, Color disabledColor) {
    // Проверка: можно ли идти дальше на текущем шаге
    bool canProceed = false;

    switch (_currentStep) {
      case 0: // Пол
        canProceed = _gender != null;
        break;
      case 1: // Вес
        canProceed = _weight > 0.0;
        break;
      case 2: // Рост
        canProceed = _height > 0.0;
        break;
      case 3: // Возраст
        canProceed = _age > 0;
        break;
      case 4: // Активность
        // Если у _activityFactor есть значение по умолчанию (например, 1.2),
        // то здесь всегда будет true.
        canProceed = _activityFactor > 0;
        break;
      case 5: // Цель
        canProceed = _selectedGoal != null;
        break;
    }

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: canProceed ? _handleNext : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canProceed ? activeColor : disabledColor, // Смена цвета
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          _currentStep == _totalSteps - 1 ? "Рассчитать  >" : "Далее  >",
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    );
  }

  void _handleNext() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      _finishTest();
    }
  }

  void _finishTest() async {
    final result = CalorieCalculator.calculate(
      gender: _gender!,
      weight: _weight,
      height: _height,
      age: _age,
      activityFactor: _activityFactor,
      goal: _selectedGoal!,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_calorie_norm', result.toInt());
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildProgressBar(Color activeColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              _totalSteps,
              (index) => Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? activeColor
                        : Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text("Вопрос ${_currentStep + 1} из $_totalSteps"),
        ],
      ),
    );
  }

  Widget _buildGenderStep() {
    return _buildStepLayout(
      title: "Ваш пол",
      child: Column(
        children: [
          _buildRadioOption(
            "Мужской",
            Gender.male,
            _gender,
            (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 12),
          _buildRadioOption(
            "Женский",
            Gender.female,
            _gender,
            (v) => setState(() => _gender = v),
          ),
        ],
      ),
    );
  }

  // Универсальный виджет для ввода чисел (Вес, Рост, Возраст)
  Widget _buildInputStep(
    String title,
    String unit,
    Function(double) onChanged,
  ) {
    return _buildStepLayout(
      title: title,
      child: TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          suffixText: unit,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainer,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          // Добавим focusColor для красоты, когда поле активно
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        onChanged: (v) {
          // Оберните вызов функции в setState!
          setState(() {
            onChanged(double.tryParse(v) ?? 0.0);
          });
        },
      ),
    );
  }

  Widget _buildStepLayout({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildRadioOption<T>(
    String label,
    T value,
    T? groupValue,
    Function(T) onChanged,
  ) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              label,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStep() {
    final factors = {
      "Минимальная": 1.2,
      "Слабая (1-3 раза в неделю)": 1.375,
      "Средняя (3-5 раз в неделю)": 1.55,
      "Высокая (6-7 раз в неделю)": 1.725,
    };
    return _buildStepLayout(
      title: "Активность",
      child: Column(
        children: factors.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRadioOption(
                  e.key,
                  e.value,
                  _activityFactor,
                  (v) => setState(() => _activityFactor = v),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
