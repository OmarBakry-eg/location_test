import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../components/glass_container.dart';
import '../../../../providers/location_tracking_provider.dart';

class ClockControl extends StatelessWidget {
  const ClockControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationTrackingProvider>(
      builder: (context, provider, child) => ValueListenableBuilder<bool>(
        valueListenable: provider.isTracking,
        builder: (context, isTracking, child) => GlassContainer(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Icon(
                Icons.location_on,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                isTracking ? 'Currently Tracking' : 'Not Tracking',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: isTracking ? null : () => provider.startTracking(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Clock In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: isTracking ? () => provider.stopTracking() : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Clock Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}