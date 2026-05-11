import 'dart:io';
import 'package:calorie_diary/models/db_helper.dart';
import 'package:calorie_diary/models/memory_item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';

class TestMemoryItem {
  final String id;
  final String imagePath; // здесь будет путь к файлу из БД
  final String date;
  final String? category;
  final String text;

  TestMemoryItem({
    required this.id,
    required this.imagePath,
    required this.date,
    this.category,
    required this.text,
  });
}

class CategoryModel {
  final String name;
  final Color color;

  CategoryModel({required this.name, required this.color});
}

class MemoryGroupTestPage extends StatefulWidget {
  const MemoryGroupTestPage({super.key});

  @override
  State<MemoryGroupTestPage> createState() => _MemoryGroupTestPageState();
}

class _MemoryGroupTestPageState extends State<MemoryGroupTestPage> {
  Future<List<TestMemoryItem>>? _eventsFuture;
// 1. Доступные категории с цветами
  final List<CategoryModel> _availableCategories = [
    CategoryModel(name: 'День рождения', color: Colors.orange),
    CategoryModel(name: 'Путешествие', color: Colors.blue),
  ];

// 2. Хранилище связей (ID карточки -> Список объектов категорий)
  final Map<String, List<CategoryModel>> _memoryLinks = {};

// Метод для "привязки"
  void _toggleCategory(String memoryId, CategoryModel category) {
    // Принимаем объект
    setState(() {
      _memoryLinks.putIfAbsent(memoryId, () => []);

      // Теперь сравнение объектов будет работать корректно
      if (_memoryLinks[memoryId]!.contains(category)) {
        _memoryLinks[memoryId]!.remove(category);
      } else {
        _memoryLinks[memoryId]!.add(category);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadData();
  }

  Future<List<TestMemoryItem>> _loadData() async {
    // Получаем оригинальные модели из БД
    final List<Map<String, dynamic>> maps =
        await DatabaseHelper.instance.getAllMemories();
    final List<MemoryItemModel> allEvents =
        maps.map((map) => MemoryItemModel.fromMap(map)).toList();

    // Преобразуем их в тестовые модели
    return allEvents.map((event) {
      // ВРЕМЕННАЯ ЛОГИКА: для теста принудительно назначаем категории некоторым элементам
      // В будущем это поле будет браться напрямую из event.category
      String? testCategory;

      return TestMemoryItem(
        id: event.id.toString(),
        imagePath: event.image, // Путь к файлу
        date: event.date,
        category:
            testCategory, // Пока назначаем искусственно для проверки группировки
        text: event.text ?? "",
      );
    }).toList();
  }

  Color _tempSelectedColor = Colors.green; // Цвет по умолчанию в диалоге

  void _showCreateCategoryDialog() {
    TextEditingController controller = TextEditingController();

    showDialog(
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
                  decoration:
                      const InputDecoration(hintText: 'Название категории'),
                ),
                const SizedBox(height: 20),
                const Text('Выберите цвет:', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 10),

                // ПОЛНАЯ ПАЛИТРА
                ColorPicker(
                  pickerColor: _tempSelectedColor,
                  onColorChanged: (color) {
                    setDialogState(() => _tempSelectedColor = color);
                  },
                  pickerAreaHeightPercent: 0.7,
                  enableAlpha: false, // Прозрачность нам обычно не нужна
                  displayThumbColor: true,
                  labelTypes: [], // Убираем скучные цифры/коды цветов
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _availableCategories.add(
                      CategoryModel(
                          name: controller.text, color: _tempSelectedColor),
                    );
                  });
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

  void _showCategoryPicker(String memoryId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        // Чтобы чекбоксы обновлялись внутри шторки
        builder: (context, setModalState) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Выберите категории',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(
                children: _availableCategories.map((cat) {
                  // Проверяем наличие объекта в списке для этой карточки
                  bool isSelected =
                      _memoryLinks[memoryId]?.contains(cat) ?? false;

                  return CheckboxListTile(
                    title: Text(cat.name), // Берем имя из объекта
                    secondary: CircleAvatar(
                        radius: 8,
                        backgroundColor: cat.color), // Показываем цвет в списке
                    value: isSelected,
                    onChanged: (bool? value) {
                      _toggleCategory(memoryId, cat); // Передаем объект целиком
                      setModalState(() {});
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Твой F1F8E9
      appBar: AppBar(
        title: const Text('Воспоминания',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => _showCreateCategoryDialog(),
          )
        ],
      ),
      body: FutureBuilder<List<TestMemoryItem>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final memories = snapshot.data ?? [];
          if (memories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Группируем данные по дате для создания заголовков
          Map<String, List<TestMemoryItem>> groupedByDate = {};
          for (var item in memories) {
            groupedByDate.putIfAbsent(item.date, () => []).add(item);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
            itemCount: groupedByDate.keys.length,
            itemBuilder: (context, index) {
              String date = groupedByDate.keys.elementAt(index);
              List<TestMemoryItem> itemsForDate = groupedByDate[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // КРУПНЫЙ ЗАГОЛОВОК ДАТЫ
                  _buildDateHeader(context, date, colorScheme),

                  // СЕТКА ИЗОБРАЖЕНИЙ ЗА ЭТУ ДАТУ
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: itemsForDate.map((item) {
                      double width =
                          (MediaQuery.of(context).size.width - 44) / 2;
                      return _buildMemoryCard(context, item, width);
                    }).toList(),
                  ),
                  const SizedBox(height: 15),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(
      BuildContext context, String dateString, ColorScheme colorScheme) {
    DateTime date = DateTime.parse(dateString);
    DateTime now = DateTime.now();

    // Логика "Сегодня/Вчера" для уюта
    String displayDate;
    if (DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(now)) {
      displayDate = "Сегодня";
    } else if (DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd')
            .format(now.subtract(const Duration(days: 1)))) {
      displayDate = "Вчера";
    } else {
      displayDate = DateFormat('dd.MM.yyyy').format(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer, // Янтарный из схемы
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              displayDate,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSecondaryContainer,
                fontSize: 14,
              ),
            ),
          ),
          const Expanded(
              child: Divider(indent: 10, endIndent: 10, thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(
      BuildContext context, TestMemoryItem item, double width) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentCategories = _memoryLinks[item.id] ?? [];

    return GestureDetector(
      onLongPress: () => _showCategoryPicker(item.id),
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
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.file(File(item.imagePath), fit: BoxFit.cover),
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
                                        margin:
                                            EdgeInsets.symmetric(vertical: 1),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: cat.color.withValues(
                                              alpha:
                                                  0.2), // Прозрачный фон цвета категории
                                          borderRadius:
                                              BorderRadius.circular(6),
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
                          if (item.text != "")
                            Text(
                              item.text,
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
}
