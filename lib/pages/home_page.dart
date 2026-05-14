import 'dart:io';
import 'package:calorie_diary/database/db_helper.dart';
import 'package:calorie_diary/pages/diary_page.dart';
import 'package:calorie_diary/widgets/bottom_swipe_menu.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Map<String, dynamic>> _events = [];

  // Для удобства создадим Map<DateTime, List> для событий
  Map<DateTime, List<Map<String, dynamic>>> _eventsMap = {};
  Map<DateTime, List<Map<String, dynamic>>> _alcoholEventsMap = {};
  int? _dailyCalorieNorm;

  @override
  void initState() {
    super.initState();
    _loadEventsForDay(_selectedDay);
    _loadEventsForMonth(_focusedDay);
    _loadCalorieNorm();
  }

  Future<void> _loadCalorieNorm() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyCalorieNorm = prefs.getInt('daily_calorie_norm');
    });
  }

  Future<void> _loadEventsForDay(DateTime day) async {
    final dateString = DateFormat('yyyy-MM-dd').format(day);
    final events = await DatabaseHelper.instance.getEventsByDate(dateString);
    setState(() {
      _events = events.where((e) => e['type'] != 'Алкоголь').toList();
    });
  }

  Future<void> _loadEventsForMonth(DateTime focusedDay) async {
    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDayOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);

    final allEvents = await DatabaseHelper.instance
        .getEventsBetweenDates(firstDayOfMonth, lastDayOfMonth);

    Map<DateTime, List<Map<String, dynamic>>> normalMap = {};
    Map<DateTime, List<Map<String, dynamic>>> alcoholMap = {};

    for (var event in allEvents) {
      DateTime eventDate = DateTime.parse(event['date']);
      final dayKey = DateTime(eventDate.year, eventDate.month, eventDate.day);

      if (event['type'] == 'Алкоголь') {
        if (alcoholMap[dayKey] == null) alcoholMap[dayKey] = [];
        alcoholMap[dayKey]!.add(event);
      } else {
        if (normalMap[dayKey] == null) normalMap[dayKey] = [];
        normalMap[dayKey]!.add(event);
      }
    }

    setState(() {
      _eventsMap = normalMap;
      _alcoholEventsMap = alcoholMap;
    });
  }

  Future<void> _loadAllEvents() async {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    final allEvents =
        await DatabaseHelper.instance.getEventsBetweenDates(firstDay, lastDay);

    Map<DateTime, List<Map<String, dynamic>>> normalMap = {};
    Map<DateTime, List<Map<String, dynamic>>> alcoholMap = {};

    for (var event in allEvents) {
      DateTime eventDate = DateTime.parse(event['date']);
      final dayKey = DateTime(eventDate.year, eventDate.month, eventDate.day);

      if (event['type'] == 'Алкоголь') {
        if (alcoholMap[dayKey] == null) alcoholMap[dayKey] = [];
        alcoholMap[dayKey]!.add(event);
      } else {
        if (normalMap[dayKey] == null) normalMap[dayKey] = [];
        normalMap[dayKey]!.add(event);
      }
    }

    setState(() {
      _eventsMap = normalMap;
      _alcoholEventsMap = alcoholMap;
    });
  }

  void _openFullList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventsListScreen(date: _selectedDay),
      ),
    ).then((_) {
      _loadEventsForDay(_selectedDay);
      _loadAllEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Считаем суммарные калории за выбранный день
    double totalCalories = 0;
    for (var event in _events) {
      final weight = event['weightOrCount'];
      final energy = event['energyValue'];
      final count = event['count'];
      if (weight != null && energy != null) {
        totalCalories += (weight * energy * count / 100);
      }
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4CAF50),
        onPressed: () {
          setState(() {});
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => BottomSwipeMenu(),
          ).then((_) {
            setState(() {});
          });
        },
        child: Icon(Icons.expand_less, color: Colors.white),
      ),
      body: Column(
        children: [
          SizedBox(height: 30.0),
          TableCalendar(
            locale: 'ru_RU',
            availableCalendarFormats: const {
              CalendarFormat.month: 'Месяц',
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true, // если хотите заголовок по центру
            ),
            calendarFormat: CalendarFormat.month,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            startingDayOfWeek: StartingDayOfWeek.monday,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadEventsForDay(selectedDay);
            },
            eventLoader: (day) {
              final dayKey = DateTime(day.year, day.month, day.day);
              return _eventsMap[dayKey] ?? [];
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xFF81C784), width: 2),
              ),
              todayTextStyle:
                  TextStyle(color: Colors.black), // чтобы текст был виден

              selectedDecoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final dayKey = DateTime(day.year, day.month, day.day);

                final hasNormalEvents =
                    (_eventsMap[dayKey]?.isNotEmpty ?? false);
                final hasAlcoholEvents =
                    (_alcoholEventsMap[dayKey]?.isNotEmpty ?? false);

                if (!hasNormalEvents && !hasAlcoholEvents) {
                  return SizedBox.shrink();
                }

                List<Widget> markers = [];

                // Метка в правом верхнем углу (например, алкоголь)
                if (hasAlcoholEvents) {
                  markers.add(
                    Positioned(
                      top: 4,
                      right: 5,
                      child: Icon(
                        Icons.local_bar, // Иконка "Алкоголь"
                        size: 12,
                        color: const Color.fromARGB(255, 205, 0, 0),
                      ),
                    ),
                  );
                }

                // Метка по центру снизу (обычные события)
                if (hasNormalEvents) {
                  markers.add(
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }

                return Stack(
                  children: markers,
                );
              },
            ),
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _loadEventsForMonth(focusedDay);
            },
          ),
          SizedBox(height: 16),
          Builder(
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;

              // Если норма не задана в SharedPreferences — возвращаем твой исходный базовый текст
              if (_dailyCalorieNorm == null) {
                return Text(
                  'Калории за день: ${totalCalories.toStringAsFixed(1)} ккал',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                );
              }

              // Если норма задана — вычисляем прогресс для шкалы и статус перебора
              double progress = totalCalories / _dailyCalorieNorm!;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Калории за день',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${totalCalories.toStringAsFixed(1)} / $_dailyCalorieNorm ккал',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ВИЗУАЛЬНЫЙ ВАРИАНТ: Индикатор прогресса (Шкала)
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: _openFullList,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.transparent,
                child: _events.isEmpty
                    ? Center(
                        child: Text('Записей нет. Нажмите для добавления.'))
                    : ListView.builder(
                        itemCount: _events.length > 5 ? 5 : _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          final imagePath = event['imagePath'] as String?;
                          final text = event['foodName'] ?? event['text'] ?? '';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14.0)),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (imagePath != null &&
                                        imagePath.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(imagePath),
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      SizedBox(
                                          width: 50,
                                          height:
                                              50), // пустое место под картинку
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        text.isNotEmpty ? text : 'Без описания',
                                        style: TextStyle(fontSize: 16),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
