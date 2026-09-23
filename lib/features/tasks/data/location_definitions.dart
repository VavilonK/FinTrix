import 'package:flutter/widgets.dart';

import '../../../core/assets/app_assets.dart';
import '../../missions/domain/mission_models.dart';
import '../domain/location_definition.dart';

abstract final class LocationDefinitions {
  static const List<LocationDefinition> all = [
    LocationDefinition(
      id: 'game_center',
      title: 'Игровой центр',
      sceneAsset: AppAssets.sceneGameCenter,
      normalizedPosition: Offset(0.70, 0.60),
      preferredThemes: {
        TaskTheme.entertainment,
        TaskTheme.logic,
        TaskTheme.math,
      },
    ),
    LocationDefinition(
      id: 'school',
      title: 'Школа',
      sceneAsset: AppAssets.sceneSchool,
      normalizedPosition: Offset(0.22, 0.18),
      preferredThemes: {TaskTheme.math, TaskTheme.logic},
    ),
    LocationDefinition(
      id: 'canteen',
      title: 'Столовая',
      sceneAsset: AppAssets.sceneCanteen,
      normalizedPosition: Offset(0.38, 0.28),
      preferredThemes: {TaskTheme.finance, TaskTheme.math},
    ),
    LocationDefinition(
      id: 'stationery_store',
      title: 'Канцелярский магазин',
      sceneAsset: AppAssets.sceneStationeryStore,
      normalizedPosition: Offset(0.52, 0.16),
      preferredThemes: {TaskTheme.finance, TaskTheme.attention, TaskTheme.math},
    ),
    LocationDefinition(
      id: 'supermarket',
      title: 'Супермаркет',
      sceneAsset: AppAssets.sceneSupermarket,
      normalizedPosition: Offset(0.79, 0.19),
      preferredThemes: {TaskTheme.finance, TaskTheme.logic, TaskTheme.math},
    ),
    LocationDefinition(
      id: 'amusement_park',
      title: 'Парк аттракционов',
      sceneAsset: AppAssets.sceneAmusementPark,
      normalizedPosition: Offset(0.16, 0.52),
      preferredThemes: {TaskTheme.entertainment, TaskTheme.finance},
    ),
    LocationDefinition(
      id: 'cinema',
      title: 'Кинотеатр',
      sceneAsset: AppAssets.sceneCinema,
      normalizedPosition: Offset(0.84, 0.42),
      preferredThemes: {TaskTheme.entertainment, TaskTheme.finance},
    ),
    LocationDefinition(
      id: 'museum',
      title: 'Музей',
      sceneAsset: AppAssets.sceneMuseum,
      normalizedPosition: Offset(0.58, 0.35),
      preferredThemes: {TaskTheme.attention, TaskTheme.memory, TaskTheme.logic},
    ),
    LocationDefinition(
      id: 'library',
      title: 'Библиотека',
      sceneAsset: AppAssets.sceneLibrary,
      normalizedPosition: Offset(0.28, 0.68),
      preferredThemes: {TaskTheme.logic, TaskTheme.memory},
    ),
    LocationDefinition(
      id: 'transport_hub',
      title: 'Транспортный узел',
      sceneAsset: AppAssets.sceneTransportHub,
      normalizedPosition: Offset(0.75, 0.78),
      preferredThemes: {TaskTheme.math, TaskTheme.logic, TaskTheme.finance},
    ),
    LocationDefinition(
      id: 'sports_center',
      title: 'Спортивный центр',
      sceneAsset: AppAssets.sceneSportsCenter,
      normalizedPosition: Offset(0.47, 0.83),
      preferredThemes: {TaskTheme.logic, TaskTheme.entertainment},
    ),
    LocationDefinition(
      id: 'science_center',
      title: 'Научный центр',
      sceneAsset: AppAssets.sceneScienceCenter,
      normalizedPosition: Offset(0.19, 0.86),
      preferredThemes: {TaskTheme.logic, TaskTheme.math, TaskTheme.memory},
    ),
  ];

  static LocationDefinition byId(String id) {
    return all.firstWhere(
      (location) => location.id == id,
      orElse: () => all.first,
    );
  }
}
