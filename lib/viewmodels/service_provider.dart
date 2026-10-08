import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/service_model.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';

/// State management provider for metal categories, service discovery, GPS distance calculation, and filtering.
class ServiceProvider with ChangeNotifier {
  final DatabaseService _databaseService;
  final LocationService _locationService;

  List<ServiceModel> _allServices = [];
  List<ServiceModel> _filteredServices = [];
  Position? _currentPosition;

  String? _selectedMetalCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isMapView = false;
  ServiceModel? _selectedService;

  ServiceProvider({
    required DatabaseService databaseService,
    required LocationService locationService,
  })  : _databaseService = databaseService,
        _locationService = locationService {
    fetchServicesAndLocation();
  }

  List<ServiceModel> get allServices => _allServices;
  List<ServiceModel> get filteredServices => _filteredServices;
  Position? get currentPosition => _currentPosition;
  String? get selectedMetalCategory => _selectedMetalCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isMapView => _isMapView;
  ServiceModel? get selectedService => _selectedService;

  void toggleMapView(bool isMap) {
    _isMapView = isMap;
    notifyListeners();
  }

  void selectService(ServiceModel service) {
    _selectedService = service;
    notifyListeners();
  }

  /// Initial load of services and user coordinates
  Future<void> fetchServicesAndLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentPosition = await _locationService.getCurrentPosition();
      _allServices = await _databaseService.getRecyclingServices();
      _applyFiltersAndSorting();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// Select a metal category to filter centers
  void selectMetalCategory(String? metal) {
    if (_selectedMetalCategory == metal) {
      _selectedMetalCategory = null; // Toggle off if clicked again
    } else {
      _selectedMetalCategory = metal;
    }
    _applyFiltersAndSorting();
    notifyListeners();
  }

  /// Update search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSorting();
    notifyListeners();
  }

  /// Calculate distance in meters from user to a recycling service
  double getDistanceToService(ServiceModel service) {
    if (_currentPosition == null) return 0.0;
    return _locationService.calculateDistance(
      startLatitude: _currentPosition!.latitude,
      startLongitude: _currentPosition!.longitude,
      endLatitude: service.lat,
      endLongitude: service.lng,
    );
  }

  void _applyFiltersAndSorting() {
    List<ServiceModel> list = List.from(_allServices);

    // 1. Metal category filter
    if (_selectedMetalCategory != null && _selectedMetalCategory!.isNotEmpty) {
      list = list.where((service) {
        return service.acceptedMetals.any(
          (m) => m.toLowerCase() == _selectedMetalCategory!.toLowerCase(),
        );
      }).toList();
    }

    // 2. Search query filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((service) {
        final matchesName = service.name.toLowerCase().contains(q);
        final matchesAddress = service.address.toLowerCase().contains(q);
        final matchesMetals = service.acceptedMetals.any((m) => m.toLowerCase().contains(q));
        return matchesName || matchesAddress || matchesMetals;
      }).toList();
    }

    // 3. Sort by distance if current position is available
    if (_currentPosition != null) {
      list.sort((a, b) {
        final distA = getDistanceToService(a);
        final distB = getDistanceToService(b);
        return distA.compareTo(distB);
      });
    }

    _filteredServices = list;
  }
}
