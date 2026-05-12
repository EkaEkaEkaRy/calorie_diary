class FoodEntry {
  int id; // ID записи (автоинкремент в SQLite)
  String name; // Название продукта или блюда
  double calories; // Калории
  double? weight;
  String? imagePath;
  String? barcode;

  FoodEntry(
      {required this.id,
      required this.name,
      required this.calories,
      this.weight,
      this.imagePath,
      this.barcode});

  // Создание объекта из Map (из данных SQLite)
  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      id: map['id'],
      name: map['name'],
      calories: map['calories'],
      weight: map['weight'],
      imagePath: map['imagePath'],
      barcode: map['barcode'],
    );
  }
}
