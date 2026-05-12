import 'package:calorie_diary/models/category_item.dart';
import 'package:calorie_diary/database/db_helper.dart';
import 'package:calorie_diary/models/memory_item_model.dart';
import 'package:calorie_diary/pages/nav_pages/memory_page/components/memory_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final Map<int, List<CategoryModel>> memoryLinks = {};
final List<CategoryModel> availableCategories = [];

class MemoryListPage extends StatefulWidget {
  const MemoryListPage({super.key});

  @override
  State<MemoryListPage> createState() => _MemoryListPageState();
}

class _MemoryListPageState extends State<MemoryListPage> {
  Future<List<MemoryItemModel>>? _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadData();
    _initAppData();
  }

  Future<void> _initAppData() async {
    final db = DatabaseHelper.instance;

    // Загружаем данные из таблиц
    final categoriesFromDb = await db.getAllCategories();
    final linksFromDb = await db.getAllMemoryLinks();

    setState(() {
      availableCategories.clear();
      availableCategories.addAll(categoriesFromDb);

      memoryLinks.clear();
      memoryLinks.addAll(linksFromDb);
    });
  }

  Future<List<MemoryItemModel>> _loadData() async {
    // Получаем оригинальные модели из БД
    final List<Map<String, dynamic>> maps =
        await DatabaseHelper.instance.getAllMemories();
    final List<MemoryItemModel> allEvents =
        maps.map((map) => MemoryItemModel.fromMap(map)).toList();

    // Преобразуем их в тестовые модели
    return allEvents;
  }

  // 1. Добавь эту переменную в состояние твоего класса _MemoryGroupTestPageState:
  CategoryModel? _activeFilter; // null означает "Показать все"
  bool _isSelectedNoneCategory = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Воспоминания',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          // ПОДСКАЗКА: Иконка информации о жестах
          IconButton(
            icon: Icon(Icons.info_outline, color: colorScheme.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  content: Text(
                    'Подсказка: зажми карточку на 2 секунды, чтобы добавить ей категорию!',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.surfaceContainer),
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<MemoryItemModel>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var memories = snapshot.data ?? [];
          if (memories.isEmpty) {
            return const Center(child: Text('Записей не найдено'));
          }

          // Логика фильтрации: если фильтр выбран, оставляем только те воспоминания,
          // чей ID есть в memoryLinks со ссылкой на выбранную категорию
          if (_activeFilter != null) {
            memories = memories.where((item) {
              final links = memoryLinks[item.id] ?? [];
              return links.any((cat) => cat.id == _activeFilter!.id);
            }).toList();
          }
          if (_activeFilter == null && _isSelectedNoneCategory) {
            memories = memories.where((item) {
              final links = memoryLinks[item.id] ?? [];
              return links.isEmpty;
            }).toList();
          }

          // Группируем отфильтрованные данные по дате
          Map<String, List<MemoryItemModel>> groupedByDate = {};
          for (var item in memories) {
            groupedByDate.putIfAbsent(item.date, () => []).add(item);
          }

          return Column(
            children: [
              // ЛЕНТА ФИЛЬТРОВ (Горизонтальный скролл)
              if (availableCategories.isNotEmpty) _buildFilterBar(colorScheme),

              // ОСНОВНОЙ СПИСОК
              Expanded(
                child: groupedByDate.isEmpty
                    ? const Center(child: Text('Нет записей в этой категории'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 100),
                        itemCount: groupedByDate.keys.length,
                        itemBuilder: (context, index) {
                          String date = groupedByDate.keys.elementAt(index);
                          List<MemoryItemModel> itemsForDate =
                              groupedByDate[date]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDateHeader(context, date, colorScheme),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: itemsForDate.map((item) {
                                  double width =
                                      (MediaQuery.of(context).size.width - 44) /
                                          2;
                                  return buildMemoryCard(context, item, width,
                                      () => setState(() {}));
                                }).toList(),
                              ),
                              const SizedBox(height: 15),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

// Виджет горизонтальной ленты фильтров
  Widget _buildFilterBar(ColorScheme colorScheme) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: availableCategories.length + 2, // +1 для кнопки "Все"
        itemBuilder: (context, index) {
          if (index == 0) {
            // Кнопка сброса фильтра "Все"
            final bool isAllSelected =
                _activeFilter == null && !_isSelectedNoneCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: const Text('Все'),
                selected: isAllSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _activeFilter = null;
                      _isSelectedNoneCategory = false;
                    });
                  }
                },
              ),
            );
          }

          if (index == availableCategories.length + 1) {
            final bool isSelected =
                _activeFilter == null && _isSelectedNoneCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: const Text('Без тега'),
                selected: isSelected,
                selectedColor: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.3),
                checkmarkColor: Theme.of(context).colorScheme.onSurfaceVariant,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _activeFilter = null;
                      _isSelectedNoneCategory = true;
                    });
                  }
                },
              ),
            );
          }

          final cat = availableCategories[index - 1];
          final bool isSelected = _activeFilter?.id == cat.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text('#${cat.name}'),
              selected: isSelected,
              selectedColor: cat.color.withValues(alpha: 0.3),
              checkmarkColor: cat.color,
              labelStyle: TextStyle(
                color: isSelected ? cat.color : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                setState(() {
                  _activeFilter = selected ? cat : null;
                  _isSelectedNoneCategory = false;
                });
              },
            ),
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
}
