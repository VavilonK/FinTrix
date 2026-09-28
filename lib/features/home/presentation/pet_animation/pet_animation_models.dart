import '../../../../core/assets/app_assets.dart';
import '../../../pet_progression/domain/pet_progression.dart';
import '../../domain/pet_models.dart';

/// Visual base pose derived from the persisted [PetState]; never stored.
enum PetBaseState {
  happy,
  hungry;

  static PetBaseState of(PetState pet) =>
      pet.isHungry ? PetBaseState.hungry : PetBaseState.happy;
}

/// The role of the clip on Home, independent of the growth stage.
/// Idle clips loop; the rest play once.
enum PetAnimationState {
  happyIdle,
  hungryIdle,
  petHappy,
  petHungry,
  feedHappyBasic,
  feedHappyHealthy,
  feedHappyTreat,
  feedHungryBasic,
  feedHungryHealthy,
  feedHungryTreat;

  bool get isIdle => this == happyIdle || this == hungryIdle;

  /// Pose the clip starts in; identical for every growth stage.
  PetBaseState get startState => switch (this) {
    happyIdle ||
    petHappy ||
    feedHappyBasic ||
    feedHappyHealthy ||
    feedHappyTreat => PetBaseState.happy,
    _ => PetBaseState.hungry,
  };

  /// Pose the clip ends in: hungry feeds end happy.
  PetBaseState get endState => switch (this) {
    hungryIdle || petHungry => PetBaseState.hungry,
    _ => PetBaseState.happy,
  };

  bool get loops => isIdle;

  /// Real playback length of the runtime assets. Every stage was generated
  /// with the same frame counts (298/300/210/306 frames at 60 fps).
  Duration get duration => switch (this) {
    happyIdle => const Duration(milliseconds: 4967),
    hungryIdle => const Duration(milliseconds: 5000),
    petHappy || petHungry => const Duration(milliseconds: 3500),
    _ => const Duration(milliseconds: 5100),
  };
}

/// Where a stage's character sits inside the shared 960px source canvas and
/// how tall it should appear relative to Stage 1. Home aligns every stage's
/// paws on the rug and scales the canvas so the anchor pose is [growth] times
/// Stage 1's height, which keeps the growing-up effect even though the
/// generated Stage 2/3 masters frame the fox smaller.
class PetStageVisualConfig {
  const PetStageVisualConfig({
    required this.anchorTop,
    required this.anchorBottom,
    required this.growth,
  });

  /// Opaque rows (alpha > 32) of the happy anchor frame in the 960px canvas.
  final double anchorTop;
  final double anchorBottom;

  /// Visible height relative to Stage 1.
  final double growth;

  static const double sourceSide = 960;

  double get visibleFraction => (anchorBottom - anchorTop + 1) / sourceSide;
  double get pawLineFraction => (anchorBottom + 1) / sourceSide;
}

/// All Home clips of one growth stage. Stage selection happens only in
/// [PetAnimationCatalog.setFor]; widgets never build asset paths.
class PetAnimationSet {
  const PetAnimationSet({
    required this.happyIdle,
    required this.hungryIdle,
    required this.petHappy,
    required this.petHungry,
    required this.feedHappyBasic,
    required this.feedHappyHealthy,
    required this.feedHappyTreat,
    required this.feedHungryBasic,
    required this.feedHungryHealthy,
    required this.feedHungryTreat,
    required this.happyStill,
    required this.hungryStill,
    required this.happyIdleAnchorWindow,
    required this.hungryIdleAnchorWindow,
    required this.visual,
  });

  final String happyIdle;
  final String hungryIdle;
  final String petHappy;
  final String petHungry;
  final String feedHappyBasic;
  final String feedHappyHealthy;
  final String feedHappyTreat;
  final String feedHungryBasic;
  final String feedHungryHealthy;
  final String feedHungryTreat;

  /// First frames of the idle loops: reduce motion and first paint.
  final String happyStill;
  final String hungryStill;

  /// Opening span of each idle loop that still matches its anchor pose, so an
  /// action may cut in there without a visible jump.
  final Duration happyIdleAnchorWindow;
  final Duration hungryIdleAnchorWindow;

  final PetStageVisualConfig visual;

  String assetFor(PetAnimationState state) => switch (state) {
    PetAnimationState.happyIdle => happyIdle,
    PetAnimationState.hungryIdle => hungryIdle,
    PetAnimationState.petHappy => petHappy,
    PetAnimationState.petHungry => petHungry,
    PetAnimationState.feedHappyBasic => feedHappyBasic,
    PetAnimationState.feedHappyHealthy => feedHappyHealthy,
    PetAnimationState.feedHappyTreat => feedHappyTreat,
    PetAnimationState.feedHungryBasic => feedHungryBasic,
    PetAnimationState.feedHungryHealthy => feedHungryHealthy,
    PetAnimationState.feedHungryTreat => feedHungryTreat,
  };

  String stillFor(PetBaseState base) => switch (base) {
    PetBaseState.happy => happyStill,
    PetBaseState.hungry => hungryStill,
  };

  List<String> get allAssets => [
    for (final state in PetAnimationState.values) assetFor(state),
    happyStill,
    hungryStill,
  ];
}

/// A clip resolved for a growth stage: what the viewport plays.
class PetAnimationDefinition {
  const PetAnimationDefinition({
    required this.stage,
    required this.state,
    required this.asset,
    required this.stillAsset,
    required this.anchorWindow,
    required this.visual,
  });

  final PetGrowthStage stage;
  final PetAnimationState state;
  final String asset;

  /// Anchor frame shown before the first decoded frame and under reduce motion.
  final String stillAsset;

  /// For looping idles: the opening span that matches the anchor pose.
  final Duration anchorWindow;
  final PetStageVisualConfig visual;

  /// The idle loop whose first frame is [stillAsset].
  String get stillIdleAsset =>
      PetAnimationCatalog.setFor(stage)
          .assetFor(PetAnimationCatalog.idleFor(startState));

  Duration get duration => state.duration;
  bool get loops => state.loops;
  PetBaseState get startState => state.startState;
  PetBaseState get endState => state.endState;
}

abstract final class PetAnimationCatalog {
  static const sets = <PetGrowthStage, PetAnimationSet>{
    PetGrowthStage.little: PetAnimationSet(
      happyIdle: AppAssets.foxHappyIdle,
      hungryIdle: AppAssets.foxHungryIdle,
      petHappy: AppAssets.foxPetHappy,
      petHungry: AppAssets.foxPetHungry,
      feedHappyBasic: AppAssets.foxFeedHappyBasic,
      feedHappyHealthy: AppAssets.foxFeedHappyHealthy,
      feedHappyTreat: AppAssets.foxFeedHappyTreat,
      feedHungryBasic: AppAssets.foxFeedHungryBasic,
      feedHungryHealthy: AppAssets.foxFeedHungryHealthy,
      feedHungryTreat: AppAssets.foxFeedHungryTreat,
      happyStill: AppAssets.foxHappyStill,
      hungryStill: AppAssets.foxHungryStill,
      // Measured on the 60 fps runtime frames against frame 0.
      happyIdleAnchorWindow: Duration(milliseconds: 700),
      hungryIdleAnchorWindow: Duration(milliseconds: 33),
      visual: PetStageVisualConfig(anchorTop: 61, anchorBottom: 959, growth: 1),
    ),
    PetGrowthStage.growing: PetAnimationSet(
      happyIdle: AppAssets.foxStage2HappyIdle,
      hungryIdle: AppAssets.foxStage2HungryIdle,
      petHappy: AppAssets.foxStage2PetHappy,
      petHungry: AppAssets.foxStage2PetHungry,
      feedHappyBasic: AppAssets.foxStage2FeedHappyBasic,
      feedHappyHealthy: AppAssets.foxStage2FeedHappyHealthy,
      feedHappyTreat: AppAssets.foxStage2FeedHappyTreat,
      feedHungryBasic: AppAssets.foxStage2FeedHungryBasic,
      feedHungryHealthy: AppAssets.foxStage2FeedHungryHealthy,
      feedHungryTreat: AppAssets.foxStage2FeedHungryTreat,
      happyStill: AppAssets.foxStage2HappyStill,
      hungryStill: AppAssets.foxStage2HungryStill,
      happyIdleAnchorWindow: Duration(milliseconds: 850),
      hungryIdleAnchorWindow: Duration(milliseconds: 67),
      visual: PetStageVisualConfig(
        anchorTop: 86,
        anchorBottom: 910,
        growth: 1.08,
      ),
    ),
    PetGrowthStage.grown: PetAnimationSet(
      happyIdle: AppAssets.foxStage3HappyIdle,
      hungryIdle: AppAssets.foxStage3HungryIdle,
      petHappy: AppAssets.foxStage3PetHappy,
      petHungry: AppAssets.foxStage3PetHungry,
      feedHappyBasic: AppAssets.foxStage3FeedHappyBasic,
      feedHappyHealthy: AppAssets.foxStage3FeedHappyHealthy,
      feedHappyTreat: AppAssets.foxStage3FeedHappyTreat,
      feedHungryBasic: AppAssets.foxStage3FeedHungryBasic,
      feedHungryHealthy: AppAssets.foxStage3FeedHungryHealthy,
      feedHungryTreat: AppAssets.foxStage3FeedHungryTreat,
      happyStill: AppAssets.foxStage3HappyStill,
      hungryStill: AppAssets.foxStage3HungryStill,
      happyIdleAnchorWindow: Duration(milliseconds: 883),
      hungryIdleAnchorWindow: Duration(milliseconds: 83),
      visual: PetStageVisualConfig(
        anchorTop: 109,
        anchorBottom: 897,
        growth: 1.16,
      ),
    ),
  };

  static PetAnimationSet setFor(PetGrowthStage stage) => sets[stage]!;

  /// Growth stage + clip role -> the runtime clip to play.
  static PetAnimationDefinition definition(
    PetGrowthStage stage,
    PetAnimationState state,
  ) {
    final set = setFor(stage);
    return PetAnimationDefinition(
      stage: stage,
      state: state,
      asset: set.assetFor(state),
      stillAsset: set.stillFor(state.startState),
      anchorWindow: switch (state) {
        PetAnimationState.happyIdle => set.happyIdleAnchorWindow,
        PetAnimationState.hungryIdle => set.hungryIdleAnchorWindow,
        _ => Duration.zero,
      },
      visual: set.visual,
    );
  }

  static PetAnimationState idleFor(PetBaseState base) => switch (base) {
    PetBaseState.happy => PetAnimationState.happyIdle,
    PetBaseState.hungry => PetAnimationState.hungryIdle,
  };

  static PetAnimationState petFor(PetBaseState base) => switch (base) {
    PetBaseState.happy => PetAnimationState.petHappy,
    PetBaseState.hungry => PetAnimationState.petHungry,
  };

  static PetAnimationState feedFor(
    PetBaseState base,
    FoodType food,
  ) => switch ((base, food)) {
    (PetBaseState.happy, FoodType.basic) => PetAnimationState.feedHappyBasic,
    (PetBaseState.happy, FoodType.healthy) =>
      PetAnimationState.feedHappyHealthy,
    (PetBaseState.happy, FoodType.treat) => PetAnimationState.feedHappyTreat,
    (PetBaseState.hungry, FoodType.basic) => PetAnimationState.feedHungryBasic,
    (PetBaseState.hungry, FoodType.healthy) =>
      PetAnimationState.feedHungryHealthy,
    (PetBaseState.hungry, FoodType.treat) => PetAnimationState.feedHungryTreat,
  };

  /// Clips that may be requested next from [base], idle first.
  static List<PetAnimationState> preloadFor(PetBaseState base) => [
    idleFor(base),
    petFor(base),
    for (final food in FoodType.values) feedFor(base, food),
    // A hungry feed ends in the happy idle, which must be ready at the cut.
    if (base == PetBaseState.hungry) PetAnimationState.happyIdle,
  ];
}
