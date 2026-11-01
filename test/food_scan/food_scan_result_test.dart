import 'package:flutter_test/flutter_test.dart';
import 'package:muenee/features/food_scan/models/food_scan_result.dart';

void main() {
  test('parses a recognized structured nutrition estimate', () {
    final result = FoodScanResult.fromJson({
      'recognizedFood': true,
      'foodName': 'ข้าวกะเพราไก่',
      'calories': 540,
      'proteinGrams': 28,
      'carbsGrams': 65.5,
      'fatGrams': 18,
      'assumption': 'ประเมินจากข้าวหนึ่งจานและไข่ดาวหนึ่งฟอง',
    });

    expect(result.foodName, 'ข้าวกะเพราไก่');
    expect(result.nutrition.calories, 540);
    expect(result.nutrition.carbsGrams, 65.5);
  });

  test('rejects images that are not recognized as food', () {
    expect(
      () => FoodScanResult.fromJson({
        'recognizedFood': false,
        'foodName': '',
        'calories': 0,
        'proteinGrams': 0,
        'carbsGrams': 0,
        'fatGrams': 0,
        'assumption': 'ไม่พบอาหาร',
      }),
      throwsA(isA<FoodNotRecognizedException>()),
    );
  });

  test('rejects malformed or out-of-range model output', () {
    final base = <String, dynamic>{
      'recognizedFood': true,
      'foodName': 'อาหารทดสอบ',
      'calories': 500,
      'proteinGrams': 20,
      'carbsGrams': 60,
      'fatGrams': 15,
      'assumption': 'หนึ่งจาน',
    };

    expect(
      () => FoodScanResult.fromJson({...base, 'calories': 500.5}),
      throwsFormatException,
    );
    expect(
      () => FoodScanResult.fromJson({...base, 'proteinGrams': 1001}),
      throwsFormatException,
    );
    expect(
      () => FoodScanResult.fromJson({...base, 'foodName': ''}),
      throwsFormatException,
    );
  });
}
