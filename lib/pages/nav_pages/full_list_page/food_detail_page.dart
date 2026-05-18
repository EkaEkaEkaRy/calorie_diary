import 'package:calorie_diary/models/food_entry.dart';
import 'package:calorie_diary/pages/nav_pages/full_list_page/barcode_page.dart';
import 'package:calorie_diary/pages/nav_pages/full_list_page/bloc/food_bloc.dart';
import 'package:calorie_diary/pages/nav_pages/full_list_page/bloc/food_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FoodDetailPage extends StatefulWidget {
  final FoodEntry food;

  const FoodDetailPage({super.key, required this.food});

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _caloriesController;
  late TextEditingController _barcodeController;

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллеры текущими данными или пустыми строками
    _nameController = TextEditingController(text: widget.food.name);
    _weightController =
        TextEditingController(text: widget.food.weight.toString());
    _caloriesController =
        TextEditingController(text: widget.food.calories.toString());
    _barcodeController = TextEditingController(text: widget.food.barcode ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _caloriesController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _saveFood() async {
    final updatedFood = FoodEntry(
      id: widget.food.id, // ID остается прежним для SQL UPDATE
      name: _nameController.text.trim(),
      weight: double.tryParse(_weightController.text) ?? 0.0,
      calories: double.tryParse(_caloriesController.text) ?? 0.0,
      barcode: _barcodeController.text.isEmpty
          ? null
          : _barcodeController.text.trim(),
    );

    context.read<FoodsBloc>().add(UpdateFoodEvent(updatedFood));

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Text('Редактировать блюдо'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Название блюда
          TextFormField(
            controller: _nameController,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Название блюда',
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Введите название'
                : null,
          ),
          const SizedBox(height: 16),

          // Вес порции
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Вес (грамм)',
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // Калории
          TextFormField(
            controller: _caloriesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Калории (ккал)',
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // Штрих-код
          TextFormField(
            controller: _barcodeController,
            keyboardType: TextInputType.text,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Штрих-код',
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code, color: Color(0xFF4CAF50)),
                onPressed: () async {
                  // Открываем созданный ранее экран сканера

                  final String? code = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BarcodeScannerPage(),
                    ),
                  );

                  if (code != null) {
                    setState(() {
                      _barcodeController.text = code;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Кнопка сохранения
          ElevatedButton(
            onPressed: _saveFood,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Сохранить изменения',
                style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
