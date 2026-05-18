import 'package:calorie_diary/models/food_entry.dart';

abstract class FoodsState {}

// Состояние инициализации
class FoodsInitial extends FoodsState {}

// Состояние загрузки данных
class FoodsLoading extends FoodsState {}

// Данные успешно загружены и отсортированы
class FoodsLoaded extends FoodsState {
  final List<FoodEntry> allFoods;
  final List<FoodEntry> filteredFoods;
  final String searchQuery;

  FoodsLoaded({
    required this.allFoods,
    required this.filteredFoods,
    this.searchQuery = '',
  });
}

// Ошибка при работе с БД
class FoodsError extends FoodsState {
  final String message;
  FoodsError(this.message);
}
