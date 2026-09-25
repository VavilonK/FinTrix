import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../missions/domain/mission_models.dart';
import '../../data/location_definitions.dart';
import '../../domain/location_definition.dart';
import 'map_camera.dart';
import 'mission_card.dart';

class MoscowMapStage extends StatefulWidget {
  const MoscowMapStage({
    required this.mission,
    required this.onStartMission,
    required this.topOverlayHeight,
    this.visitedLocationIds = const {},
    super.key,
  });

  final DailyMission mission;
  final VoidCallback onStartMission;
  final double topOverlayHeight;
  final Set<String> visitedLocationIds;

  @override
  State<MoscowMapStage> createState() => _MoscowMapStageState();
}

class _MoscowMapStageState extends State<MoscowMapStage>
    with TickerProviderStateMixin {
  static const Size _sceneSize = Size(1080, 1280);

  final TransformationController _mapController = TransformationController();
  late final AnimationController _focusController;
  late final AnimationController _pulseController;
  Matrix4Tween? _focusTween;
  String? _focusedLocationId;
  bool _userControlsCamera = false;
  String? _tooltipLocationId;

  LocationDefinition get _activeLocation =>
      LocationDefinitions.byId(widget.mission.locationId);

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..addListener(_animateFocus);
    _pulseController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1150),
          )
          ..forward().then((_) {
            if (mounted) _pulseController.reverse();
          });
  }

  @override
  void didUpdateWidget(covariant MoscowMapStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mission.locationId != widget.mission.locationId) {
      _focusedLocationId = null;
      _userControlsCamera = false;
    }
  }

  @override
  void dispose() {
    _focusController
      ..removeListener(_animateFocus)
      ..dispose();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _animateFocus() {
    final tween = _focusTween;
    if (tween == null) return;
    final progress = Curves.easeOutCubic.transform(_focusController.value);
    _mapController.value = tween.lerp(progress);
  }

  void _focusActiveLocation(MapCameraPlan plan) {
    _focusTween = Matrix4Tween(
      begin: _mapController.value,
      end: plan.transform,
    );
    _focusController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Restore the original 178px footprint (172px card + 6px bottom gap).
        final baseCardHeight = constraints.maxWidth < 400 ? 196.0 : 178.0;
        final missionCardHeight =
            (baseCardHeight +
                    (MediaQuery.textScalerOf(context).scale(1) - 1) * 160)
                .clamp(baseCardHeight, constraints.maxHeight * 0.62);
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final cameraPlan = MapCamera.plan(
          viewport: viewport,
          sceneSize: _sceneSize,
          normalizedLocation: _activeLocation.normalizedPosition,
          bottomOverlayHeight: missionCardHeight,
          topOverlayHeight: widget.topOverlayHeight,
        );
        if (_focusedLocationId != _activeLocation.id) {
          _focusedLocationId = _activeLocation.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_userControlsCamera) {
              _focusActiveLocation(cameraPlan);
            }
          });
        }
        final visibleMapHeight = math.max(
          1.0,
          constraints.maxHeight - missionCardHeight,
        );
        final minScale = math.max(
          constraints.maxWidth / _sceneSize.width,
          visibleMapHeight / _sceneSize.height,
        );

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: const Color(0xFFBFE2F4),
                child: InteractiveViewer(
                  key: const ValueKey('moscow_interactive_map'),
                  transformationController: _mapController,
                  constrained: false,
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: minScale,
                  maxScale: 1.35,
                  boundaryMargin: EdgeInsets.only(bottom: missionCardHeight),
                  clipBehavior: Clip.hardEdge,
                  onInteractionStart: (_) {
                    _userControlsCamera = true;
                    _focusController.stop();
                    _focusTween = null;
                  },
                  child: SizedBox.fromSize(
                    size: _sceneSize,
                    child: _MapScene(
                      activeLocation: _activeLocation,
                      foxPoint: cameraPlan.foxPoint,
                      visitedLocationIds: widget.visitedLocationIds,
                      pulse: _pulseController,
                      onLocationTap: (location) {
                        if (location.id == _activeLocation.id) return;
                        setState(() => _tooltipLocationId = location.id);
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                top: widget.topOverlayHeight + 8,
                child: IgnorePointer(
                  ignoring: _tooltipLocationId == null,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _tooltipLocationId == null
                        ? const SizedBox.shrink()
                        : _LocationTooltip(
                            key: ValueKey(_tooltipLocationId),
                            location: LocationDefinitions.byId(
                              _tooltipLocationId!,
                            ),
                            onClose: () {
                              setState(() => _tooltipLocationId = null);
                            },
                          ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 6,
                child: SizedBox(
                  height: missionCardHeight - 6,
                  child: MissionCard(
                    mission: widget.mission,
                    location: _activeLocation,
                    onStartMission: widget.onStartMission,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapScene extends StatelessWidget {
  const _MapScene({
    required this.activeLocation,
    required this.foxPoint,
    required this.visitedLocationIds,
    required this.pulse,
    required this.onLocationTap,
  });

  final LocationDefinition activeLocation;
  final Offset foxPoint;
  final Set<String> visitedLocationIds;
  final Animation<double> pulse;
  final ValueChanged<LocationDefinition> onLocationTap;

  static const Size _size = Size(1080, 1280);

  @override
  Widget build(BuildContext context) {
    final activePoint = Offset(
      activeLocation.normalizedPosition.dx * _size.width,
      activeLocation.normalizedPosition.dy * _size.height,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Image.asset(
            AppAssets.backgroundMapMoscowLargeDay,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _MapRoutePainter(start: foxPoint, end: activePoint),
          ),
        ),
        for (final location in LocationDefinitions.all)
          Positioned(
            left: location.normalizedPosition.dx * _size.width - 70,
            top: location.normalizedPosition.dy * _size.height - 54,
            child: _LocationNode(
              key: ValueKey('map_location_${location.id}'),
              location: location,
              active: location.id == activeLocation.id,
              visited: visitedLocationIds.contains(location.id),
              pulse: pulse,
              onTap: () => onLocationTap(location),
            ),
          ),
        Positioned(
          left: foxPoint.dx - 58,
          top: foxPoint.dy - 88,
          child: IgnorePointer(
            child: Image.asset(
              AppAssets.foxWalkingMapLevel05,
              width: 122,
              height: 122,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationNode extends StatelessWidget {
  const _LocationNode({
    required this.location,
    required this.active,
    required this.visited,
    required this.pulse,
    required this.onTap,
    super.key,
  });

  final LocationDefinition location;
  final bool active;
  final bool visited;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (active)
              AnimatedBuilder(
                animation: pulse,
                builder: (context, child) => Transform.scale(
                  scale: 1 + pulse.value * 0.12,
                  child: Opacity(
                    opacity: 0.34 - pulse.value * 0.16,
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: const BoxDecoration(
                        color: AppColors.yellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: active ? 70 : 56,
              height: active ? 70 : 56,
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [AppColors.purple, AppColors.primaryBlue],
                      )
                    : null,
                color: active ? null : const Color(0xEAF4F6FD),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 4),
                boxShadow: active ? AppShadows.primaryControl : AppShadows.card,
              ),
              child: Icon(
                active ? Icons.star_rounded : _locationIcon(location.id),
                color: active ? AppColors.yellow : AppColors.secondaryText,
                size: active ? 40 : 28,
              ),
            ),
            if (visited && !active)
              const Positioned(
                right: -2,
                top: -3,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.green,
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.surface,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          constraints: const BoxConstraints(maxWidth: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryBlue : const Color(0xEAF4F6FD),
            borderRadius: AppRadii.capsule,
            border: Border.all(color: AppColors.surface, width: 2),
            boxShadow: AppShadows.card,
          ),
          child: Text(
            location.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: active ? AppColors.surface : AppColors.secondaryText,
              fontSize: active ? 13 : 11,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: active ? 1 : 0.82,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.card,
          child: Padding(padding: const EdgeInsets.all(6), child: content),
        ),
      ),
    );
  }
}

class _LocationTooltip extends StatelessWidget {
  const _LocationTooltip({
    required this.location,
    required this.onClose,
    super.key,
  });

  final LocationDefinition location;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadii.card,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            Icon(_locationIcon(location.id), color: AppColors.purple, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'Здесь тоже бывают задания. '
                    'Загляни в другой день!',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              color: AppColors.secondaryText,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapRoutePainter extends CustomPainter {
  const _MapRoutePainter({required this.start, required this.end});

  final Offset start;
  final Offset end;

  @override
  void paint(Canvas canvas, Size size) {
    final control = Offset(
      (start.dx + end.dx) / 2,
      math.min(start.dy, end.dy) - 45,
    );
    final whitePaint = Paint()..color = AppColors.surface;
    final purplePaint = Paint()..color = AppColors.purple;
    for (var index = 0; index <= 9; index++) {
      final t = index / 9;
      final inverse = 1 - t;
      final point = Offset(
        inverse * inverse * start.dx +
            2 * inverse * t * control.dx +
            t * t * end.dx,
        inverse * inverse * start.dy +
            2 * inverse * t * control.dy +
            t * t * end.dy,
      );
      canvas
        ..drawCircle(point, 9, whitePaint)
        ..drawCircle(point, 6, purplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapRoutePainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}

IconData _locationIcon(String id) => switch (id) {
  'game_center' => Icons.sports_esports_rounded,
  'school' => Icons.school_rounded,
  'canteen' => Icons.restaurant_rounded,
  'stationery_store' => Icons.edit_note_rounded,
  'supermarket' => Icons.shopping_basket_rounded,
  'amusement_park' => Icons.attractions_rounded,
  'cinema' => Icons.movie_rounded,
  'museum' => Icons.museum_rounded,
  'library' => Icons.local_library_rounded,
  'transport_hub' => Icons.directions_subway_rounded,
  'sports_center' => Icons.sports_soccer_rounded,
  'science_center' => Icons.science_rounded,
  _ => Icons.place_rounded,
};
