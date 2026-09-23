import 'package:flutter/material.dart';

import '../core/state/app_controller.dart';
import '../core/state/app_scope.dart';
import '../core/theme/app_theme.dart';
import '../features/onboarding/presentation/parent_onboarding_flow.dart';
import 'app_shell.dart';

class App extends StatefulWidget {
  const App({this.controller, super.key});

  final AppController? controller;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AppController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: MaterialApp(
        title: 'Финансовый питомец',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AppEntry(),
      ),
    );
  }
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return controller.parentSetupCompleted
        ? const AppShell()
        : const ParentOnboardingFlow();
  }
}
