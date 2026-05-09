import 'package:calorie_diary/pages/full_list_page.dart';
import 'package:calorie_diary/pages/memory_list_page.dart';
import 'package:flutter/material.dart';

class BottomSwipeMenu extends StatefulWidget {
  @override
  _BottomSwipeMenuState createState() => _BottomSwipeMenuState();
}

class _BottomSwipeMenuState extends State<BottomSwipeMenu> {
  final List<IconData> icons = [
    Icons.app_registration_rounded,
    Icons.photo_album
    //Icons.star,
    //Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: icons.map((icon) {
                  // Обработчик для иконки app_registration_rounded
                  if (icon == Icons.app_registration_rounded) {
                    return Padding(
                      padding: EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .pop(); // закрываем меню перед навигацией (по желанию)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FullListPage()),
                          );
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.green[100],
                          child: Icon(icon, color: Colors.green, size: 36),
                        ),
                      ),
                    );
                  } else if (icon == Icons.photo_album) {
                    return Padding(
                      padding: EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .pop(); // закрываем меню перед навигацией (по желанию)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MemoryListPage()),
                          );
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.green[100],
                          child: Icon(icon, color: Colors.green, size: 36),
                        ),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green[100],
                        child: Icon(icon, color: Colors.green, size: 36),
                      ),
                    );
                  }
                }).toList(),
              ),
            ],
          ),
        );
      },
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
