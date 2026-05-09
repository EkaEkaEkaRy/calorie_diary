import 'package:calorie_diary/pages/nav_pages/full_list_page.dart';
import 'package:calorie_diary/pages/nav_pages/memory_list_page.dart';
import 'package:calorie_diary/pages/nav_pages/motivation_page/motivation_page.dart';
import 'package:flutter/material.dart';

class BottomSwipeMenu extends StatefulWidget {
  const BottomSwipeMenu({super.key});

  @override
  _BottomSwipeMenuState createState() => _BottomSwipeMenuState();
}

class _BottomSwipeMenuState extends State<BottomSwipeMenu> {
  // Выносим данные в структуру для удобства
  final List<Map<String, dynamic>> menuItems = [
    {
      'icon': Icons.app_registration_rounded,
      'label': 'Блюда',
      'page': const FullListPage()
    },
    {
      'icon': Icons.photo_album,
      'label': 'Фото',
      'page': const MemoryListPage()
    },
    {
      'icon': Icons.brightness_4_outlined,
      'label': 'Мотивация',
      'page': MotivationPage()
    }, // Пока заглушка
    {'icon': Icons.settings_outlined, 'label': 'Настройки', 'page': null},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.18,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface, // Используем ваш F1F8E9
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: ListView(
            // Используем ListView с контроллером для скролла шторки
            controller: scrollController,
            children: [
              const SizedBox(height: 12),
              // Хендл
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Ряд иконок
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: menuItems
                    .map((item) => _buildMenuButton(context, item))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuButton(BuildContext context, Map<String, dynamic> item) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasPage = item['page'] != null;

    return GestureDetector(
      onTap: () {
        if (hasPage) {
          Navigator.of(context).pop(); // Закрываем шторку
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => item['page']),
          );
        } else {
          // Логика для вкладок без страниц
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Раздел "${item['label']}" в разработке')),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor:
                colorScheme.primaryContainer, // Светло-зеленый (C8E6C9)
            child: Icon(
              item['icon'],
              color:
                  hasPage ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item['label'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/*
class BottomSwipeMenu extends StatefulWidget {
  @override
  _BottomSwipeMenuState createState() => _BottomSwipeMenuState();
}

class _BottomSwipeMenuState extends State<BottomSwipeMenu> {
  final List<IconData> icons = [
    Icons.app_registration_rounded,
    Icons.star,
    Icons.settings,
  ];

  late ScrollController _scrollController;
  final int _repetitionCount = 10;

  // Расстояние между центрами элементов (иконок) по оси X, увеличено с 70 до 100 (пример)
  final double itemSpacing = 100.0;

  // Размеры иконки при нормальном и увеличенном виде
  final double baseIconSize = 36;
  final double maxIconSize = 56;
  final double baseRadius = 28;
  final double maxRadius = 40;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: icons.length * itemSpacing * _repetitionCount / 2,
    );

    // Обновлять состояние при прокрутке, чтобы перекрасить иконки с масштабом
    _scrollController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _getRealIndex(int index) {
    return index % icons.length;
  }

  @override
  Widget build(BuildContext context) {
    // Получаем ширину экрана
    final screenWidth = MediaQuery.of(context).size.width;
    // Считаем центр экрана (по x)
    final centerX = screenWidth / 2;

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.14,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
          ),
          child: Column(
            children: [
              SizedBox(height: 12),
              Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 14),
              SizedBox(
                height:
                    2 * maxRadius + 10, // высота с учётом увеличенного размера
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: icons.length * _repetitionCount,
                  itemBuilder: (context, index) {
                    final icon = icons[_getRealIndex(index)];

                    double itemCenterX = index * itemSpacing + itemSpacing / 2;
                    double scrollOffset = _scrollController.hasClients
                        ? _scrollController.offset
                        : 0;
                    double screenPosX = itemCenterX - scrollOffset;
                    double distanceFromCenter = (centerX - screenPosX).abs();

                    double maxDistance = 150;
                    double t = (distanceFromCenter / maxDistance).clamp(0, 1);

                    double scale = 1.5 - (0.8 * t);

                    double iconSize = baseIconSize * scale;
                    double radius = baseRadius * scale;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: itemSpacing / 2 - radius),
                      child: GestureDetector(
                        onTap: () {
                          if (icon == Icons.app_registration_rounded) {
                            Navigator.of(context)
                                .pop(); // закрываем меню перед навигацией (по желанию)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FullListPage()),
                            );
                          }
                        },
                        child: CircleAvatar(
                          radius: radius,
                          backgroundColor: Colors.green[100],
                          child:
                              Icon(icon, color: Colors.green, size: iconSize),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
*/
