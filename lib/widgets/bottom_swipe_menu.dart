import 'package:calorie_diary/pages/nav_pages/memory_page/memory_page.dart';
import 'package:calorie_diary/pages/nav_pages/full_list_page.dart';
import 'package:calorie_diary/pages/nav_pages/motivation_page/motivation_page.dart';
import 'package:flutter/material.dart';

class BottomSwipeMenu extends StatefulWidget {
  const BottomSwipeMenu({super.key});

  @override
  State<BottomSwipeMenu> createState() => _BottomSwipeMenuState();
}

class _BottomSwipeMenuState extends State<BottomSwipeMenu> {
  // Твои данные
  final List<Map<String, dynamic>> menuItems = [
    {
      'icon': Icons.app_registration_rounded,
      'label': 'Блюда',
      'page': const FullListPage()
    },
    {'icon': Icons.photo_album, 'label': 'Фото', 'page': MemoryListPage()},
    {
      'icon': Icons.brightness_4_outlined,
      'label': 'Мотивация',
      'page': const MotivationPage()
    },
    {'icon': Icons.settings_outlined, 'label': 'Настройки', 'page': null},
  ];

  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.3);
    _pageController.addListener(() {
      setState(() => _currentPage = _pageController.page!);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.14,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Хендл
              Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 20),

              // Карусель иконок
              SizedBox(
                height: 110,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: menuItems.length,
                  clipBehavior:
                      Clip.none, // Позволяет иконкам выходить за границы
                  itemBuilder: (context, index) {
                    double difference = (index - _currentPage).abs();
                    double scale = 1.0 - (difference * 0.15).clamp(0.0, 0.15);

                    return _buildAnimatedItem(context, menuItems[index], scale);
                  },
                ),
              ),

              // ПОДСКАЗКА: Точки пагинации
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(menuItems.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: _currentPage.round() == index ? 12 : 6,
                    decoration: BoxDecoration(
                      color: _currentPage.round() == index
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedItem(
      BuildContext context, Map<String, dynamic> item, double scale) {
    final colorScheme = Theme.of(context).colorScheme;

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: scale, // Немного приглушаем боковые иконки
        child: GestureDetector(
          onTap: () {
            if (item['page'] != null) {
              Navigator.pop(context);
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => item['page']));
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 35, // Базовый размер
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(item['icon'], color: colorScheme.primary, size: 36),
              ),
              const SizedBox(height: 8),
              Text(
                item['label'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      scale > 0.95 ? FontWeight.bold : FontWeight.normal,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
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
