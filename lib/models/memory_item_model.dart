class MemoryItemModel {
  int id;
  String? text;
  String image;
  String date;

  MemoryItemModel({
    required this.id,
    this.text,
    required this.image,
    required this.date,
  });

  // Создание объекта из Map (из данных SQLite)
  factory MemoryItemModel.fromMap(Map<String, dynamic> map) {
    return MemoryItemModel(
      id: map['id'],
      text: map['text'],
      image: map['imagePath'],
      date: map['date'],
    );
  }
}
