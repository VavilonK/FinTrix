import '../../../core/assets/app_assets.dart';
import '../../home/presentation/pet_animation/pet_animation_models.dart';
import '../domain/pet_progression.dart';

enum PetEmotionalState { neutral, happy, celebrating, hungry, loved }

enum PetVisualContext { home, profile, periodSummary, demoComplete }

/// The one place that maps a growth stage to Ryzhik's visuals.
abstract final class PetVisualResolver {
  /// Still artwork for screens without the Home animation.
  static String assetFor({
    required PetGrowthStage stage,
    required PetEmotionalState emotionalState,
    required PetVisualContext context,
  }) {
    final hungry = emotionalState == PetEmotionalState.hungry;
    return switch (stage) {
      PetGrowthStage.little => switch (emotionalState) {
        PetEmotionalState.hungry => AppAssets.foxHungrySad,
        PetEmotionalState.loved => AppAssets.foxPettingLove,
        _ => AppAssets.foxSittingHappyLevel05,
      },
      PetGrowthStage.growing =>
        hungry ? AppAssets.foxSadLevel2 : AppAssets.foxHappyLevel2,
      PetGrowthStage.grown =>
        hungry ? AppAssets.foxSadLevel3 : AppAssets.foxHappyLevel3,
    };
  }

  /// Home animation clips of a growth stage.
  static PetAnimationSet animationSetFor(PetGrowthStage stage) =>
      PetAnimationCatalog.setFor(stage);
}
