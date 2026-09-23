import 'package:flutter/material.dart';

abstract final class AppRadii {
  static const double small = 12;
  static const double medium = 16;
  static const double large = 24;
  static const double extraLarge = 32;
  static const double action = 30;
  static const double sheet = 36;
  static const double pill = 999;

  static const BorderRadius smallBorder = BorderRadius.all(
    Radius.circular(small),
  );
  static const BorderRadius mediumBorder = BorderRadius.all(
    Radius.circular(medium),
  );
  static const BorderRadius card = BorderRadius.all(Radius.circular(large));
  static const BorderRadius heroCard = BorderRadius.all(
    Radius.circular(extraLarge),
  );
  static const BorderRadius actionButton = BorderRadius.all(
    Radius.circular(action),
  );
  static const BorderRadius capsule = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius bottomSheet = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}
