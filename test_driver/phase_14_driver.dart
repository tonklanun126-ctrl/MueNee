import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final directory = Directory('artifacts/phase-14-food-scan');
  await directory.create(recursive: true);
  await integrationDriver(
    responseDataCallback: null,
    onScreenshot: (name, bytes, [args]) async {
      if (name != 'food-scan-review' && name != 'food-scan-saved') {
        return false;
      }
      await File('${directory.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
  );
}
