import 'package:calorie_diary/pages/nav_pages/full_list_page/bloc/food_event.dart';
import 'package:calorie_diary/pages/nav_pages/full_list_page/bloc/food_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calorie_diary/database/db_helper.dart';
import 'package:calorie_diary/models/food_entry.dart';

class FoodsBloc extends Bloc<FoodsEvent, FoodsState> {
  FoodsBloc() : super(FoodsInitial()) {
    on<LoadFoodsEvent>(_onLoadFoods);
    on<SearchFoodsEvent>(_onSearchFoods);
    on<UpdateFoodEvent>(_onUpdateFood);
  }

  // Вспомогательный метод для сортировки списка по алфавиту
  List<FoodEntry> _sortFoods(List<FoodEntry> list) {
    return list
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> _onLoadFoods(
      LoadFoodsEvent event, Emitter<FoodsState> emit) async {
    emit(FoodsLoading());
    try {
      final maps = await DatabaseHelper.instance.getAllFood();
      final list = maps.map((map) => FoodEntry.fromMap(map)).toList();
      final sortedList = _sortFoods(list);

      emit(FoodsLoaded(allFoods: sortedList, filteredFoods: sortedList));
    } catch (e) {
      emit(FoodsError('Не удалось загрузить данные: $e'));
    }
  }

  void _onSearchFoods(SearchFoodsEvent event, Emitter<FoodsState> emit) {
    if (state is FoodsLoaded) {
      final currentState = state as FoodsLoaded;
      final query = event.query.toLowerCase();

      final filtered = currentState.allFoods
          .where((food) => food.name.toLowerCase().contains(query))
          .toList();

      emit(FoodsLoaded(
        allFoods: currentState.allFoods,
        filteredFoods: _sortFoods(filtered),
        searchQuery: event.query,
      ));
    }
  }

  Future<void> _onUpdateFood(
      UpdateFoodEvent event, Emitter<FoodsState> emit) async {
    try {
      await DatabaseHelper.instance.updateFood(event.food);

      // Перезапрашиваем актуальный список из базы данных после обновления
      add(LoadFoodsEvent());
    } catch (e) {
      emit(FoodsError('Ошибка при обновлении в БД: $e'));
    }
  }
}
