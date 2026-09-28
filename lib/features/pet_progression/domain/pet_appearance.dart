/// Hoodie colours offered in Profile. [blue] is the colour the clips are
/// drawn in; the others are recoloured at runtime from per-clip hoodie masks.
enum HoodieColor {
  blue,
  red,
  green,
  purple;

  String get title => switch (this) {
    blue => 'Синее',
    red => 'Красное',
    green => 'Зелёное',
    purple => 'Фиолетовое',
  };
}

enum PetAccessory {
  glasses,
  bow;

  String get title => switch (this) {
    glasses => 'Очки',
    bow => 'Бантик',
  };
}

/// How Ryzhik looks. Purely visual: it never affects gameplay.
class PetAppearance {
  const PetAppearance({
    this.hoodie = HoodieColor.blue,
    this.accessories = const {},
  });

  final HoodieColor hoodie;
  final Set<PetAccessory> accessories;

  /// The look the animations are drawn in; rendering takes the plain path.
  bool get isDefault => hoodie == HoodieColor.blue && accessories.isEmpty;

  bool has(PetAccessory accessory) => accessories.contains(accessory);

  PetAppearance copyWith({
    HoodieColor? hoodie,
    Set<PetAccessory>? accessories,
  }) => PetAppearance(
    hoodie: hoodie ?? this.hoodie,
    accessories: accessories ?? this.accessories,
  );

  PetAppearance toggle(PetAccessory accessory) => copyWith(
    accessories: has(accessory)
        ? ({...accessories}..remove(accessory))
        : {...accessories, accessory},
  );

  Map<String, Object?> toJson() => {
    'hoodie': hoodie.name,
    'accessories': [
      for (final accessory in PetAccessory.values)
        if (has(accessory)) accessory.name,
    ],
  };

  /// Unknown values fall back to the default look (older saves, removed items).
  static PetAppearance fromJson(Object? json) {
    if (json is! Map) return const PetAppearance();
    final hoodie = HoodieColor.values
        .where((value) => value.name == json['hoodie'])
        .firstOrNull;
    final names = json['accessories'];
    return PetAppearance(
      hoodie: hoodie ?? HoodieColor.blue,
      accessories: {
        if (names is List)
          for (final accessory in PetAccessory.values)
            if (names.contains(accessory.name)) accessory,
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PetAppearance &&
      other.hoodie == hoodie &&
      other.accessories.length == accessories.length &&
      other.accessories.containsAll(accessories);

  @override
  int get hashCode => Object.hash(hoodie, Object.hashAllUnordered(accessories));
}
