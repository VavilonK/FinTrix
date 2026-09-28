import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../shop/domain/shop_catalog.dart';

/// The bedroom behind the pet, with the room items the child has bought.
///
/// Items are placed in the background image's own pixel coordinates and laid
/// out with the same cover fit and transform as the image, so they stay on
/// the bed, wall or floor on every screen size.
class RoomBackground extends StatelessWidget {
  const RoomBackground({required this.ownedItems, super.key});

  final Set<String> ownedItems;

  static const Size imageSize = Size(941, 1672);

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final item in ShopCatalog.items)
        if (item.roomSlot != null && ownedItems.contains(item.id)) item,
    ];
    return Transform.translate(
      offset: const Offset(0, 20),
      child: Transform.scale(
        scale: 1.06,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final fitted = applyBoxFit(BoxFit.cover, imageSize, size);
            final dst = Alignment.topCenter.inscribe(
              fitted.destination,
              Offset.zero & size,
            );
            final scale = dst.width / imageSize.width;
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  AppAssets.backgroundBedroomDay,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                for (final item in items)
                  Positioned(
                    key: ValueKey('room_${item.id}'),
                    left:
                        dst.left +
                        (item.roomSlot!.centerX - item.roomSlot!.width / 2) *
                            scale,
                    width: item.roomSlot!.width * scale,
                    bottom:
                        size.height -
                        (dst.top + item.roomSlot!.bottomY * scale),
                    child: IgnorePointer(
                      child: Image.asset(
                        item.asset,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
