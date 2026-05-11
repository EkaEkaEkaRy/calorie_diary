import 'dart:io';
import 'package:calorie_diary/models/db_helper.dart';
import 'package:calorie_diary/models/memory_item_model.dart';
import 'package:calorie_diary/pages/full_screen_image_page.dart';
import 'package:flutter/material.dart';

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
    _eventsFuture = _loadAllEventsText();
  }

  Future<List<MemoryItemModel>> _loadAllEventsText() async {
    final allEvents = await DatabaseHelper.instance.getAllMemories();
    return allEvents.map((map) => MemoryItemModel.fromMap(map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Воспоминания',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<MemoryItemModel>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final memories = snapshot.data ?? [];
          if (memories.isEmpty) return _buildEmptyState(colorScheme);

          // Используем CustomScrollView для контроля отступов и гибкой сетки
          return ListView(
            padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 100 // РЕШЕНИЕ ПРОБЛЕМЫ №1: Отступ под высоту навигации
                ),
            children: [
              // Используем Wrap вместо GridView для РЕШЕНИЯ ПРОБЛЕМЫ №2
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: memories.map((item) {
                  // Вычисляем ширину для 2-х колонок
                  double width = (MediaQuery.of(context).size.width - 48) / 2;
                  return SizedBox(
                    width: width,
                    child: _buildMemoryCard(context, item),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMemoryCard(BuildContext context, MemoryItemModel item) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Позволяет колонке сжиматься/расти
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Фото фиксированной высоты
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
                aspectRatio: 1, // Квадратное фото
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(item.image), fit: BoxFit.cover),
                    _buildDateOverlay(item.date),
                  ],
                ),
              ),
            ),
            // Текстовый блок, который РАСТЕТ вместе с текстом
            if (item.text != "" && item.text != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  item.text ?? "",
                  // Убираем maxLines, чтобы текст отображался полностью
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateOverlay(String date) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
          ),
        ),
        child: Text(
          date,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 80, color: colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Здесь будет твоя история блюд',
              style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
