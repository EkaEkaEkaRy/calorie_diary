class FoodEntry {
  int? id; // ID записи (автоинкремент в SQLite)
  String name; // Название продукта или блюда
  int calories; // Калории
  int proteins; // Белки (опционально)
  int fats; // Жиры (опционально)
  int carbs; // Углеводы (опционально)
  String date; // Дата приёма пищи (в формате строки)

  FoodEntry({
    this.id,
    required this.name,
    required this.calories,
    this.proteins = 0,
    this.fats = 0,
    this.carbs = 0,
    required this.date,
  });

  // Преобразование объекта в Map для SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'proteins': proteins,
      'fats': fats,
      'carbs': carbs,
      'date': date,
    };
  }

  // Создание объекта из Map (из данных SQLite)
  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      id: map['id'],
      name: map['name'],
      calories: map['calories'],
      proteins: map['proteins'],
      fats: map['fats'],
      carbs: map['carbs'],
      date: map['date'],
    );
  }
}
