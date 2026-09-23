import 'package:flutter/widgets.dart';

import '../../missions/domain/mission_models.dart';

class LocationDefinition {
  const LocationDefinition({
    required this.id,
    required this.title,
    required this.sceneAsset,
    required this.normalizedPosition,
    required this.preferredThemes,
  });

  final String id;
  final String title;
  final String sceneAsset;
  final Offset normalizedPosition;
  final Set<TaskTheme> preferredThemes;
}
