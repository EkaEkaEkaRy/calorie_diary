import 'dart:io';
import 'package:calorie_diary/models/category_item.dart';
import 'package:calorie_diary/models/challenge_model.dart';
import 'package:calorie_diary/models/food_entry.dart';
import 'package:flutter/material.dart';
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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      food_id INTEGER
      type TEXT NOT NULL,
      text TEXT,
      weightOrCount REAL,
      energyValue REAL,
      imagePath TEXT,
      count REAL DEFAULT 1
    )
    ''');

    // Таблица блюд (справочник)
    await db.execute('''
    CREATE TABLE foods (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      weight REAL,
      calories REAL,
      imagePath TEXT,
      barcode TEXT)
    ''');

    // Таблица категорий
    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      color INTEGER NOT NULL
    )
    ''');

    // Таблица связей (Многие-ко-многим для событий и категорий)
    await db.execute('''
    CREATE TABLE event_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_id INTEGER NOT NULL,
      category_id INTEGER NOT NULL,
      FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
    )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE events ADD COLUMN count REAL DEFAULT 1');
    }

    if (oldVersion < 3) {
      // 1. Создаем таблицу-справочник блюд
      await db.execute('''CREATE TABLE foods (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      weight REAL,
      calories REAL,
      imagePath TEXT,
      barcode TEXT
    )''');

      // 2. Создаем таблицы для категорий
      await db.execute('''CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      color INTEGER NOT NULL
    )''');

      await db.execute('''CREATE TABLE event_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_id INTEGER NOT NULL,
      category_id INTEGER NOT NULL,
      FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
    )''');

      // 3. Добавляем колонку food_id в таблицу events
      await db.execute('ALTER TABLE events ADD COLUMN food_id INTEGER');

      // 4. МИГРАЦИЯ ДАННЫХ
      // Берем записи с едой, сортируем от новых к старым (чтобы взять актуальный вес)
      final List<Map<String, dynamic>> oldEvents = await db.query(
        'events',
        where: 'text IS NOT NULL AND energyValue IS NOT NULL',
        orderBy: 'date DESC',
      );

      for (var event in oldEvents) {
        final String foodName = event['text'];

        // Вставляем блюдо или игнорируем, если такое имя уже есть
        // При INSERT OR IGNORE, если имя дублируется, запись не создастся
        await db.rawInsert('''
        INSERT OR IGNORE INTO foods (name, weight, calories)
        VALUES (?, ?, ?)
      ''', [foodName, event['weightOrCount'], event['energyValue']]);

        // Находим ID этого блюда в таблице foods
        final List<Map<String, dynamic>> foodResult = await db.query(
          'foods',
          columns: ['id'],
          where: 'name = ?',
          whereArgs: [foodName],
        );

        if (foodResult.isNotEmpty) {
          int foodId = foodResult.first['id'];

          await db.update(
            'events',
            {
              'food_id': foodId,
              'text': null,
            },
            where: 'id = ?',
            whereArgs: [event['id']],
          );
        }
      }
    }
  }

  // События
  Future<int> insertEvent(Map<String, dynamic> row) async {
    final db = await instance.database;

    Map<String, dynamic> eventRow = Map.from(row);

    String? rowText = eventRow['text'];
    double? energyValue = eventRow['energyValue'];

    // Пытаемся найти или создать блюдо, если есть название и калории
    if (rowText != null && energyValue != null && energyValue > 0) {
      // Ищем, есть ли уже такое блюдо в базе
      final List<Map<String, dynamic>> existingFood = await db.query(
        'foods',
        where: 'name = ?',
        whereArgs: [rowText],
      );

      int foodId;
      if (existingFood.isNotEmpty) {
        // Если нашли — берем его ID
        foodId = existingFood.first['id'];
      } else {
        // Если не нашли — создаем новое блюдо
        foodId = await db.insert('foods', {
          'name': rowText,
          'calories': energyValue,
          'weight':
              eventRow['weightOrCount'], // берем текущий вес как дефолтный
        });
      }

      eventRow['food_id'] = foodId;
      eventRow['text'] = null;
    } else {
      eventRow['food_id'] = null;
    }

    // Вставляем итоговую строку в таблицу events
    return await db.insert('events', eventRow);
  }

  Future<int> updateEvent(Map<String, dynamic> row, int id) async {
    final db = await instance.database;
    Map<String, dynamic> eventRow = Map.from(row);

    String? newText = eventRow['text'];
    double? energyValue = eventRow['energyValue'];
    int? oldFoodId = eventRow['food_id'];

    // Проверяем текущее имя блюда по старому food_id
    bool isSameName = false;
    if (oldFoodId != null && newText != null) {
      final List<Map<String, dynamic>> res = await db.query(
        'foods',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [oldFoodId],
      );
      if (res.isNotEmpty && res.first['name'] == newText) {
        isSameName = true;
      }
    }

    // Логика определения нового food_id
    if (newText != null && energyValue != null && energyValue > 0) {
      if (isSameName) {
        // Имя то же самое — ничего не меняем в food_id, текст зануляем
        eventRow['text'] = null;
      } else {
        // Имя изменилось — ищем новое или создаем
        final List<Map<String, dynamic>> existing = await db.query(
          'foods',
          where: 'name = ?',
          whereArgs: [newText],
        );

        int newFoodId;
        if (existing.isNotEmpty) {
          newFoodId = existing.first['id'];
        } else {
          newFoodId = await db.insert('foods', {
            'name': newText,
            'calories': energyValue,
            'weight': eventRow['weightOrCount'],
          });
        }
        eventRow['food_id'] = newFoodId;
        eventRow['text'] = null;
      }
    } else {
      // Больше не является блюдом
      eventRow['food_id'] = null;
    }

    // Сохраняем изменения в events
    int result =
        await db.update('events', eventRow, where: 'id = ?', whereArgs: [id]);

    // Если food_id изменился или стал null, проверяем старое блюдо
    if (oldFoodId != null && oldFoodId != eventRow['food_id']) {
      final List<Map<String, dynamic>> countRes = await db.rawQuery(
          'SELECT COUNT(*) as total FROM events WHERE food_id = ?',
          [oldFoodId]);

      // Если на это блюдо больше никто не ссылается — удаляем его из справочника
      if (countRes.first['total'] == 0) {
        await db.delete('foods', where: 'id = ?', whereArgs: [oldFoodId]);
      }
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getFindUniqueTexts(
      {String? textQuery}) async {
    final db = await instance.database;

    if (textQuery == null || textQuery.isEmpty) {
      return await db.rawQuery('SELECT * FROM foods');
    } else {
      final likeQuery = '%${textQuery.toLowerCase()}%';
      return await db.rawQuery(
        "SELECT * FROM foods WHERE LOWER(name) LIKE ?",
        [likeQuery],
      );
    }
  }

  Future<Map<String, dynamic>?> getFoodByBarcode(String code) async {
    final db = await instance.database;
    final foods =
        await db.rawQuery('SELECT * FROM foods WHERE barcode = ?', [code]);
    if (foods.isEmpty) {
      return null;
    }
    return foods.first;
  }

  Future<List<Map<String, dynamic>>> getEventsByDate(String date) async {
    final db = await instance.database;
    return await db.rawQuery('''
    SELECT 
      events.*, 
      foods.name AS foodName
    FROM events
    LEFT JOIN foods ON events.food_id = foods.id
    WHERE events.date = ?
  ''', [date]);
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

  // Воспоминания
  Future<List<Map<String, dynamic>>> getAllMemories() async {
    final db = await instance.database;

    return await db.rawQuery('''
    SELECT DISTINCT 
      events.id, 
      COALESCE(foods.name, events.text) AS text, 
      events.date, 
      events.imagePath 
    FROM events 
    LEFT JOIN foods ON events.food_id = foods.id
    WHERE events.imagePath IS NOT NULL 
    ORDER BY events.date DESC
  ''');
  }

  // Весь список блюд
  Future<List<Map<String, dynamic>>> getAllFood() async {
    final db = await instance.database;

    return await db.rawQuery("SELECT * FROM foods ORDER BY name");
  }

  Future<void> updateFood(FoodEntry food) async {
    final db = await instance.database;

    await db.rawUpdate('''
    UPDATE foods 
    SET name = ?, weight = ?, calories = ?, imagePath = ?, barcode = ?
    WHERE id = ?
  ''', [
      food.name,
      food.weight,
      food.calories,
      food.imagePath,
      food.barcode,
      food.id,
    ]);

    return;
  }

  // КАТЕГОРИИ
  Future<List<CategoryModel>> getAllCategories() async {
    final db = await instance.database;
    // Получаем все строки из таблицы категорий
    final List<Map<String, dynamic>> res = await db.query('categories');

    return res
        .map((map) => CategoryModel(
              id: map['id'],
              name: map['name'],
              // SQLite хранит цвет как int, превращаем его обратно в объект Color
              color: Color(map['color']),
            ))
        .toList();
  }

  Future<int> insertCategory(String name, int colorValue) async {
    final db = await instance.database;
    // Используем INSERT OR IGNORE, чтобы не падать при дубликате имени
    return await db.insert('categories', {'name': name, 'color': colorValue});
  }

  Future<int> updateCategory(int id, String name, int colorValue) async {
    final db = await instance.database;
    return await db.update('categories', {'name': name, 'color': colorValue},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    // Благодаря ON DELETE CASCADE в схеме, связи в event_categories удалятся сами
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

// СВЯЗИ (Многие-ко-многим)
  Future<Map<int, List<CategoryModel>>> getAllMemoryLinks() async {
    final db = await instance.database;

    // Объединяем таблицу связей с таблицей категорий
    final List<Map<String, dynamic>> res = await db.rawQuery('''
    SELECT 
      event_categories.event_id, 
      categories.id, 
      categories.name, 
      categories.color
    FROM event_categories
    JOIN categories ON event_categories.category_id = categories.id
  ''');

    Map<int, List<CategoryModel>> links = {};

    for (var row in res) {
      int eventId = row['event_id'];

      // Если для этого ID события еще нет списка в мапе — создаем его
      if (!links.containsKey(eventId)) {
        links[eventId] = [];
      }

      // Добавляем категорию в список этого события
      links[eventId]!.add(CategoryModel(
        id: row['id'],
        name: row['name'],
        color: Color(row['color']),
      ));
    }

    return links;
  }

  Future<void> toggleLink(int eventId, int categoryId) async {
    final db = await instance.database;

    // Проверяем, есть ли связь
    final res = await db.query('event_categories',
        where: 'event_id = ? AND category_id = ?',
        whereArgs: [eventId, categoryId]);

    if (res.isEmpty) {
      await db.insert(
          'event_categories', {'event_id': eventId, 'category_id': categoryId});
    } else {
      await db.delete('event_categories',
          where: 'event_id = ? AND category_id = ?',
          whereArgs: [eventId, categoryId]);
    }
  }

  // Проверка челленджа
  Future<bool> checkChallengeDayStatus(
      String isoDate, ChallengeType type) async {
    final db = await instance.database;

    switch (type) {
      case ChallengeType.cleanMind:
        // Ищем, были ли записи с типом "Алкоголь" за этот день
        final res = await db.query('events',
            where: 'date = ? AND type = ?', whereArgs: [isoDate, 'Алкоголь']);
        return res
            .isEmpty; // Если пустой список — значит алкоголя не было, день выполнен!

      case ChallengeType.rainbowPlate:
        // Проверяем наличие блюд с категорией Овощи/Фрукты
        final res = await db.rawQuery('''
        SELECT COUNT(*) as total FROM events 
        JOIN foods ON events.food_id = foods.id
        WHERE events.date = ? AND (foods.category = 'Овощи' OR foods.category = 'Фрукты')
      ''', [isoDate]);
        return (res.first['total'] as int) > 0;

      case ChallengeType.cleanEvening:
        // Тут будет проверка времени внесения последней записи в этот день
        // (Например, если в поле date ты хранишь и время, либо по структуре приложения)
        return true; // Временная заглушка

      case ChallengeType.inBullseye:
        // Считаем сумму калорий из events за день и сравниваем с нормой пользователя
        return true; // Временная заглушка

      case ChallengeType.honestDiary:
        // Считаем уникальные типы приемов пищи за день (должно быть >= 3: Завтрак, Обед, Ужин)
        final res =
            await db.query('events', where: 'date = ?', whereArgs: [isoDate]);
        return res.length >= 3;

      case ChallengeType.sugarDetox:
        // Считаем продукты из категории 'Сладости' за день (должно быть <= 1)
        return true; // Временная заглушка

      case ChallengeType.homeKitchen:
        // Ищем блюда, содержащие тег/категорию 'Фастфуд' за день
        return true; // Временная заглушка

      case ChallengeType.lightEvening:
        return true;
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future<void> debugPrintFullDatabase() async {
    final db = await instance.database;

    debugPrint('\n========== ПОЛНЫЙ ДАМП БАЗЫ ДАННЫХ ==========');

    // 1. ТАБЛИЦА FOODS
    debugPrint('\n[TABLE: foods] - Справочник блюд');
    final foods = await db.query('foods');
    if (foods.isEmpty) {
      debugPrint('   Пусто');
    } else {
      for (var row in foods) {
        debugPrint(
            '   ID: ${row['id']} | Название: ${row['name']} | Кал: ${row['calories']} | Вес: ${row['weight']} | Баркод: ${row['barcode']} | Путь: ${row['imagePath']}');
      }
    }

    // 2. ТАБЛИЦА CATEGORIES
    debugPrint('\n[TABLE: categories] - Справочник категорий');
    final categories = await db.query('categories');
    if (categories.isEmpty) {
      debugPrint('   Пусто');
    } else {
      for (var row in categories) {
        debugPrint(
            '   ID: ${row['id']} | Имя: ${row['name']} | Цвет(int): ${row['color']}');
      }
    }

    // 3. ТАБЛИЦА EVENTS
    debugPrint('\n[TABLE: events] - Дневник событий');
    // JOIN нужен, чтобы увидеть, какое именно блюдо привязано к food_id
    final events = await db.rawQuery('''
    SELECT e.*, f.name as food_name 
    FROM events e 
    LEFT JOIN foods f ON e.food_id = f.id
  ''');
    if (events.isEmpty) {
      debugPrint('   Пусто');
    } else {
      for (var row in events) {
        debugPrint(
            '   ID: ${row['id']} | Дата: ${row['date']} | Тип: ${row['type']} | Food_ID: ${row['food_id']} (Блюдо: ${row['food_name']}) | Текст: ${row['text']} | Вес/Кол: ${row['weightOrCount']} | Кал: ${row['energyValue']} | Кол-во: ${row['count']} | Путь: ${row['imagePath']}');
      }
    }

    // 4. ТАБЛИЦА EVENT_CATEGORIES
    debugPrint('\n[TABLE: event_categories] - Связи категорий');
    final links = await db.rawQuery('''
    SELECT ec.id, ec.event_id, c.name as cat_name
    FROM event_categories ec
    JOIN categories c ON ec.category_id = c.id
  ''');
    if (links.isEmpty) {
      debugPrint('   Связей пока нет');
    } else {
      for (var row in links) {
        debugPrint(
            '   Link_ID: ${row['id']} | Event_ID: ${row['event_id']} ===> Категория: ${row['cat_name']}');
      }
    }

    debugPrint('\n=============================================');
  }
}
