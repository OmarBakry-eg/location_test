import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/geo_fence_provider.dart';
import '../../../providers/location_tracking_provider.dart';
import '../screens/logged_in/home_tabs/main_screen_widgets/add_geo_fence_dialog.dart';

class MainScreenProvider with ChangeNotifier {
  final LocationTrackingProvider _locationTrackingProvider;
  final GeoFenceProvider _geoFenceProvider;

  MainScreenProvider(this._locationTrackingProvider, this._geoFenceProvider) {
    initLocationTracking();
  }

  bool _isInitializing = true;
  String? _errorMessage;

  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;

  Future<void> initLocationTracking() async {
    _isInitializing = true;
    notifyListeners();
    try {
      await _locationTrackingProvider.init();
      await _geoFenceProvider.init();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to initialize location tracking: $e';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void showAddGeoFenceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: this,
        child: const AddGeoFenceDialog(),
      ),
    );
  }

  void addCustomGeoFence(String name, double radius) {
    _locationTrackingProvider.addCustomGeoFence(name, radius: radius);
  }
}
