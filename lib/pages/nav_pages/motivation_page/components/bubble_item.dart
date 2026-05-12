// Вспомогательный виджет для пузырька
import 'dart:math';
import 'package:calorie_diary/database/data/icons_list.dart';
import 'package:flutter/material.dart';

class BubbleItem extends StatefulWidget {
  final ColorScheme colorScheme;
  final VoidCallback onPop;
  const BubbleItem({super.key, required this.colorScheme, required this.onPop});

  @override
  State<BubbleItem> createState() => _BubbleItemState();
}

class _BubbleItemState extends State<BubbleItem> {
  bool _isPopped = true;
  late IconData _randomIcon;

  @override
  void initState() {
    super.initState();
    // Выбираем иконку один раз при создании пузырька
    _randomIcon = _getRandomIcon();
  }

  IconData _getRandomIcon() {
    return icons[Random().nextInt(icons.length)];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_isPopped) {
          widget.onPop();
        }

        setState(() => _isPopped = !_isPopped);
        // Для тактильного отклика:
        // HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: _isPopped
              ? widget.colorScheme.primary
              : widget.colorScheme.primaryContainer.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          boxShadow: _isPopped
              ? []
              : [
                  const BoxShadow(
                      blurRadius: 2,
                      offset: Offset(0, 2),
                      color: Colors.black12)
                ],
        ),
        child: _isPopped
            ? TweenAnimationBuilder<double>(
                // Добавим микро-анимацию появления иконки
                duration: const Duration(milliseconds: 200),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: Icon(_randomIcon, size: 20, color: Colors.white),
                ),
              )
            : null,
      ),
    );
  }
}
