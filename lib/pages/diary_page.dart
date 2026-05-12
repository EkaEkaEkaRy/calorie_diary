import 'dart:io';

import 'package:calorie_diary/models/db_helper.dart';
import 'package:calorie_diary/pages/add_form_page.dart';
import 'package:calorie_diary/pages/full_screen_image_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventsListScreen extends StatefulWidget {
  final DateTime date;

  const EventsListScreen({super.key, required this.date});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  // Все типы в базе
  final List<String> _dbTypes = [
    'Алкоголь',
    'Завтрак',
    'Перекус 1',
    'Обед',
    'Перекус 2',
    'Ужин',
    'Перекус 3',
  ];

  // Отображаемые названия для пользователя
  final Map<String, String> _displayNames = {
    'Алкоголь': 'Алкоголь',
    'Завтрак': 'Завтрак',
    'Перекус 1': 'Перекус',
    'Обед': 'Обед',
    'Перекус 2': 'Перекус',
    'Ужин': 'Ужин',
    'Перекус 3': 'Перекус',
  };

  Map<String, List<Map<String, dynamic>>> _eventsByType = {};
  final Map<String, bool> _alcoholSwitchValue = {'Алкоголь': false};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final dateString = DateFormat('yyyy-MM-dd').format(widget.date);
    final allEvents = await DatabaseHelper.instance.getEventsByDate(dateString);

    // Группируем события по типу
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var type in _dbTypes) {
      grouped[type] = allEvents.where((e) => e['type'] == type).toList();
    }

    setState(() {
      _eventsByType = grouped;
      _alcoholSwitchValue['Алкоголь'] =
          (grouped['Алкоголь']?.isNotEmpty ?? false);
    });
  }

  void _addEvent(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(
          date: widget.date,
          initialType: type,
        ),
      ),
    );
    if (result == true) {
      _loadEvents();
    }
  }

  void _editEvent(Map<String, dynamic> event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(
          date: widget.date,
          event: event,
        ),
      ),
    );
    if (result == true) {
      _loadEvents();
    }
  }

  Future<void> _deleteEvent(Map<String, dynamic> event) async {
    final db = await DatabaseHelper.instance.database;

    // Удаляем файл изображения, если он есть и существует
    final imagePath = event['imagePath'];
    if (imagePath != null && imagePath is String && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          // Можно логировать ошибку, если нужно
          debugPrint('Ошибка при удалении файла изображения: $e');
        }
      }
    }

    // Удаляем запись из базы
    await db.delete('events', where: 'id = ?', whereArgs: [event['id']]);
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('d MMMM y', 'ru').format(widget.date);

    // Считаем суммарные калории за день
    double totalCalories = 0;
    for (var eventsList in _eventsByType.values) {
      for (var event in eventsList) {
        final weight = event['weightOrCount'];
        final energy = event['energyValue'];
        final count = event['count'];
        if (weight != null && energy != null) {
          totalCalories += (weight * energy * count / 100);
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(dateFormatted),
      ),
      body: ListView.builder(
        itemCount: _dbTypes.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Первая строка — выводим суммарные калории
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Калории за день: ${totalCalories.toStringAsFixed(1)} ккал',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            );
          }

          final dbType = _dbTypes[index - 1];
          final displayName = _displayNames[dbType]!;
          final events = _eventsByType[dbType] ?? [];

          final double totalCaloriesForType = events.fold(0, (sum, event) {
            final weight = event['weightOrCount'];
            final energy = event['energyValue'];
            final count = event['count'];
            if (weight != null && energy != null) {
              return sum + (weight * energy * count / 100);
            }
            return sum;
          });
          if (dbType == 'Алкоголь') {
            // Возвращаем виджет с переключателем
            return Card(
              color: Colors.white,
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayName,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: _alcoholSwitchValue['Алкоголь'] ?? false,
                      onChanged: (bool newValue) async {
                        if (newValue) {
                          final db = await DatabaseHelper.instance.database;
                          final dateString =
                              DateFormat('yyyy-MM-dd').format(widget.date);

                          final row = {
                            'date': dateString,
                            'type': 'Алкоголь',
                            'text': 'True'
                          };
                          await db.insert('events', row);
                        } else {
                          await DatabaseHelper.instance
                              .deleteTypeAlco(events[0]['date']);
                        }
                        setState(() {
                          _alcoholSwitchValue['Алкоголь'] = newValue;
                        });
                      },
                      activeThumbColor: Colors.green,
                    )
                  ],
                ),
              ),
            );
          }

          return Card(
            color: Colors.white,
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок с кнопкой добавления
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          totalCaloriesForType != 0
                              ? Text(
                                  '${totalCaloriesForType.toStringAsFixed(1)} ккал',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green,
                                  ),
                                )
                              : SizedBox(),
                          SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.green),
                            onPressed: () => _addEvent(dbType),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Список событий этого типа
                  if (events.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Нет записей',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    )
                  else
                    Column(
                      children: events.map((event) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Color(0xFF81C784), width: 2),
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Картинка, если есть
                                    if (event['imagePath'] != null &&
                                        (event['imagePath'] as String)
                                            .isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  FullscreenImageScreen(
                                                      imagePath:
                                                          event['imagePath']),
                                            ),
                                          );
                                        },
                                        child: Hero(
                                          tag: event['id'],
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.file(
                                              File(event['imagePath']),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (event['imagePath'] != null &&
                                        (event['imagePath'] as String)
                                            .isNotEmpty)
                                      SizedBox(width: 12),

                                    // Текст описания, занимает всё доступное пространство
                                    Expanded(
                                      child: Text(
                                        (event['foodName'] != null
                                            ? event['foodName'] +
                                                ((event['count'] != null &&
                                                        event['count'] > 1)
                                                    ? ' ${event['count'].toInt()}шт'
                                                    : '')
                                            : event['text'] ?? 'Без описания'),
                                        style: TextStyle(fontSize: 16),
                                        maxLines: null,
                                        softWrap: true,
                                      ),
                                    ),
                                    SizedBox(width: 12),

                                    // Энергетическая ценность
                                    if (event['weightOrCount'] != null &&
                                        event['energyValue'] != null)
                                      Text(
                                        "${(event['weightOrCount'] * event['energyValue'] * event['count'] / 100).toStringAsFixed(1)} ккал",
                                        style: TextStyle(fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                                // Кнопки редактирования и удаления, прижаты к правому краю и близко друг к другу
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      onPressed: () => _editEvent(event),
                                      tooltip: 'Редактировать',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: Colors.white,
                                            title: Text('Удалить запись?',
                                                style: TextStyle(
                                                    color: Colors.black)),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: Text('Отмена',
                                                    style: TextStyle(
                                                        color: Colors.black)),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: Text('Удалить',
                                                    style: TextStyle(
                                                        color: Colors.black)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await _deleteEvent(event);
                                        }
                                      },
                                      tooltip: 'Удалить',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
