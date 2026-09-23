import 'package:flutter/material.dart';

import '../../periods/presentation/period_summary_screen.dart';

class MissionCompleteScreen extends StatelessWidget {
  const MissionCompleteScreen({required this.onReturnHome, super.key});

  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    return PeriodSummaryScreen(onReturnHome: onReturnHome);
  }
}
