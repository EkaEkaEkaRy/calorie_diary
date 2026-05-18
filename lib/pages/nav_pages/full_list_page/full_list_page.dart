import 'package:calorie_diary/models/food_entry.dart';
import 'package:calorie_diary/pages/nav_pages/full_list_page/bloc/food_bloc.dart';
import 'package:calorie_diary/pages/nav_pages/full_list_page/bloc/food_event.dart';
import 'package:calorie_diary/pages/nav_pages/full_list_page/bloc/food_state.dart';
import 'package:calorie_diary/pages/nav_pages/full_list_page/food_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FullListPage extends StatefulWidget {
  const FullListPage({super.key});

  @override
  State<FullListPage> createState() => _FullListPageState();
}

class _FullListPageState extends State<FullListPage> {
  List<FoodEntry> _filteredEventsTexts = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text('Все блюда'),
      ),
      body: BlocProvider(
        create: (_) => FoodsBloc()..add(LoadFoodsEvent()),
        child: BlocBuilder<FoodsBloc, FoodsState>(builder: (context, state) {
          if (state is FoodsLoading) {
            return Center(
                child: CircularProgressIndicator(color: colorScheme.primary));
          }
          if (state is FoodsError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }
          if (state is FoodsLoaded) {
            _searchController.addListener(() {
              context
                  .read<FoodsBloc>()
                  .add(SearchFoodsEvent(_searchController.text));
            });
            _filteredEventsTexts = state.filteredFoods;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search,
                          color: colorScheme.onSurfaceVariant),
                      hintText: 'Поиск записей',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainer,
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredEventsTexts.isEmpty
                      ? Center(
                          child: Text(
                            'Записей не найдено',
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 50),
                          itemCount: _filteredEventsTexts.length,
                          itemBuilder: (context, index) {
                            final food = _filteredEventsTexts[index];

                            // Получаем первую букву текущего блюда
                            final currentLetter = food.name.isNotEmpty
                                ? food.name[0].toUpperCase()
                                : '';

                            // Проверяем, нужно ли выводить заголовок буквы
                            bool showLetterHeader = false;
                            if (index == 0) {
                              showLetterHeader = true;
                            } else {
                              final previousFood =
                                  _filteredEventsTexts[index - 1];
                              final previousLetter =
                                  previousFood.name.isNotEmpty
                                      ? previousFood.name[0].toUpperCase()
                                      : '';
                              if (currentLetter != previousLetter) {
                                showLetterHeader = true;
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showLetterHeader &&
                                    currentLetter.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 10, bottom: 2, left: 2),
                                    key: ValueKey('header_$currentLetter'),
                                    child: Text(
                                      currentLetter,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: () async {
                                    final foodsBloc = context.read<FoodsBloc>();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BlocProvider.value(
                                          value: foodsBloc,
                                          child: FoodDetailPage(food: food),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainer,
                                      borderRadius: BorderRadius.circular(14.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 4),
                                      title: Text(
                                        food.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: colorScheme.onSurface,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            );
          }
          return Center(
              child: CircularProgressIndicator(color: colorScheme.primary));
        }),
      ),
    );
  }
}
