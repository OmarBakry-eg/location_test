import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mixins/geo_fence_logic_mixin.dart';
import '../mixins/geo_fence_storage_mixin.dart';
import '../models/location.dart';
import '../util/notifications_helper.dart';
import 'location_provider.dart';

class GeoFenceProvider
    with ChangeNotifier, GeoFenceStorageMixin, GeoFenceLogicMixin {
  static final GeoFenceProvider _singleton = GeoFenceProvider._internal();

  factory GeoFenceProvider() => _singleton;

  GeoFenceProvider._internal();

  final LocationProvider _locationProvider = LocationProvider();
  AppLocation? currentLocation;
  bool get hasPermission => _locationProvider.hasPermission;

  @override
  final Map<String, Map<String, dynamic>> geoFences = {
    'Home': {
      'latitude': 37.7749,
      'longitude': -122.4194,
      'radius': 50.0,
      'timeSpent': 0,
      'lastEntered': null,
    },
    'Office': {
      'latitude': 37.7858,
      'longitude': -122.4364,
      'radius': 50.0,
      'timeSpent': 0,
      'lastEntered': null,
    },
  };

  @override
  final Map<String, Map<dynamic, dynamic>> customGeoFences = {};

  Future<void> init() async {
    if (isInitialized) return;
    await initGeoFenceStorage();
    await getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    await _locationProvider.fetchCurrentLocation();
    currentLocation = _locationProvider.currentLocation;
    notifyListeners();
  }

  Map<String, bool> checkGeoFences(double latitude, double longitude) {
    final Map<String, bool> result = {};
    final allGeoFences = {...geoFences, ...customGeoFences};

    for (final entry in allGeoFences.entries) {
      try {
        result[entry.key] = isLocationInGeoFence(
          latitude,
          longitude,
          entry.value['latitude'],
          entry.value['longitude'],
          entry.value['radius'],
        );
      } catch (e) {
        NotificationsHelper()
            .printIfDebugMode('Error checking geo-fence ${entry.key}: $e');
        result[entry.key] = false;
      }
    }

    return result;
  }

  void checkGeoFencesAndUpdateTime(
    double latitude,
    double longitude,
    DateTime now,
    int timeDelta,
  ) {
    if (timeDelta < 0) {
      NotificationsHelper()
          .printIfDebugMode('Invalid parameters for geo-fence check');
      return;
    }

    try {
      final geoFenceNames = getAllGeoFenceNames();
      final geoFenceStatuses = checkGeoFences(latitude, longitude);

      for (final name in geoFenceNames) {
        final isInGeoFence = geoFenceStatuses[name] ?? false;

        if (isInGeoFence) {
          if (getLastEntered(name) == null) {
            setLastEntered(name, now);
          }
        } else {
          final lastEntered = getLastEntered(name);
          if (lastEntered != null) {
            final timeSpent = now.difference(lastEntered).inSeconds;
            updateTimeSpent(name, timeSpent);
            setLastEntered(name, null);
          }
        }
      }
    } catch (e) {
      NotificationsHelper()
          .printIfDebugMode('Error processing geo-fence updates: $e');
    }
  }

  Duration getTimeSpentInGeoFence(String name) {
    int seconds = 0;

    if (geoFences.containsKey(name)) {
      seconds = geoFences[name]!['timeSpent'] ?? 0;
    } else if (customGeoFences.containsKey(name)) {
      seconds = customGeoFences[name]!['timeSpent'] ?? 0;
    }

    return Duration(seconds: seconds);
  }

  Map<String, Duration> getAllGeoFencesTimeSpent() {
    final Map<String, Duration> result = {};

    try {
      for (final entry in geoFences.entries) {
        final seconds = entry.value['timeSpent'] ?? 0;
        result[entry.key] = Duration(seconds: seconds);
      }

      for (final entry in customGeoFences.entries) {
        final seconds = entry.value['timeSpent'] ?? 0;
        result[entry.key] = Duration(seconds: seconds);
      }
    } catch (e) {
      NotificationsHelper().printIfDebugMode(
        'Error getting geo-fence time data: $e',
      );
    }

    return result;
  }

  Future<void> addCustomGeoFence(String name, {double radius = 50.0}) async {
    if (name.trim().isEmpty) {
      NotificationsHelper().showError('Geo-fence name cannot be empty');
      return;
    }

    if (radius <= 0) {
      NotificationsHelper().showError('Geo-fence radius must be positive');
      return;
    }

    try {
      if (geoFences.containsKey(name) || customGeoFences.containsKey(name)) {
        NotificationsHelper()
            .showError('A geo-fence with this name already exists');
        return;
      }
      await getCurrentLocation();
      customGeoFences[name] = {
        'latitude': currentLocation?.latitude,
        'longitude': currentLocation?.longitude,
        'radius': radius,
        'timeSpent': 0,
        'lastEntered': null,
      };

      await persistGeoFenceData();
      notifyListeners();
      NotificationsHelper()
          .showSuccess('Geo-fence "$name" created successfully');
    } catch (e) {
      NotificationsHelper()
          .showError('Failed to create geo-fence: ${e.toString()}');
    }
  }
}
