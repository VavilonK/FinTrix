import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/pet_models.dart';
import 'pet_animation_models.dart';

/// Single owner of Home's fox clip selection.
///
/// Gameplay stays in AppController; this only mirrors the resulting domain
/// state ([syncBaseState]) and plays one action clip at a time on top of it.
class PetAnimationCoordinator extends ChangeNotifier {
  PetAnimationCoordinator({
    required PetBaseState baseState,
    this._animationsEnabled = true,
  }) : _baseState = baseState,
       _current = PetAnimationCatalog.idleFor(baseState);

  /// Extra time for the idle to reach its anchor and the first frame to decode
  /// before a started action is abandoned.
  static const startTimeout = Duration(seconds: 8);

  /// Safety net only: the viewport reports the real last frame. Slow devices
  /// decode 60 fps clips below real time, so the net must not cut them short.
  static const endTimeoutFactor = 3;

  PetBaseState _baseState;
  bool _animationsEnabled;
  PetAnimationState _current;
  int _playId = 0;
  Timer? _watchdog;

  PetBaseState get baseState => _baseState;
  bool get animationsEnabled => _animationsEnabled;
  PetAnimationState get current => _current;
  PetAnimationDefinition get currentDefinition => _current.definition;

  /// Changes whenever a clip should start from its first frame.
  int get playId => _playId;
  bool get isActionPlaying => !_current.isIdle;

  List<PetAnimationState> get preloadSet =>
      PetAnimationCatalog.preloadFor(_baseState);

  /// Mirrors the persisted pet state. During an action only the destination
  /// changes; the running clip settles into it when it ends.
  void syncBaseState(PetBaseState state) {
    if (_baseState == state) return;
    _baseState = state;
    if (!isActionPlaying) _show(PetAnimationCatalog.idleFor(state));
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
    if (_animationsEnabled && clip.definition.endState == after) {
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
