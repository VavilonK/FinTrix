class ParentProfile {
  const ParentProfile({
    required this.parentSetupCompleted,
    this.parentDisplayName,
    this.biometricEnabled = false,
  });

  const ParentProfile.initial()
    : parentSetupCompleted = false,
      parentDisplayName = null,
      biometricEnabled = false;

  final bool parentSetupCompleted;
  final String? parentDisplayName;
  final bool biometricEnabled;

  ParentProfile copyWith({
    bool? parentSetupCompleted,
    String? parentDisplayName,
    bool clearParentDisplayName = false,
    bool? biometricEnabled,
  }) {
    return ParentProfile(
      parentSetupCompleted: parentSetupCompleted ?? this.parentSetupCompleted,
      parentDisplayName: clearParentDisplayName
          ? null
          : parentDisplayName ?? this.parentDisplayName,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  Map<String, Object?> toJson() => {
    'parentSetupCompleted': parentSetupCompleted,
    'parentDisplayName': parentDisplayName,
    'biometricEnabled': biometricEnabled,
  };

  factory ParentProfile.fromJson(Map<String, Object?> json) {
    return ParentProfile(
      parentSetupCompleted: json['parentSetupCompleted'] as bool? ?? false,
      parentDisplayName:
          json['parentDisplayName'] as String? ??
          json['displayName'] as String?,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
    );
  }
}

class ChildProfile {
  const ChildProfile({required this.name, required this.age})
    : assert(age >= minimumAge && age <= maximumAge);

  const ChildProfile.initial() : name = 'Миша', age = 8;

  static const int minimumAge = 7;
  static const int maximumAge = 11;
  static const int maximumNameLength = 24;

  final String name;
  final int age;

  ChildProfile copyWith({String? name, int? age}) {
    return ChildProfile(name: name ?? this.name, age: age ?? this.age);
  }

  Map<String, Object?> toJson() => {'name': name, 'age': age};

  factory ChildProfile.fromJson(Map<String, Object?> json) {
    final rawName = json['name'];
    final rawAge = json['age'];
    if (rawName is! String || rawName.trim().isEmpty) {
      throw const FormatException('Child profile name is invalid.');
    }
    if (rawAge is! int || rawAge < minimumAge || rawAge > maximumAge) {
      throw const FormatException('Child profile age is invalid.');
    }
    return ChildProfile(name: rawName.trim(), age: rawAge);
  }
}
