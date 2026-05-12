import 'package:calorie_diary/models/category_item.dart';
import 'package:calorie_diary/pages/memory_page/test_memory_page.dart';
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
            onPressed: () {
              if (controller.text.isNotEmpty) {
                availableCategories.add(CategoryModel(
                    name: controller.text, color: _tempSelectedColor));
                onCategoryCreated();
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
                      memoryLinks[memoryId]?.contains(cat) ?? false;

                  return GestureDetector(
                    onTap: () {
                      _toggleCategory(memoryId, cat, onCategoryCreated);
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
            onPressed: () {
              availableCategories.remove(cat);
              // Удаляем связи этой категории у всех карточек
              for (var list in memoryLinks.values) {
                list.remove(cat);
              }
              onCategoryCreated();
              Navigator.pop(context);
              setModalState(() {});
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              int index = availableCategories.indexOf(cat);
              availableCategories[index] = CategoryModel(
                  name: controller.text, color: _tempSelectedColor);

              // Обновляем категорию во всех связях, чтобы цвет/имя поменялись везде
              for (var list in memoryLinks.values) {
                if (list.contains(cat)) {
                  int i = list.indexOf(cat);
                  list[i] = availableCategories[index];
                }
              }
              onCategoryCreated();
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
void _toggleCategory(
    int memoryId, CategoryModel category, VoidCallback onCategoryCreated) {
  memoryLinks.putIfAbsent(memoryId, () => []);

  // Теперь сравнение объектов будет работать корректно
  if (memoryLinks[memoryId]!.contains(category)) {
    memoryLinks[memoryId]!.remove(category);
  } else {
    memoryLinks[memoryId]!.add(category);
  }
  onCategoryCreated();
}
