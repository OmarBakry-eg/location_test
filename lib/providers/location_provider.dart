import 'dart:async';

import 'package:background_location/background_location.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

import '../models/location.dart';
import '../util/notifications_helper.dart';

class LocationProvider with ChangeNotifier {
  static final LocationProvider _singleton = LocationProvider._internal();

  factory LocationProvider() => _singleton;

  LocationProvider._internal();

  Position? _currentLocationData;
  AppLocation? _currentLocation;

  bool _acceptedPermission = false;
  bool _isBackgroundModeEnabled = false;

  bool get initialized => _currentLocation != null;
  bool get hasPermission => _acceptedPermission;
  bool get isBackgroundModeEnabled => _isBackgroundModeEnabled;
  AppLocation? get currentLocation => _currentLocation;

  Map<String, double?> getCurrentLocationMap() {
    if (_currentLocation != null) {
      return {
        'latitude': _currentLocation!.latitude,
        'longitude': _currentLocation!.longitude,
      };
    }
    return {
      'latitude': _currentLocationData?.latitude,
      'longitude': _currentLocationData?.longitude,
    };
  }

  Future<void> init() async {
    await geocoding.setLocaleIdentifier('en');
    _acceptedPermission = await requestPermission();
    if (_acceptedPermission) {
      await fetchCurrentLocation();
    }
    notifyListeners();
  }

  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        NotificationsHelper().showError(
          'Location permission denied. Please enable location services.',
        );
        return false;
      }
    }
    return true;
  }

  Future<void> fetchCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        NotificationsHelper().showError(
          'Location service is disabled. Please enable location service.',
        );
        return;
      }
      NotificationsHelper().printIfDebugMode('Location service enabled');

      _currentLocationData = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 10));

      NotificationsHelper()
          .printIfDebugMode('Location fetched: $_currentLocationData');
      _currentLocation = await _getUserLocation();
      NotificationsHelper()
          .printIfDebugMode('Location fetched: $_currentLocation');
      notifyListeners();
    } catch (e) {
      NotificationsHelper().printIfDebugMode('Location fetching failed: $e');
    }
  }

  Future<void> startContinuousUpdates({
    int interval = 10000, // 10 seconds by default
    double distanceFilter = 10, // 10 meters by default
    bool batteryOptimized = true,
  }) async {
    try {
      int actualInterval = interval;
      double actualDistanceFilter = distanceFilter;

      if (batteryOptimized) {
        actualInterval = interval > 30000 ? interval : 30000;
        actualDistanceFilter = distanceFilter < 20 ? 20 : distanceFilter;
      }

      NotificationsHelper().printIfDebugMode(
          'Location updates configured: interval=${actualInterval}ms, '
          'distance=${actualDistanceFilter}m, '
          'battery optimized=$batteryOptimized');

      notifyListeners();
    } catch (e) {
      NotificationsHelper()
          .printIfDebugMode('Error setting location updates: $e');
    }
  }

  Future<void> setBackgroundMode(bool enable) async {
    try {
      _isBackgroundModeEnabled = enable;
      if (enable) {
        BackgroundLocation.startLocationService();
      } else {
        BackgroundLocation.stopLocationService();
        // Cancel the position stream subscription
        _positionStreamSubscription?.cancel();
        _positionStreamSubscription = null;
      }
      notifyListeners();
    } catch (e) {
      NotificationsHelper()
          .printIfDebugMode('Error setting background mode: $e');
    }
  }

  Future<void> updateLocationOnMap(double lat, double lng) async {
    // update my location on the server
  }

  // Store the subscription to be able to cancel it later
  StreamSubscription<Position>? _positionStreamSubscription;

  void onLocationChanged(Function(Position) callback) {
    // Cancel any existing subscription first
    _positionStreamSubscription?.cancel();

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 10,
      ),
    ).listen(callback);
  }

  Future<AppLocation?> _getUserLocation() async {
    final locationPlaceMark = await _getLocationPlaceMark();

    if (locationPlaceMark == null) return null;

    return AppLocation(
      country: locationPlaceMark.country ?? '',
      displayName: locationPlaceMark.locality ?? '',
      latitude: _currentLocationData!.latitude,
      longitude: _currentLocationData!.longitude,
      lastUpdated: DateTime.now(),
    );
  }

  Future<geocoding.Placemark?> _getLocationPlaceMark() async {
    if (_currentLocationData?.latitude == null ||
        _currentLocationData?.longitude == null) return null;
    final List<geocoding.Placemark> placeMarks =
        await geocoding.placemarkFromCoordinates(
      _currentLocationData!.latitude,
      _currentLocationData!.longitude,
    );

    return placeMarks[0];
  }
}
