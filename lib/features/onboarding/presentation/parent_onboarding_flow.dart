import 'package:flutter/material.dart';

import '../../../core/state/app_scope.dart';
import 'child_profile_setup_screen.dart';
import 'parent_access_setup_screen.dart';
import 'parent_welcome_screen.dart';
import 'setup_complete_screen.dart';

enum _OnboardingStep { welcome, parentAccess, childProfile, complete }

class ParentOnboardingFlow extends StatefulWidget {
  const ParentOnboardingFlow({super.key});

  @override
  State<ParentOnboardingFlow> createState() => _ParentOnboardingFlowState();
}

class _ParentOnboardingFlowState extends State<ParentOnboardingFlow> {
  _OnboardingStep _step = _OnboardingStep.welcome;
  bool _biometricEnabled = false;
  String _childName = '';
  int _childAge = 8;

  @override
  Widget build(BuildContext context) {
    final screen = switch (_step) {
      _OnboardingStep.welcome => ParentWelcomeScreen(
        onContinue: () => _goTo(_OnboardingStep.parentAccess),
      ),
      _OnboardingStep.parentAccess => ParentAccessSetupScreen(
        onCompleted: (biometricEnabled) {
          _biometricEnabled = biometricEnabled;
          _goTo(_OnboardingStep.childProfile);
        },
      ),
      _OnboardingStep.childProfile => ChildProfileSetupScreen(
        onCompleted: (result) {
          _childName = result.name;
          _childAge = result.age;
          _goTo(_OnboardingStep.complete);
        },
      ),
      _OnboardingStep.complete => SetupCompleteScreen(
        childName: _childName,
        onStart: () async {
          final state = AppScope.of(context);
          // The child's intro to the game follows the parent's setup once.
          state.requestTutorial();
          await state.completeParentSetup(
            childName: _childName,
            age: _childAge,
            biometricEnabled: _biometricEnabled,
          );
        },
      ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: KeyedSubtree(key: ValueKey(_step), child: screen),
    );
  }

  void _goTo(_OnboardingStep step) => setState(() => _step = step);
}
