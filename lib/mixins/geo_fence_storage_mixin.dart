import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../util/notifications_helper.dart';

mixin GeoFenceStorageMixin on ChangeNotifier {
  Box? _geoFenceBox;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initGeoFenceStorage() async {
    if (_initialized) return;

    try {
      _geoFenceBox = await _openGeoFenceBoxWithTimeout();
      await _loadCustomGeoFences();
      await _loadGeoFencesTimeData();
      _initialized = true;
      notifyListeners();
    } catch (e) {
      NotificationsHelper().showError(
        'Failed to initialize geo-fence tracking: ${e.toString()}',
      );
      await _handleInitializationFallback(e);
    }
  }

  Future<Box> _openGeoFenceBoxWithTimeout() async {
    try {
      return await Hive.openBox('geoFences').timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Timed out opening geo-fence storage');
        },
      );
    } catch (e) {
      NotificationsHelper().printIfDebugMode('Error opening geo-fence box: $e');
      rethrow;
    }
  }

  Future<void> _loadCustomGeoFences() async {
    try {
      final savedCustomGeoFences = _geoFenceBox!.get('customGeoFences');
      if (savedCustomGeoFences != null) {
        customGeoFences.addAll(
          Map<String, Map<dynamic, dynamic>>.from(savedCustomGeoFences),
        );
      }
      notifyListeners();
    } catch (e) {
      NotificationsHelper()
          .printIfDebugMode('Error loading custom geo-fences: $e');
      rethrow;
    }
  }

  Future<void> _loadGeoFencesTimeData() async {
    try {
      final savedGeoFencesTimeData = _geoFenceBox!.get('geoFencesTimeData');
      if (savedGeoFencesTimeData != null) {
        final Map<String, dynamic> timeData =
            Map<String, dynamic>.from(savedGeoFencesTimeData);

        for (final entry in timeData.entries) {
          if (geoFences.containsKey(entry.key)) {
            geoFences[entry.key]!['timeSpent'] = entry.value;
          }
        }
      }
    } catch (e) {
      NotificationsHelper()
          .printIfDebugMode('Error loading geo-fence time data: $e');
      rethrow;
    }
  }

  Future<void> _handleInitializationFallback(error) async {
    try {
      _geoFenceBox = await Hive.openBox('geoFences');
      _initialized = true;
      notifyListeners();
    } catch (e) {
      NotificationsHelper().printIfDebugMode(
        'Critical error initializing geo-fence storage: $e',
      );
      throw error;
    }
  }

  Future<bool> persistGeoFenceData() async {
    if (_geoFenceBox == null || !_initialized) {
      NotificationsHelper().printIfDebugMode(
        'Cannot persist geo-fence data: storage not initialized',
      );
      return false;
    }

    final Map<String, int> timeData = {
      ...geoFences.map((k, v) => MapEntry(k, v['timeSpent'] ?? 0)),
      ...customGeoFences.map((k, v) => MapEntry(k, v['timeSpent'] ?? 0)),
    };

    for (int retryCount = 0; retryCount < 3; retryCount++) {
      try {
        await Future.wait([
          _geoFenceBox!.put('customGeoFences', customGeoFences),
          _geoFenceBox!.put('geoFencesTimeData', timeData),
        ]);
        return true;
      } catch (e) {
        NotificationsHelper().printIfDebugMode(
          'Error persisting geo-fence data (attempt ${retryCount + 1}/3): $e',
        );
        if (retryCount == 2) {
          NotificationsHelper().printIfDebugMode(
            'Failed to persist geo-fence data after 3 attempts',
          );
          return false;
        }
        await Future.delayed(Duration(milliseconds: 200 * (retryCount + 1)));
      }
    }
    return false;
  }

  // These need to be implemented by the class using this mixin
  Map<String, Map<String, dynamic>> get geoFences;
  Map<String, Map<dynamic, dynamic>> get customGeoFences;
}