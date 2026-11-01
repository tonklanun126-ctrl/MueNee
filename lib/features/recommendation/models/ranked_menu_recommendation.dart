import '../../restaurants/models/menu_item.dart';
import '../../restaurants/models/restaurant.dart';

class RecommendationScore {
  const RecommendationScore({
    required this.distance,
    required this.affordability,
    required this.priceConfidence,
    required this.preference,
  });

  final double distance;
  final double affordability;
  final double priceConfidence;
  final double preference;

  double get total => distance + affordability + priceConfidence + preference;
}

class RankedMenuRecommendation {
  const RankedMenuRecommendation({
    required this.menu,
    required this.restaurant,
    required this.distanceMeters,
    required this.isDisliked,
    required this.score,
  });

  final MenuItem menu;
  final Restaurant restaurant;
  final double distanceMeters;
  final bool isDisliked;
  final RecommendationScore score;
}
