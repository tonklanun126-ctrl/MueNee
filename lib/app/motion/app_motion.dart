import 'package:flutter/widgets.dart';

abstract final class AppMotion {
  static const press = Duration(milliseconds: 140);
  static const selection = Duration(milliseconds: 200);
  static const content = Duration(milliseconds: 220);

  static Duration contentFor(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : content;
}
