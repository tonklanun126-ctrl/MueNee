import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:muenee/app/theme/app_theme.dart';
import 'package:muenee/features/auth/auth_repository.dart';
import 'package:muenee/features/profile/models/food_preferences.dart';
import 'package:muenee/features/restaurants/models/menu_item.dart';
import 'package:muenee/features/restaurants/models/menu_preview.dart';
import 'package:muenee/features/restaurants/models/restaurant.dart';
import 'package:muenee/features/restaurants/models/restaurant_detail_arguments.dart';
import 'package:muenee/features/restaurants/presentation/screens/restaurant_detail_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders Phase 10 detail and evidence on Android', (
    tester,
  ) async {
    final details = _details();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [accountProvider.overrideWith((ref) => Stream.value(null))],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  key: const ValueKey('open-detail'),
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RestaurantDetailScreen(details: details),
                    ),
                  ),
                  child: const Text('เปิดรายละเอียดร้าน'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-detail')));
    await tester.pumpAndSettle();

    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('restaurant-detail-top');

    await tester.tap(find.byKey(const ValueKey('price-evidence')));
    await tester.pumpAndSettle();
    expect(find.textContaining('wongnai.com'), findsOneWidget);
    await binding.takeScreenshot('restaurant-price-evidence');
    await tester.tap(find.text('ปิด'));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView), const Offset(0, -1400), 1200);
    await tester.pumpAndSettle();
    expect(find.text('ข้อมูลส่วนผสมและสารก่อภูมิแพ้'), findsOneWidget);
    await binding.takeScreenshot('restaurant-detail-bottom');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-detail')), findsOneWidget);
  });
}

RestaurantDetailArguments _details() {
  final now = DateTime.now().toUtc();
  final restaurant = Restaurant(
    id: 'thasanam-boat-noodles',
    name: 'ก๋วยเตี๋ยวเรือ ท่าสนาม THASANAM',
    googlePlaceId: 'ChIJQQMnDs_l4jARYfvOanBx37c',
    location: const GeoPoint(13.8157152, 100.045282),
    address: 'ถนนราชมรรคาใน หน้าโรงเรียนสาธิต ม.ศิลปากร อำเภอเมืองนครปฐม นครปฐม 73000',
    verificationStatus: RestaurantVerificationStatus.verified,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  return RestaurantDetailArguments(
    restaurant: restaurant,
    menu: MenuItem(
      id: 'thasanam-boat-noodle-soup',
      restaurantId: restaurant.id,
      name: 'ก๋วยเตี๋ยวเรือน้ำ',
      price: MenuPrice(
        amount: 40,
        confidence: PriceConfidence.unverified,
        source: 'https://www.wongnai.com/restaurants/496811LZ/reviews',
      ),
      nutrition: NutritionEstimate(
        calories: 410,
        proteinGrams: 23,
        carbsGrams: 57,
        fatGrams: 10,
      ),
      tags: const ['noodles', 'thai'],
      ingredients: const {FoodIngredient.pork, FoodIngredient.beef},
      allergens: const {FoodAllergen.soy, FoodAllergen.wheat},
      ingredientsKnown: false,
      allergensKnown: false,
      vegetarianConfirmed: false,
      halalConfirmed: false,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    distanceMeters: 620,
    rank: 1,
  );
}
