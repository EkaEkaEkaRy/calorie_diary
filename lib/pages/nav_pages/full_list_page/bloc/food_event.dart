import 'package:calorie_diary/models/food_entry.dart';

abstract class FoodsEvent {}

// Событие первоначальной загрузки списка
class LoadFoodsEvent extends FoodsEvent {}

// Событие ввода текста в поиск
class SearchFoodsEvent extends FoodsEvent {
  final String query;
  SearchFoodsEvent(this.query);
}

// Событие обновления блюда
class UpdateFoodEvent extends FoodsEvent {
  final FoodEntry food;
  UpdateFoodEvent(this.food);
}
