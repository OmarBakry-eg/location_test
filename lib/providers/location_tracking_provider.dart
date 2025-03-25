import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../util/notifications_helper.dart';
import 'geo_fence_provider.dart';
import 'location_provider.dart';
import 'summary_provider.dart';

class LocationTrackingProvider with ChangeNotifier, WidgetsBindingObserver {
  static final LocationTrackingProvider _singleton =
      LocationTrackingProvider._internal();

  factory LocationTrackingProvider() => _singleton;

  final ValueNotifier<bool> isTracking = ValueNotifier<bool>(false);

  final LocationProvider _locationProvider = LocationProvider();
  final GeoFenceProvider geoFenceProvider = GeoFenceProvider();
  final SummaryProvider summaryProvider = SummaryProvider();

  double? _currentLatitude;
  double? _currentLongitude;
  DateTime? _lastLocationUpdate;

  Box? _locationBox;

  int _travelingTimeToday = 0;

  LocationTrackingProvider._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && isTracking.value) {
      summaryProvider.persistDailySummary(
        _travelingTimeToday,
        geoFenceProvider.getAllGeoFencesTimeSpent(),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> init() async {
    if (_locationBox != null) return;

    await _locationProvider.init();
    await geoFenceProvider.init();
    await summaryProvider.init();

    _locationBox = await Hive.openBox('locationTracking');

    _travelingTimeToday = summaryProvider.getTravelingTimeToday();

    final wasTracking = _locationBox!.get('isTracking') ?? false;
    if (wasTracking) {
      startTracking();
    }
  }

  Future<void> startTracking() async {
    if (isTracking.value) return;

    try {
      if (!_locationProvider.hasPermission) {
        final hasPermission = await _locationProvider.requestPermission();
        if (!hasPermission) {
          NotificationsHelper().showError(
            'Location permission denied. Please enable location services.',
          );
          return;
        }
      }

      _locationProvider.onLocationChanged((position) {
        _processLocationUpdate(
          position.latitude,
          position.longitude,
        );
      });

      await _locationProvider.setBackgroundMode(true);
      await _locationProvider.startContinuousUpdates();

      isTracking.value = true;
      _locationBox?.put('isTracking', true);
      notifyListeners();
    } catch (e) {
      NotificationsHelper()
          .printIfDebugMode('Error starting location tracking: $e');
    }
  }

  Future<void> stopTracking() async {
    if (!isTracking.value) return;

    try {
      // Cancel the location updates subscription first
      await _locationProvider.setBackgroundMode(false);
      // Persist the current summary before stopping
      summaryProvider.persistDailySummary(
        _travelingTimeToday,
        geoFenceProvider.getAllGeoFencesTimeSpent(),
      );

      // Reset the traveling time to the persisted value to avoid accumulation
      _travelingTimeToday = summaryProvider.getTravelingTimeToday();
      _lastLocationUpdate = null;

      isTracking.value = false;
      _locationBox?.put('isTracking', false);
      notifyListeners();
    } catch (e) {
      NotificationsHelper()
          .printIfDebugMode('Error stopping location tracking: $e');
    }
  }

  void _processLocationUpdate(double latitude, double longitude) {
    try {
      _currentLatitude = latitude;
      _currentLongitude = longitude;
      final now = DateTime.now();

      if (_lastLocationUpdate == null) {
        _lastLocationUpdate = now;
        return;
      }

      final timeDelta = now.difference(_lastLocationUpdate!).inSeconds;

      if (timeDelta < 1 || timeDelta > 3600) {
        _lastLocationUpdate = now;
        return;
      }

      geoFenceProvider.checkGeoFencesAndUpdateTime(
        latitude,
        longitude,
        now,
        timeDelta,
      );

      _travelingTimeToday += timeDelta;
      _lastLocationUpdate = now;

      if (now.minute % 5 == 0 && now.second < 10) {
        summaryProvider.persistDailySummary(
          _travelingTimeToday,
          geoFenceProvider.getAllGeoFencesTimeSpent(),
        );
      }
    } catch (e) {
      NotificationsHelper()
          .printIfDebugMode('Error processing location update: $e');
    }
  }

  Future<void> addCustomGeoFence(String name, {double radius = 50.0}) async {
    await geoFenceProvider.addCustomGeoFence(name, radius: radius);
    notifyListeners();
  }

  Duration getTimeSpentInGeoFence(String name) {
    return geoFenceProvider.getTimeSpentInGeoFence(name);
  }

  Map<String, Duration> getAllGeoFencesTimeSpent() {
    final result = geoFenceProvider.getAllGeoFencesTimeSpent();
    result['Traveling'] = Duration(seconds: _travelingTimeToday);
    return result;
  }

  Map<String, double?> getCurrentLocation() {
    final locationMap = _locationProvider.getCurrentLocationMap();

    if (locationMap['latitude'] == null || locationMap['longitude'] == null) {
      return {
        'latitude': _currentLatitude,
        'longitude': _currentLongitude,
      };
    }

    return locationMap;
  }

  int getTravelingTimeToday() {
    return _travelingTimeToday;
  }
}
