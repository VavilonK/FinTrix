import '../../../core/assets/app_assets.dart';
import '../domain/pet_progression.dart';

enum PetEmotionalState { neutral, happy, celebrating, hungry, loved }

enum PetVisualContext { home, profile, periodSummary, demoComplete }

abstract final class PetVisualResolver {
  static String assetFor({
    required PetGrowthStage stage,
    required PetEmotionalState emotionalState,
    required PetVisualContext context,
  }) {
    // Stage-specific artwork is not available yet. Keeping the decision here
    // lets future assets be connected without spreading stage checks in UI.
    return switch (emotionalState) {
      PetEmotionalState.hungry => AppAssets.foxHungrySad,
      PetEmotionalState.loved => AppAssets.foxPettingLove,
      _ => AppAssets.foxSittingHappyLevel05,
    };
  }
}
