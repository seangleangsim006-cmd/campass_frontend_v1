import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../home/data/mock/home_content.dart';

class MapProvider extends ChangeNotifier {
  static const categories = ['All', 'Temples', 'Beaches', 'Nature', 'Culture'];
  static const cambodiaCenter = LatLng(12.5657, 104.9910);

  final mapController = MapController();
  MapProvider({List<HomeDestination>? destinations})
    : _destinations = destinations ?? homeDestinations;

  final List<HomeDestination> _destinations;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  HomeDestination? _selectedDestination;
  bool _showList = false;
  bool _isLocating = false;
  bool _isDisposed = false;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  HomeDestination? get selectedDestination => _selectedDestination;
  bool get showList => _showList;
  bool get isLocating => _isLocating;

  List<HomeDestination> get visibleDestinations {
    final query = _searchQuery.trim().toLowerCase();
    return _destinations.where((destination) {
      final matchesSearch =
          query.isEmpty ||
          destination.name.toLowerCase().contains(query) ||
          destination.province.toLowerCase().contains(query) ||
          destination.location.toLowerCase().contains(query);
      final matchesCategory = switch (_selectedCategory) {
        'All' => true,
        'Nature' =>
          destination.category == 'Mountains' ||
              destination.tags.any((tag) => tag.toLowerCase() == 'nature'),
        _ =>
          destination.category.toLowerCase() ==
                  _selectedCategory.toLowerCase() ||
              destination.categorySlug?.toLowerCase() ==
                  _selectedCategory.toLowerCase().replaceAll(RegExp(r's$'), ''),
      };
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _clearHiddenSelection();
    notifyListeners();
  }

  void selectCategory(String category) {
    if (!categories.contains(category)) return;
    _selectedCategory = category;
    _clearHiddenSelection();
    notifyListeners();
  }

  void selectDestination(HomeDestination destination) {
    _selectedDestination = destination;
    notifyListeners();
  }

  void showDestinationList() {
    _showList = true;
    _selectedDestination = null;
    notifyListeners();
  }

  void showMap() {
    _showList = false;
    notifyListeners();
  }

  void zoomBy(double amount) {
    final camera = mapController.camera;
    mapController.move(camera.center, camera.zoom + amount);
  }

  void recenterOnCambodia() {
    mapController.move(cambodiaCenter, 6.2);
  }

  Future<String?> showCurrentLocation() async {
    _isLocating = true;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return 'Turn on location services to find your position.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return permission == LocationPermission.deniedForever
            ? 'Allow location access in your device settings to use this feature.'
            : 'Location permission is needed to show your position.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      mapController.move(LatLng(position.latitude, position.longitude), 14);
      return null;
    } on Exception {
      return 'Could not determine your current location.';
    } finally {
      _isLocating = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void _clearHiddenSelection() {
    if (_selectedDestination != null &&
        !visibleDestinations.contains(_selectedDestination)) {
      _selectedDestination = null;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
