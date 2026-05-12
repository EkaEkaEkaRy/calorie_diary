import 'dart:io';

import 'package:calorie_diary/models/memory_item_model.dart';
import 'package:calorie_diary/pages/full_screen_image_page.dart';
import 'package:calorie_diary/pages/nav_pages/memory_page/components/create_category_form.dart';
import 'package:calorie_diary/pages/nav_pages/memory_page/memory_page.dart';
import 'package:flutter/material.dart';

Widget buildMemoryCard(BuildContext context, MemoryItemModel item, double width,
    VoidCallback onCategoryCreated) {
  final colorScheme = Theme.of(context).colorScheme;
  final currentCategories = memoryLinks[item.id] ?? [];

  return GestureDetector(
    onLongPress: () => showCategoryPicker(context, item.id, onCategoryCreated),
    child: Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        // Добавляем границу, чтобы карточка не сливалась с фоном
        border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Позволяет колонке сжиматься/расти
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FullscreenImageScreen(imagePath: item.image),
                      ),
                    );
                  },
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.file(File(item.image), fit: BoxFit.cover),
                  ),
                ),
                if (currentCategories.isNotEmpty || item.text != "")
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentCategories.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            children: currentCategories
                                .map((cat) => Container(
                                      margin: EdgeInsets.symmetric(vertical: 1),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: cat.color.withValues(
                                            alpha:
                                                0.2), // Прозрачный фон цвета категории
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: cat.color.withValues(
                                                alpha:
                                                    0.5)), // Контур цвета категории
                                      ),
                                      child: Text(
                                        "#${cat.name}",
                                        style: TextStyle(
                                            color: cat.color,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ))
                                .toList(),
                          ),
                        // ТЕГ КАТЕГОРИИ (если есть)
                        if (item.text != "" && item.text != null)
                          Text(
                            item.text!,
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface,
                                height: 1.2),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
