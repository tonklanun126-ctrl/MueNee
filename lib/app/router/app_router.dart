import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/account_screen.dart';
import '../../features/budget/presentation/budget_screen.dart';
import '../../features/food_scan/presentation/food_scan_screen.dart';
import '../../features/location/presentation/screens/location_screen.dart';
import '../../features/map/presentation/restaurant_map_screen.dart';
import '../../features/privacy/presentation/privacy_settings_screen.dart';

import '../../features/recommendation/presentation/screens/recommendation_placeholder_screen.dart';
import '../../features/recommendation/presentation/screens/food_preview_screen.dart';
import '../../features/recommendation/presentation/screens/recommendation_results_screen.dart';
import '../../features/profile/presentation/screens/food_preferences_screen.dart';
import '../../features/profile/presentation/screens/user_profile_settings_screen.dart';
import '../../features/restaurants/models/restaurant_detail_arguments.dart';
import '../../features/restaurants/presentation/screens/restaurant_detail_screen.dart';
import '../../features/tracking/presentation/daily_tracking_screen.dart';
import '../../core/monitoring/telemetry_providers.dart';

abstract final class AppRoute {
  static const recommendation = 'recommendation';
  static const account = 'account';
  static const budget = 'budget';
  static const location = 'location';
  static const foodSettings = 'food_settings';
  static const profileSettings = 'profile_settings';
  static const privacySettings = 'privacy_settings';
  static const foodPreview = 'food_preview';
  static const recommendations = 'recommendations';
  static const tracking = 'tracking';
  static const foodScan = 'food_scan';
  static const restaurantDetail = 'restaurant_detail';
  static const restaurantMap = 'restaurant_map';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final telemetry = ref.watch(telemetryServiceProvider);
  final router = GoRouter(
    initialLocation: '/',
    observers: [telemetry.navigatorObserver],
    routes: [
      GoRoute(
        path: '/',
        name: AppRoute.recommendation,
        builder: (context, state) => const RecommendationPlaceholderScreen(),
        routes: [
          GoRoute(
            path: 'account',
            name: AppRoute.account,
            builder: (context, state) => const AccountScreen(),
          ),
          GoRoute(
            path: 'budget',
            name: AppRoute.budget,
            builder: (context, state) => BudgetScreen(
              initialAmount: int.tryParse(
                state.uri.queryParameters['amount'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: 'location',
            name: AppRoute.location,
            builder: (context, state) => const LocationScreen(),
          ),
          GoRoute(
            path: 'food-settings',
            name: AppRoute.foodSettings,
            builder: (context, state) => FoodPreferencesScreen(
              isMealFlow: state.uri.queryParameters['flow'] == 'meal',
            ),
          ),
          GoRoute(
            path: 'profile-settings',
            name: AppRoute.profileSettings,
            builder: (context, state) => const UserProfileSettingsScreen(),
          ),
          GoRoute(
            path: 'privacy-settings',
            name: AppRoute.privacySettings,
            builder: (context, state) => const PrivacySettingsScreen(),
          ),
          GoRoute(
            path: 'food-preview',
            name: AppRoute.foodPreview,
            builder: (context, state) => const FoodPreviewScreen(),
          ),
          GoRoute(
            path: 'recommendations',
            name: AppRoute.recommendations,
            builder: (context, state) => const RecommendationResultsScreen(),
          ),
          GoRoute(
            path: 'tracking',
            name: AppRoute.tracking,
            builder: (context, state) => const DailyTrackingScreen(),
          ),
          GoRoute(
            path: 'food-scan',
            name: AppRoute.foodScan,
            builder: (context, state) => const FoodScanScreen(),
          ),
          GoRoute(
            path: 'restaurant/:restaurantId/menu/:menuId',
            name: AppRoute.restaurantDetail,
            builder: (context, state) {
              final details = state.extra;
              if (details is! RestaurantDetailArguments ||
                  details.restaurant.id !=
                      state.pathParameters['restaurantId'] ||
                  details.menu.id != state.pathParameters['menuId']) {
                return const RestaurantDetailUnavailableScreen();
              }
              return RestaurantDetailScreen(details: details);
            },
            routes: [
              GoRoute(
                path: 'map',
                name: AppRoute.restaurantMap,
                builder: (context, state) {
                  final details = state.extra;
                  if (details is! RestaurantDetailArguments ||
                      details.restaurant.id !=
                          state.pathParameters['restaurantId'] ||
                      details.menu.id != state.pathParameters['menuId'] ||
                      details.menu.restaurantId != details.restaurant.id) {
                    return const RestaurantDetailUnavailableScreen();
                  }
                  return RestaurantMapScreen(restaurant: details.restaurant);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
