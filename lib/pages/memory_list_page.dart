import 'dart:io';

import 'package:calorie_diary/models/db_helper.dart';
import 'package:calorie_diary/models/memory_item_model.dart';
import 'package:flutter/material.dart';

class MemoryListPage extends StatefulWidget {
  const MemoryListPage({super.key});

  @override
  _MemoryListPageState createState() => _MemoryListPageState();
}

class _MemoryListPageState extends State<MemoryListPage> {
  Future<List<MemoryItemModel>>? _eventsFuture;
  List<MemoryItemModel> _allEventsMemories = [];

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadAllEventsText();
  }

  Future<List<MemoryItemModel>> _loadAllEventsText() async {
    final allEvents = await DatabaseHelper.instance.getAllMemories();
    return allEvents
        .map<MemoryItemModel>((map) => MemoryItemModel.fromMap(map))
        .toList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: FutureBuilder<List<MemoryItemModel>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Ошибка загрузки данных: ${snapshot.error}'));
          } else {
            _allEventsMemories = snapshot.data ?? [];

            return Column(
              children: [
                Expanded(
                  child: _allEventsMemories.isEmpty
                      ? const Center(child: Text('Записей не найдено'))
                      : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.7,
                            ),
                            itemCount: _allEventsMemories.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(5)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      color: Colors.amber,
                                      width: MediaQuery.of(context).size.width,
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        _allEventsMemories[index].date,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.file(
                                            File(_allEventsMemories[index]
                                                .image),
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                          if (_allEventsMemories[index].text !=
                                              null) ...[
                                            SizedBox(height: 8),
                                            Text(
                                              _allEventsMemories[index].text!,
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
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
