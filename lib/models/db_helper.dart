import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('calendar.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      type TEXT NOT NULL,
      text TEXT,
      weightOrCount REAL,
      energyValue REAL,
      imagePath TEXT,
      count REAL DEFAULT 1
    )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE events ADD COLUMN count REAL DEFAULT 1');
    }
  }

  Future<int> insertEvent(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('events', row);
  }

  Future<int> updateEvent(Map<String, dynamic> row, int id) async {
    final db = await instance.database;
    return await db.update('events', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final db = await instance.database;

    return await db.rawQuery(
        "SELECT DISTINCT text FROM events WHERE type <> 'Алкоголь' AND energyValue IS NOT NULL AND text IS NOT NULL AND text <> '' ORDER BY text");
  }

  Future<List<Map<String, dynamic>>> getFindUniqueTexts(
      {String? textQuery}) async {
    final db = await instance.database;

    if (textQuery == null || textQuery.isEmpty) {
      return await db.rawQuery(
          'SELECT DISTINCT text FROM events WHERE energyValue IS NOT NULL');
    } else {
      final likeQuery = '%${textQuery.toLowerCase()}%';
      return await db.rawQuery(
        "SELECT DISTINCT text FROM events WHERE LOWER(text) LIKE ? AND type <> 'Алкоголь' AND energyValue IS NOT NULL",
        [likeQuery],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAllMemories() async {
    final db = await instance.database;

    return await db.rawQuery(
        "SELECT DISTINCT id, text, date, imagePath FROM events WHERE imagePath IS NOT NULL ORDER BY date");
  }

  Future<List<Map<String, dynamic>>> getEvent({String? textQuery}) async {
    final db = await instance.database;

    if (textQuery == null || textQuery.isEmpty) {
      // Возвращаем все, сортируя по дате от новых к старым
      return await db.query(
        'events',
        where: 'energyValue IS NOT NULL AND text IS NOT NULL',
        orderBy: 'date DESC',
      );
    } else {
      // При точном совпадении text = textQuery
      return await db.query(
        'events',
        where: 'text = ? AND energyValue IS NOT NULL',
        whereArgs: [textQuery],
        orderBy: '''
    CASE
      WHEN weightOrCount IS NOT NULL THEN 1
      ELSE 2
    END,
    date DESC
  ''',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getEventsByDate(String date) async {
    final db = await instance.database;
    return await db.query('events', where: 'date = ?', whereArgs: [date]);
  }

  Future<List<Map<String, dynamic>>> getEventsBetweenDates(
      DateTime start, DateTime end) async {
    final db = await instance.database;
    final startDate = start.toIso8601String().substring(0, 10);
    final endDate = end.toIso8601String().substring(0, 10);

    return await db.query(
      'events',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await instance.database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTypeAlco(String date) async {
    final db = await instance.database;
    return await db.delete('events',
        where: "date = ? AND type = 'Алкоголь'", whereArgs: [date]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
