import 'dart:ui';

int indexCategory = 0;

int getIndexCategory() {
  indexCategory++;
  final i = indexCategory;
  return i;
}

class CategoryModel {
  final int id = getIndexCategory();
  final String name;
  final Color color;

  CategoryModel({required this.name, required this.color});
}
