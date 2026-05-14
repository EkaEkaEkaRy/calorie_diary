import 'package:calorie_diary/models/challenge_model.dart';
import 'package:flutter/material.dart';

final List<ChallengeModel> allChallenges = [
  ChallengeModel(
    id: 1,
    title: "Чистый разум",
    description:
        "Никакого алкоголя в течение недели. Дай организму полноценно восстановиться.",
    icon: Icons.no_drinks_rounded,
    type: ChallengeType.cleanMind,
  ),
  ChallengeModel(
    id: 2,
    title: "Радуга на тарелке",
    description:
        "Добавляй овощи или фрукты в рацион каждый день этой недели, чтобы укрепить корни дерева.",
    icon: Icons.apple_rounded,
    type: ChallengeType.rainbowPlate,
  ),
  ChallengeModel(
    id: 3,
    title: "Чистый вечер",
    description:
        "Завершай все приемы пищи до 21:00, чтобы сон был крепким, а утро — легким.",
    icon: Icons.dark_mode_rounded,
    type: ChallengeType.cleanEvening,
  ),
  ChallengeModel(
    id: 4,
    title: "В яблочко",
    description:
        "Удерживай итоговую калорийность дня строго в пределах своей дневной нормы.",
    icon: Icons.track_changes_rounded,
    type: ChallengeType.inBullseye,
  ),
  ChallengeModel(
    id: 5,
    title: "Честный дневник",
    description:
        "Вноси в базу как минимум 3 главных приема пищи (Завтрак, Обед и Ужин) каждый день.",
    icon: Icons.menu_book_rounded,
    type: ChallengeType.honestDiary,
  ),
  ChallengeModel(
    id: 6,
    title: "Сахарный детокс",
    description:
        "Ограничь употребление сладостей: не более одного продукта из категории сладкого в день.",
    icon: Icons.cookie_rounded,
    type: ChallengeType.sugarDetox,
  ),
  ChallengeModel(
    id: 7,
    title: "Домашняя кухня",
    description: "Откажись от фастфуда на этой неделе. Только домашние блюда.",
    icon: Icons.soup_kitchen_rounded,
    type: ChallengeType.homeKitchen,
  ),
  ChallengeModel(
    id: 8,
    title: "Легкий вечер",
    description:
        "Постарайся, чтобы калорийность ужина составила не более 30% от твоей дневной нормы. Сделай акцент на сытный завтрак и обед.",
    icon: Icons.room_service,
    type: ChallengeType.lightEvening,
  )
];
