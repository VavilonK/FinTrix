/// Type-safe paths for the Phase 1 critical MVP assets.
///
/// Asset files are added separately as they are produced. This class must stay
/// aligned with the asset directories declared in `pubspec.yaml`.
abstract final class AppAssets {
  // Home fox animations: runtime Animated WebP converted from the WebM masters
  // in assets/animations/fox/source/ by tool/animations/convert_fox_animations.py.
  static const String foxHappyIdle =
      'assets/animations/fox/runtime/fox_happy_idle.webp';
  static const String foxHungryIdle =
      'assets/animations/fox/runtime/fox_hungry_idle.webp';
  static const String foxPetHappy =
      'assets/animations/fox/runtime/fox_pet_happy.webp';
  static const String foxPetHungry =
      'assets/animations/fox/runtime/fox_pet_hungry.webp';
  static const String foxFeedHappyBasic =
      'assets/animations/fox/runtime/fox_feed_happy_basic.webp';
  static const String foxFeedHappyHealthy =
      'assets/animations/fox/runtime/fox_feed_happy_healthy.webp';
  static const String foxFeedHappyTreat =
      'assets/animations/fox/runtime/fox_feed_happy_treat.webp';
  static const String foxFeedHungryBasic =
      'assets/animations/fox/runtime/fox_feed_hungry_basic.webp';
  static const String foxFeedHungryHealthy =
      'assets/animations/fox/runtime/fox_feed_hungry_healthy.webp';
  static const String foxFeedHungryTreat =
      'assets/animations/fox/runtime/fox_feed_hungry_treat.webp';
  // Anchor frames: happy/hungry idle pose for reduce motion and first paint.
  static const String foxHappyStill =
      'assets/animations/fox/runtime/fox_happy_still.webp';
  static const String foxHungryStill =
      'assets/animations/fox/runtime/fox_hungry_still.webp';

  // Canonical Fox
  static const String foxSittingHappyLevel05 =
      'assets/images/characters/fox/fox_sitting_happy_level_05.png';
  static const String foxPeekingHappyLevel05 =
      'assets/images/characters/fox/fox_peeking_happy_level_05.png';
  static const String foxStandingExcitedLevel05 =
      'assets/images/characters/fox/fox_standing_excited_level_05.png';
  static const String foxWalkingMapLevel05 =
      'assets/images/characters/fox/fox_walking_map_level_05.png';
  static const String foxHeadCelebratingLevel05 =
      'assets/images/characters/fox/fox_head_celebrating_level_05.png';
  static const String foxSittingHappyLevel01 =
      'assets/images/characters/fox/fox_sitting_happy_level_01.png';
  static const String foxHungrySad =
      'assets/images/characters/fox/fox_hungry_sad.png';
  static const String foxPettingLove =
      'assets/images/characters/fox/fox_petting_love.png';
  static const String foxPlayfulExcited =
      'assets/images/characters/fox/fox_playful_excited.png';
  static const String foxGameThinking =
      'assets/images/characters/fox/fox_game_thinking.png';
  static const String foxGameCheer =
      'assets/images/characters/fox/fox_game_cheer.png';

  // Avatar
  static const String avatarChildDefault =
      'assets/images/characters/avatars/avatar_child_default.png';

  // Backgrounds
  static const String backgroundBedroomDay =
      'assets/images/backgrounds/bg_bedroom_day.png';
  static const String backgroundMapMoscowDay =
      'assets/images/backgrounds/bg_map_moscow_day.png';
  static const String backgroundMapMoscowLargeDay =
      'assets/images/backgrounds/bg_map_moscow_large_day.png';
  static const String backgroundGameCenterInterior =
      'assets/images/backgrounds/bg_game_center_interior.webp';

  // Locations
  static const String locationGameCenterExterior =
      'assets/images/locations/location_game_center_exterior.png';

  // Location scenes
  static const String sceneGameCenter =
      'assets/images/locations/scenes/scene_game_center.png';
  static const String sceneSchool =
      'assets/images/locations/scenes/scene_school.png';
  static const String sceneCanteen =
      'assets/images/locations/scenes/scene_canteen.png';
  static const String sceneStationeryStore =
      'assets/images/locations/scenes/scene_stationery_store.png';
  static const String sceneSupermarket =
      'assets/images/locations/scenes/scene_supermarket.png';
  static const String sceneAmusementPark =
      'assets/images/locations/scenes/scene_amusement_park.png';
  static const String sceneCinema =
      'assets/images/locations/scenes/scene_cinema.png';
  static const String sceneMuseum =
      'assets/images/locations/scenes/scene_museum.png';
  static const String sceneLibrary =
      'assets/images/locations/scenes/scene_library.png';
  static const String sceneTransportHub =
      'assets/images/locations/scenes/scene_transport_hub.png';
  static const String sceneSportsCenter =
      'assets/images/locations/scenes/scene_sports_center.png';
  static const String sceneScienceCenter =
      'assets/images/locations/scenes/scene_science_center.png';

  // Finance objects
  static const String financeCoinSingle =
      'assets/images/objects/finance/finance_coin_single.png';
  static const String financePiggyBank =
      'assets/images/objects/finance/finance_piggy_bank.png';
  static const String financeWalletBlue =
      'assets/images/objects/finance/finance_wallet_blue.png';

  // Task objects
  static const String itemShoppingBasket =
      'assets/images/objects/tasks/item_shopping_basket.png';
  static const String itemCalculator =
      'assets/images/objects/tasks/item_calculator.png';
  static const String itemRewardGift =
      'assets/images/objects/tasks/item_reward_gift.png';
  static const String itemGameController =
      'assets/images/objects/tasks/item_game_controller.png';
  static const String itemClipboardComplete =
      'assets/images/objects/tasks/item_clipboard_complete.png';
  static const String homeTaskPreviewMap =
      'assets/images/objects/tasks/home_task_preview_map.png';
  static const String minigameTicTacToe =
      'assets/images/objects/tasks/minigame_tic_tac_toe.png';
  static const String minigameMemoryPairs =
      'assets/images/objects/tasks/minigame_memory_pairs.png';

  // Mini-game cards
  static const String memoryCoin =
      'assets/images/minigames/memory/finance_coin_single.png';
  static const String memoryPiggyBank =
      'assets/images/minigames/memory/finance_piggy_bank.png';
  static const String memoryBicycle =
      'assets/images/minigames/memory/goal_bicycle_blue.png';
  static const String memoryScooter =
      'assets/images/minigames/memory/goal_scooter_purple.png';
  static const String memoryBuildingSet =
      'assets/images/minigames/memory/goal_building_set.png';
  static const String memoryGameController =
      'assets/images/minigames/memory/item_game_controller.png';
  static const String memoryFoodBowl =
      'assets/images/minigames/memory/food_basic_bowl.png';
  static const String memoryGift = 'assets/images/minigames/memory/gift.png';
  static const String memoryBall = 'assets/images/minigames/memory/ball.png';
  static const String memoryBackpack =
      'assets/images/minigames/memory/backpack.png';
  static const String memoryCardBack =
      'assets/images/minigames/common/memory_card_back.png';

  // Goal objects
  static const String goalBicycleBlue =
      'assets/images/objects/goals/goal_bicycle_blue.png';
  static const String goalScooterPurple =
      'assets/images/objects/goals/goal_scooter_purple.png';
  static const String goalBuildingSet =
      'assets/images/objects/goals/goal_building_set.png';

  // Care objects
  static const String careFoodBowl =
      'assets/images/objects/care/care_food_bowl.png';
  static const String actionPetting =
      'assets/images/objects/care/action_petting.png';
  static const String careHealthySnack =
      'assets/images/objects/care/care_healthy_snack.png';
  static const String careTreatCupcake =
      'assets/images/objects/care/care_treat_cupcake.png';
  static const String foodBasicBowl =
      'assets/images/objects/care/food_basic_bowl.png';
  static const String foodHealthySnack =
      'assets/images/objects/care/food_healthy_snack.png';
  static const String foodTreatDessert =
      'assets/images/objects/care/food_treat_dessert.png';

  // Navigation icons
  static const String iconNavProfileFox =
      'assets/icons/navigation/ic_nav_profile_fox.svg';
}
