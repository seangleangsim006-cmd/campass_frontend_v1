import '../../data/mock/home_content.dart';

abstract interface class PlaceRepository {
  Future<List<HomeDestination>> loadPlaces({String? query});

  Future<HomeDestination> loadPlace(String slug);

  Future<Set<String>> loadSavedPlaceSlugs();

  Future<void> setPlaceSaved(String slug, {required bool saved});
}
