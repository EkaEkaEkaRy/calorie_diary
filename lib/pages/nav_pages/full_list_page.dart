import 'package:calorie_diary/models/db_helper.dart';
import 'package:flutter/material.dart';

class FullListPage extends StatefulWidget {
  const FullListPage({super.key});

  @override
  State<FullListPage> createState() => _FullListPageState();
}

class _FullListPageState extends State<FullListPage> {
  Future<List<String>>? _eventsFuture;
  List<String> _allEventsTexts = [];
  List<String> _filteredEventsTexts = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadAllEventsText();
    _searchController.addListener(_onSearchChanged);
  }

  Future<List<String>> _loadAllEventsText() async {
    final allEvents = await DatabaseHelper.instance.getAllEvents();
    return allEvents
        .map<String>((e) => e['text'] as String? ?? 'Без описания')
        .toList();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEventsTexts = _allEventsTexts
          .where((text) => text.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: FutureBuilder<List<String>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Ошибка загрузки данных: ${snapshot.error}'));
          } else {
            if (_allEventsTexts.isEmpty) {
              // Сохраняем данные при первом успешном получении
              _allEventsTexts = snapshot.data ?? [];
              _filteredEventsTexts = List.from(_allEventsTexts);
            }

            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Поиск записей',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredEventsTexts.isEmpty
                      ? const Center(child: Text('Записей не найдено'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              16, 8, 16, 50), // Отступ снизу
                          itemCount: _filteredEventsTexts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final text = _filteredEventsTexts[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  text,
                                  style: const TextStyle(fontSize: 16),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
