import 'package:calorie_diary/models/category_item.dart';
import 'package:calorie_diary/database/db_helper.dart';
import 'package:calorie_diary/pages/nav_pages/memory_page/memory_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

Color _tempSelectedColor = Colors.green; // Цвет по умолчанию в диалоге

Future<void> _showCreateCategoryDialog(
    BuildContext context, VoidCallback onCategoryCreated) async {
  TextEditingController controller = TextEditingController();
  // Сбрасываем временный цвет перед открытием
  _tempSelectedColor = Colors.green;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Новая категория'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Название'),
              ),
              const SizedBox(height: 20),
              ColorPicker(
                pickerColor: _tempSelectedColor,
                onColorChanged: (color) =>
                    setDialogState(() => _tempSelectedColor = color),
                enableAlpha: false,
                labelTypes: [],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                // 1. Сохраняем в БД
                final int newId = await DatabaseHelper.instance.insertCategory(
                    controller.text, _tempSelectedColor.toARGB32());

                // 2. Добавляем в локальный список уже с реальным ID
                availableCategories.add(CategoryModel(
                    id: newId,
                    name: controller.text,
                    color: _tempSelectedColor));

                onCategoryCreated();
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    ),
  );
}

void showCategoryPicker(
    BuildContext context, int memoryId, VoidCallback onCategoryCreated) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Категории',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.5,
                ),
                // Список категорий + 1 кнопка "Плюс"
                itemCount: availableCategories.length + 1,
                itemBuilder: (context, index) {
                  if (index == availableCategories.length) {
                    // Кнопка добавления новой категории
                    return GestureDetector(
                      onTap: () async {
                        await _showCreateCategoryDialog(
                            context, onCategoryCreated);
                        setModalState(() {}); // Обновляем сетку в шторке
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add, color: Colors.grey),
                      ),
                    );
                  }

                  final cat = availableCategories[index];
                  bool isSelected =
                      memoryLinks[memoryId]?.any((item) => item.id == cat.id) ??
                          false;

                  return GestureDetector(
                    onTap: () async {
                      await _toggleCategory(memoryId, cat, onCategoryCreated);
                      setModalState(() {});
                    },
                    onLongPress: () => _showEditCategoryDialog(
                        context, cat, setModalState, onCategoryCreated),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cat.color,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: colorScheme.onSurface, width: 2)
                            : null,
                      ),
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          color: cat.color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    ),
  );
}

void _showEditCategoryDialog(BuildContext context, CategoryModel cat,
    Function setModalState, VoidCallback onCategoryCreated) {
  TextEditingController controller = TextEditingController(text: cat.name);
  _tempSelectedColor = cat.color;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Редактировать категорию'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller),
              const SizedBox(height: 20),
              ColorPicker(
                pickerColor: _tempSelectedColor,
                onColorChanged: (color) =>
                    setDialogState(() => _tempSelectedColor = color),
                enableAlpha: false,
                labelTypes: [],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Удаляем из БД
              await DatabaseHelper.instance.deleteCategory(cat.id);

              // Чистим локальные списки
              availableCategories.removeWhere((c) => c.id == cat.id);
              for (var list in memoryLinks.values) {
                list.removeWhere((c) => c.id == cat.id);
              }

              onCategoryCreated();
              if (!context.mounted) return;
              Navigator.pop(context);
              setModalState(() {});
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Обновляем в БД
              await DatabaseHelper.instance.updateCategory(
                  cat.id, controller.text, _tempSelectedColor.toARGB32());

              // Обновляем локально
              int index = availableCategories.indexWhere((c) => c.id == cat.id);
              if (index != -1) {
                final updatedCat = CategoryModel(
                    id: cat.id,
                    name: controller.text,
                    color: _tempSelectedColor);
                availableCategories[index] = updatedCat;

                // Обновляем во всех связях
                for (var list in memoryLinks.values) {
                  int linkIndex = list.indexWhere((c) => c.id == cat.id);
                  if (linkIndex != -1) list[linkIndex] = updatedCat;
                }
              }

              onCategoryCreated();
              if (!context.mounted) return;
              Navigator.pop(context);
              setModalState(() {});
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    ),
  );
}

// Метод для "привязки"
Future<void> _toggleCategory(int memoryId, CategoryModel category,
    VoidCallback onCategoryCreated) async {
  // 1. Работаем с БД
  await DatabaseHelper.instance.toggleLink(memoryId, category.id);

  // 2. Обновляем локальный Map для мгновенного UI-отклика
  memoryLinks.putIfAbsent(memoryId, () => []);
  final list = memoryLinks[memoryId]!;
  bool exists = list.any((c) => c.id == category.id);

  if (exists) {
    list.removeWhere((c) => c.id == category.id);
  } else {
    list.add(category);
  }

  onCategoryCreated();
}
