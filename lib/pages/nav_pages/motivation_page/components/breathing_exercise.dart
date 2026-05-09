// Мини-виджет упражнения
import 'package:flutter/material.dart';

class BreathingExercise extends StatefulWidget {
  const BreathingExercise({super.key});

  @override
  State<BreathingExercise> createState() => _BreathingExerciseState();
}

class _BreathingExerciseState extends State<BreathingExercise>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);
    _sizeAnimation = Tween<double>(begin: 100, end: 200)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text("Вдох — Выдох",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          AnimatedBuilder(
            animation: _sizeAnimation,
            builder: (context, child) => Container(
              width: _sizeAnimation.value,
              height: _sizeAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withValues(alpha: 0.3),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Center(
                  child: Text(_controller.status == AnimationStatus.forward
                      ? "Вдох"
                      : "Выдох")),
            ),
          ),
          const Spacer(),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Мне стало легче")),
        ],
      ),
    );
  }
}
