import 'package:flutter/foundation.dart';

import '../models/location.dart';
import '../util/notifications_helper.dart';

mixin GeoFenceLogicMixin on ChangeNotifier {
  bool isLocationInGeoFence(
    double latitude,
    double longitude,
    double fenceLat,
    double fenceLng,
    double radiusInMeters,
  ) {
    if (radiusInMeters <= 0) {
      return false;
    }

    try {
      final currentLocation = AppLocation(
        country: '',
        displayName: 'Current',
        latitude: latitude,
        longitude: longitude,
      );

      final fence = AppLocation(
        country: '',
        displayName: 'Fence',
        latitude: fenceLat,
        longitude: fenceLng,
      );

      final distanceInKm = currentLocation.distanceTo(fence);
      final distanceInMeters = distanceInKm * 1000;

      return distanceInMeters <= radiusInMeters;
    } catch (e) {
      NotificationsHelper().printIfDebugMode('Error calculating distance: $e');
      return false;
    }
  }

  void updateTimeSpent(String name, int additionalSeconds) {
    if (geoFences.containsKey(name)) {
      geoFences[name]!['timeSpent'] =
          (geoFences[name]!['timeSpent'] ?? 0) + additionalSeconds;
    } else if (customGeoFences.containsKey(name)) {
      customGeoFences[name]!['timeSpent'] =
          (customGeoFences[name]!['timeSpent'] ?? 0) + additionalSeconds;
    }
    persistGeoFenceData();
    notifyListeners();
  }

  void setLastEntered(String name, DateTime? time) {
    if (geoFences.containsKey(name)) {
      geoFences[name]!['lastEntered'] = time;
    } else if (customGeoFences.containsKey(name)) {
      customGeoFences[name]!['lastEntered'] = time;
    }
  }

  DateTime? getLastEntered(String name) {
    if (geoFences.containsKey(name)) {
      return geoFences[name]!['lastEntered'];
    } else if (customGeoFences.containsKey(name)) {
      return customGeoFences[name]!['lastEntered'];
    }
    return null;
  }

  void removeCustomGeoFence(String name) {
    if (customGeoFences.containsKey(name)) {
      customGeoFences.remove(name);
      persistGeoFenceData();
      notifyListeners();
    }
  }

  List<String> getAllGeoFenceNames() {
    final List<String> result = [];
    result.addAll(geoFences.keys);
    result.addAll(customGeoFences.keys);
    return result;
  }

  // These need to be implemented by the class using this mixin
  Map<String, Map<String, dynamic>> get geoFences;
  Map<String, Map<dynamic, dynamic>> get customGeoFences;
  Future<bool> persistGeoFenceData();
}