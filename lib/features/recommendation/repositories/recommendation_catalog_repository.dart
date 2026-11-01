import 'package:cloud_firestore/cloud_firestore.dart';

import '../../restaurants/models/menu_item.dart';
import '../../restaurants/models/restaurant.dart';

class RecommendationCatalog {
  const RecommendationCatalog({required this.restaurants, required this.menus});

  final List<Restaurant> restaurants;
  final List<MenuItem> menus;
}

abstract interface class RecommendationCatalogRepository {
  Future<RecommendationCatalog> loadActiveCatalog();
}

class FirestoreRecommendationCatalogRepository
    implements RecommendationCatalogRepository {
  const FirestoreRecommendationCatalogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<RecommendationCatalog> loadActiveCatalog() async {
    final restaurantsFuture = _firestore
        .collection('restaurants')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .limit(51)
        .get(const GetOptions(source: Source.server));
    final menusFuture = _firestore
        .collection('menu_items')
        .where('isActive', isEqualTo: true)
        .limit(101)
        .get(const GetOptions(source: Source.server));

    final snapshots = await Future.wait([restaurantsFuture, menusFuture]);
    final restaurantSnapshot = snapshots[0];
    final menuSnapshot = snapshots[1];
    if (restaurantSnapshot.docs.length > 50 || menuSnapshot.docs.length > 100) {
      throw StateError('Catalog exceeds the supported MVP candidate bound');
    }
    final restaurants = [
      for (final document in restaurantSnapshot.docs)
        Restaurant.fromFirestore(document.id, document.data()),
    ];
    final menus =
        [
          for (final document in menuSnapshot.docs)
            MenuItem.fromFirestore(document.id, document.data()),
        ]..sort((left, right) {
          final byName = left.name.compareTo(right.name);
          return byName != 0 ? byName : left.id.compareTo(right.id);
        });

    return RecommendationCatalog(restaurants: restaurants, menus: menus);
  }
}
