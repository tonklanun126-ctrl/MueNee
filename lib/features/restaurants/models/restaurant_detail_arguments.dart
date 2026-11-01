import 'menu_item.dart';
import 'restaurant.dart';

class RestaurantDetailArguments {
  const RestaurantDetailArguments({
    required this.restaurant,
    required this.menu,
    required this.distanceMeters,
    required this.rank,
  });

  final Restaurant restaurant;
  final MenuItem menu;
  final double distanceMeters;
  final int rank;
}
