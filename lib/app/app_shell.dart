import 'package:flutter/material.dart';

import '../core/state/app_scope.dart';
import '../core/widgets/app_bottom_navigation.dart';
import '../features/budget/presentation/budget_screen.dart';
import '../features/goals/presentation/goals_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/pet_progression/domain/pet_progression.dart';
import '../features/pet_progression/presentation/pet_visual_resolver.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const List<AppBottomNavigationItem> _navigationItems = [
    AppBottomNavigationItem(
      label: 'Главная',
      icon: Icon(Icons.home_rounded),
      selectedIcon: Icon(Icons.home_rounded),
    ),
    AppBottomNavigationItem(
      label: 'Задания',
      icon: Icon(Icons.location_on_rounded),
      selectedIcon: Icon(Icons.location_on_rounded),
    ),
    AppBottomNavigationItem(
      label: 'Бюджет',
      icon: Icon(Icons.account_balance_wallet_rounded),
      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
    ),
    AppBottomNavigationItem(
      label: 'Цели',
      icon: Icon(Icons.star_rounded),
      selectedIcon: Icon(Icons.star_rounded),
    ),
    AppBottomNavigationItem(
      label: 'Профиль',
      icon: Icon(Icons.pets_rounded),
      selectedIcon: Icon(Icons.pets_rounded),
    ),
  ];

  int _currentIndex = 0;
  late final List<Widget?> _screens;
  PetGrowthStage? _precachedStage;

  @override
  void initState() {
    super.initState();
    _screens = List<Widget?>.filled(_navigationItems.length, null);
    _screens[_currentIndex] = _createScreen(_currentIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Home paints the anchor frame until its first clip frame is decoded, and
    // permanently under reduce motion: keep the current stage's stills ready.
    final stage = AppScope.of(context).petGrowthStage;
    if (_precachedStage != stage) {
      _precachedStage = stage;
      final set = PetVisualResolver.animationSetFor(stage);
      for (final still in [set.happyStill, set.hungryStill]) {
        precacheImage(
          AssetImage(still),
          context,
          onError: (error, stackTrace) {},
        );
      }
    }
  }

  void _selectTab(int index) {
    if (index < 0 || index >= _screens.length || index == _currentIndex) {
      return;
    }

    if (index == 0) AppScope.of(context).refreshPetState();
    setState(() {
      _screens[index] ??= _createScreen(index);
      _currentIndex = index;
      // Same type and slot retain Home state; only its visibility changes.
      _screens[0] = _createScreen(0);
    });
  }

  Widget _createScreen(int index) {
    return switch (index) {
      0 => HomeScreen(
        isActive: _currentIndex == 0,
        onOpenTasks: () => _selectTab(1),
        onOpenBudget: () => _selectTab(2),
        onOpenGoals: () => _selectTab(3),
      ),
      1 => TasksScreen(
        onReturnHome: () => _selectTab(0),
        onOpenTasks: () => _selectTab(1),
        onOpenBudget: () => _selectTab(2),
        onOpenGoals: () => _selectTab(3),
      ),
      2 => BudgetScreen(onOpenGoals: () => _selectTab(3)),
      3 => const GoalsScreen(),
      4 => ProfileScreen(onOpenGoals: () => _selectTab(3)),
      _ => throw RangeError.index(index, _screens, 'index'),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (final screen in _screens) screen ?? const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        items: _navigationItems,
        currentIndex: _currentIndex,
        onTap: _selectTab,
      ),
    );
  }
}
