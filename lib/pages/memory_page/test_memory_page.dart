import 'package:calorie_diary/models/category_item.dart';
import 'package:calorie_diary/models/db_helper.dart';
import 'package:calorie_diary/models/memory_item_model.dart';
import 'package:calorie_diary/pages/memory_page/components/memory_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final Map<int, List<CategoryModel>> memoryLinks = {};
final List<CategoryModel> availableCategories = [];

class MemoryGroupTestPage extends StatefulWidget {
  const MemoryGroupTestPage({super.key});

  @override
  State<MemoryGroupTestPage> createState() => _MemoryGroupTestPageState();
}

class _MemoryGroupTestPageState extends State<MemoryGroupTestPage> {
  Future<List<MemoryItemModel>>? _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadData();
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
      ),
      body: FutureBuilder<List<MemoryItemModel>>(
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
          Map<String, List<MemoryItemModel>> groupedByDate = {};
          for (var item in memories) {
            groupedByDate.putIfAbsent(item.date, () => []).add(item);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
            itemCount: groupedByDate.keys.length,
            itemBuilder: (context, index) {
              String date = groupedByDate.keys.elementAt(index);
              List<MemoryItemModel> itemsForDate = groupedByDate[date]!;

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
                      return buildMemoryCard(
                          context, item, width, () => setState(() {}));
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
}
