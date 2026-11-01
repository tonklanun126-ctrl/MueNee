import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xSmall = 4.0;
  static const small = 8.0;
  static const medium = 12.0;
  static const normal = 16.0;
  static const large = 24.0;
  static const xLarge = 32.0;
}

abstract final class AppRadii {
  static const field = BorderRadius.all(Radius.circular(14));
  static const button = BorderRadius.all(Radius.circular(18));
  static const card = BorderRadius.all(Radius.circular(18));
  static const hero = BorderRadius.all(Radius.circular(24));
}
