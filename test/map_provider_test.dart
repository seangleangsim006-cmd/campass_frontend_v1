import 'package:flutter_test/flutter_test.dart';
import 'package:user_frontend/features/home/data/mock/home_content.dart';
import 'package:user_frontend/features/map/presentation/providers/map_provider.dart';

void main() {
  group('MapProvider', () {
    late MapProvider provider;

    setUp(() {
      provider = MapProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('filters destinations by category and search query', () {
      provider.selectCategory('Beaches');

      expect(
        provider.visibleDestinations.map((destination) => destination.name),
        ['Koh Rong'],
      );

      provider.setSearchQuery('Phnom Penh');
      expect(provider.visibleDestinations, isEmpty);
    });

    test('clears a selected destination when filters hide it', () {
      provider.selectDestination(homeDestinations.first);

      provider.selectCategory('Beaches');

      expect(provider.selectedDestination, isNull);
    });

    test('tracks map and list mode', () {
      provider.showDestinationList();
      expect(provider.showList, isTrue);

      provider.showMap();
      expect(provider.showList, isFalse);
    });
  });
}
