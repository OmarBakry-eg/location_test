import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/geo_fence_provider.dart';
import '../../../providers/location_tracking_provider.dart';
import '../../../providers/main_screen_provider.dart';
import './main_screen_widgets/clock_control.dart';
import './main_screen_widgets/geo_fences_list.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locationTrackingProvider =
        Provider.of<LocationTrackingProvider>(context, listen: false);
    final geoFenceProvider =
        Provider.of<GeoFenceProvider>(context, listen: false);

    return ChangeNotifierProvider(
      create: (_) =>
          MainScreenProvider(locationTrackingProvider, geoFenceProvider),
      child: Consumer<MainScreenProvider>(
        builder: (context, provider, child) => Scaffold(
          appBar: AppBar(
            title: const Text('Location Tracking'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: provider.isInitializing
                ? const Center(child: CircularProgressIndicator())
                : provider.errorMessage != null
                    ? Center(child: Text(provider.errorMessage!))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const ClockControl(),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Text(
                                'Geo-Fences',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  provider.showAddGeoFenceDialog(context);
                                },
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Expanded(child: GeoFencesList()),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
