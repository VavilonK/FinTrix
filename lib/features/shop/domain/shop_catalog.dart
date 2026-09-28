import '../../../core/assets/app_assets.dart';
import '../../budget/domain/budget_usage.dart';
import '../../home/domain/pet_models.dart';

/// Sections of the purchase sheet. Food and care are essential spending;
/// toys and decorations are wants the child may postpone without penalty.
enum ShopSection {
  food,
  care,
  toys;

  String get title => switch (this) {
    food => 'Еда',
    care => 'Уход',
    toys => 'Игрушки',
  };
}

/// Where a bought room item is drawn, in pixels of bg_bedroom_day (941x1672).
class RoomSlot {
  const RoomSlot({
    required this.centerX,
    required this.bottomY,
    required this.width,
  });

  final double centerX;
  final double bottomY;
  final double width;
}

/// One purchasable item. Effects are applied by AppController.buyItem.
class ShopItem {
  const ShopItem({
    required this.id,
    required this.section,
    required this.title,
    required this.asset,
    required this.cost,
    required this.category,
    this.satietyGain = 0,
    this.moodGain = 0,
    this.careGain = 0,
    this.food,
    this.roomSlot,
    this.note,
  });

  final String id;
  final ShopSection section;
  final String title;
  final String asset;
  final int cost;
  final ExpenseCategory category;
  final int satietyGain;
  final int moodGain;
  final int careGain;

  /// Food items reuse the feeding clips of their food type.
  final FoodType? food;

  /// Room items are bought once and stay in the room.
  final RoomSlot? roomSlot;

  /// Extra line shown on the card, e.g. the lasting effect of a toy.
  final String? note;

  bool get isPermanent => roomSlot != null;

  /// "Сытость +30 · Настроение +4" — effects the child sees before buying.
  String get effectsLabel => [
    if (satietyGain > 0) 'Сытость +$satietyGain',
    if (careGain > 0) 'Забота +$careGain',
    if (moodGain > 0) 'Настроение +$moodGain',
  ].join(' · ');

  String get categoryLabel => switch (category) {
    ExpenseCategory.essential => 'Важное',
    ExpenseCategory.want => 'Приятное',
  };
}

abstract final class ShopCatalog {
  static ShopItem foodItem(FoodType type) =>
      items.firstWhere((item) => item.food == type);

  static final List<ShopItem> items = [
    for (final type in FoodType.values)
      ShopItem(
        id: 'food_${type.name}',
        section: ShopSection.food,
        title: switch (type) {
          FoodType.basic => 'Корм',
          FoodType.healthy => 'Полезный перекус',
          FoodType.treat => 'Вкусняшка',
        },
        asset: switch (type) {
          FoodType.basic => AppAssets.foodBasicBowl,
          FoodType.healthy => AppAssets.foodHealthySnack,
          FoodType.treat => AppAssets.foodTreatDessert,
        },
        cost: type.cost,
        category: type.expenseCategory,
        satietyGain: type.satietyGain,
        moodGain: type.moodGain,
        careGain: type.careGain,
        food: type,
      ),
    const ShopItem(
      id: 'care_brush',
      section: ShopSection.care,
      title: 'Расчёска',
      asset: AppAssets.shopBrush,
      cost: 20,
      category: ExpenseCategory.essential,
      careGain: 20,
    ),
    const ShopItem(
      id: 'care_bath_set',
      section: ShopSection.care,
      title: 'Набор для купания',
      asset: AppAssets.shopBathSet,
      cost: 35,
      category: ExpenseCategory.essential,
      careGain: 30,
      moodGain: 5,
    ),
    const ShopItem(
      id: 'toy_teddy',
      section: ShopSection.toys,
      title: 'Плюшевый мишка',
      asset: AppAssets.shopTeddy,
      cost: 60,
      category: ExpenseCategory.want,
      moodGain: 15,
      note: 'Останется в комнате',
      roomSlot: RoomSlot(centerX: 128, bottomY: 800, width: 84),
    ),
    const ShopItem(
      id: 'toy_star_garland',
      section: ShopSection.toys,
      title: 'Гирлянда',
      asset: AppAssets.shopStarGarland,
      cost: 80,
      category: ExpenseCategory.want,
      moodGain: 20,
      note: 'Останется в комнате',
      roomSlot: RoomSlot(centerX: 700, bottomY: 690, width: 250),
    ),
    const ShopItem(
      id: 'toy_pouf',
      section: ShopSection.toys,
      title: 'Пуфик',
      asset: AppAssets.shopPouf,
      cost: 100,
      category: ExpenseCategory.want,
      moodGain: 25,
      note: 'Останется в комнате',
      roomSlot: RoomSlot(centerX: 760, bottomY: 1090, width: 150),
    ),
  ];

  static List<ShopItem> section(ShopSection section) =>
      items.where((item) => item.section == section).toList(growable: false);

  static ShopItem? byId(String id) =>
      items.where((item) => item.id == id).firstOrNull;

  /// Each room item slows the mood decay by this share.
  static const double moodDecayReliefPerRoomItem = 0.1;
}

enum ShopPurchaseResult {
  success,
  insufficientFunds,
  requiresConfirmation,
  alreadyOwned,
}

/// What a successful purchase changed, for the feedback shown to the child.
class PurchaseReceipt {
  const PurchaseReceipt({
    required this.item,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.petBefore,
    required this.petAfter,
  });

  final ShopItem item;
  final int balanceBefore;
  final int balanceAfter;
  final PetState petBefore;
  final PetState petAfter;

  int get spent => balanceBefore - balanceAfter;
  int get satietyDelta => petAfter.satiety - petBefore.satiety;
  int get moodDelta => petAfter.mood - petBefore.mood;
  int get careDelta => petAfter.care - petBefore.care;
}
