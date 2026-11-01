import 'package:flutter/services.dart';

abstract final class AppFeedback {
  static Future<void> confirmed() => HapticFeedback.lightImpact();
}
