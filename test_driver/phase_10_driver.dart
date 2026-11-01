import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final directory = Directory('artifacts/phase-10');
  await directory.create(recursive: true);
  await integrationDriver(
    responseDataCallback: null,
    onScreenshot: (name, bytes, [args]) async {
      if (!{
        'restaurant-detail-top',
        'restaurant-price-evidence',
        'restaurant-detail-bottom',
      }.contains(name)) {
        return false;
      }
      await File('${directory.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
  );
}
