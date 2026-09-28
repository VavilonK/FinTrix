import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../pet_progression/domain/pet_progression.dart';
import '../../domain/pet_models.dart';
import 'pet_animation_models.dart';

/// Single owner of Home's fox clip selection for every growth stage.
///
/// Gameplay stays in AppController; this only mirrors the resulting domain
/// state ([syncBaseState], [syncGrowthStage]) and plays one action clip at a
/// time on top of it. Clips resolve through [PetAnimationCatalog] from
/// growth stage + clip role, so no widget branches on the stage.
class PetAnimationCoordinator extends ChangeNotifier {
  PetAnimationCoordinator({
    required PetBaseState baseState,
    PetGrowthStage growthStage = PetGrowthStage.little,
    this._animationsEnabled = true,
  }) : _baseState = baseState,
       _growthStage = growthStage,
       _visualStage = growthStage,
       _current = PetAnimationCatalog.idleFor(baseState);

  /// Extra time for the idle to reach its anchor and the first frame to decode
  /// before a started action is abandoned.
  static const startTimeout = Duration(seconds: 8);

  /// Safety net only: the viewport reports the real last frame. Slow devices
  /// decode 60 fps clips below real time, so the net must not cut them short.
  static const endTimeoutFactor = 3;

  PetBaseState _baseState;

  /// Stage from the domain, and the stage of the clip on screen. They differ
  /// only while an action started before a growth step is still playing.
  PetGrowthStage _growthStage;
  PetGrowthStage _visualStage;
  bool _animationsEnabled;
  PetAnimationState _current;
  int _playId = 0;
  Timer? _watchdog;

  PetBaseState get baseState => _baseState;
  PetGrowthStage get growthStage => _growthStage;
  PetGrowthStage get visualStage => _visualStage;
  bool get animationsEnabled => _animationsEnabled;
  PetAnimationState get current => _current;
  PetAnimationDefinition get currentDefinition =>
      PetAnimationCatalog.definition(_visualStage, _current);

  /// Anchor frame of the current domain pose, for reduce motion.
  String get stillAsset =>
      PetAnimationCatalog.setFor(_growthStage).stillFor(_baseState);

  /// The idle loop whose first frame is [stillAsset].
  String get stillIdleAsset =>
      PetAnimationCatalog.setFor(_growthStage)
          .assetFor(PetAnimationCatalog.idleFor(_baseState));

  /// Changes whenever a clip should start from its first frame.
  int get playId => _playId;
  bool get isActionPlaying => !_current.isIdle;

  /// Clips of the stage on screen that may be requested next, plus the new
  /// stage's idle when a growth step waits for the running clip to end.
  /// Other stages are never kept decoded.
  List<PetAnimationDefinition> get preloadSet => [
    for (final state in PetAnimationCatalog.preloadFor(_baseState))
      PetAnimationCatalog.definition(_visualStage, state),
    if (_growthStage != _visualStage)
      PetAnimationCatalog.definition(
        _growthStage,
        PetAnimationCatalog.idleFor(_baseState),
      ),
  ];

  /// Mirrors the persisted pet state. During an action only the destination
  /// changes; the running clip settles into it when it ends.
  void syncBaseState(PetBaseState state) {
    if (_baseState == state) return;
    _baseState = state;
    if (!isActionPlaying) _show(PetAnimationCatalog.idleFor(state));
    notifyListeners();
  }

  /// Mirrors the persisted growth stage. A running clip finishes in its own
  /// stage; the new stage's idle follows it.
  void syncGrowthStage(PetGrowthStage stage) {
    if (_growthStage == stage) return;
    _growthStage = stage;
    if (!isActionPlaying) {
      _visualStage = stage;
      _show(PetAnimationCatalog.idleFor(_baseState));
    }
    notifyListeners();
  }

  void setAnimationsEnabled(bool enabled) {
    if (_animationsEnabled == enabled) return;
    _animationsEnabled = enabled;
    if (!enabled && isActionPlaying) {
      _settle();
    } else {
      notifyListeners();
    }
  }

  /// Returns false when another action clip is still playing.
  bool playPet() {
    if (isActionPlaying) return false;
    if (_animationsEnabled) _start(PetAnimationCatalog.petFor(_baseState));
    return true;
  }

  /// Call after AppController.feedPet succeeded. [after] is the domain state
  /// the feeding produced; the clip is chosen from the pose currently shown.
  bool playFeed(FoodType food, {required PetBaseState after}) {
    if (isActionPlaying) return false;
    final clip = PetAnimationCatalog.feedFor(_baseState, food);
    _baseState = after;
    if (_animationsEnabled && clip.endState == after) {
      _start(clip);
    } else {
      // No clip ends in [after] (e.g. a snack too small to end hunger):
      // show the real state instead of a transition that would contradict it.
      _show(PetAnimationCatalog.idleFor(after));
      notifyListeners();
    }
    return true;
  }

  /// The viewport shows the first frame of [playId]; arms the end watchdog.
  void actionStarted(int playId) {
    if (playId != _playId || !isActionPlaying) return;
    _arm(currentDefinition.duration * endTimeoutFactor);
  }

  /// The viewport finished the last frame of [playId].
  void actionCompleted(int playId) {
    if (playId != _playId || !isActionPlaying) return;
    _settle();
  }

  /// Drops any running action (tab hidden, app backgrounded) so a return
  /// shows the current domain idle instead of a stale half-played clip.
  void interrupt() {
    if (isActionPlaying) _settle();
  }

  void _start(PetAnimationState clip) {
    _show(clip);
    _arm(currentDefinition.duration + startTimeout);
    notifyListeners();
  }

  void _settle() {
    _visualStage = _growthStage;
    _show(PetAnimationCatalog.idleFor(_baseState));
    notifyListeners();
  }

  void _show(PetAnimationState state) {
    _watchdog?.cancel();
    _watchdog = null;
    _current = state;
    _playId += 1;
  }

  void _arm(Duration timeout) {
    _watchdog?.cancel();
    final id = _playId;
    _watchdog = Timer(timeout, () => actionCompleted(id));
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }
}
