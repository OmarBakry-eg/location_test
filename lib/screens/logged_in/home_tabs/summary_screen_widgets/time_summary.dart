import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/daily_summary.dart';
import '../../../../providers/location_tracking_provider.dart';
import '../../../../providers/summary_screen_provider.dart';
import '../../../../util/value_listanable_builder_2.dart';
import 'time_item.dart';

class TimeSummary extends StatelessWidget {
  const TimeSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final screenProvider =
        Provider.of<SummaryScreenProvider>(context, listen: false);
    final locationTrackingProvider =
        Provider.of<LocationTrackingProvider>(context, listen: false);

    // Use ValueListenableBuilder2 to listen to changes in both isTracking and currentSummary
    return ValueListenableBuilder2<bool, DailySummary?>(
      locationTrackingProvider.isTracking,
      screenProvider.currentSummary,
      builder: (context, isTracking, summary, _) {
        // If no summary is available yet, try to get it from the provider
        final effectiveSummary = summary ?? screenProvider.getSummary();

        if (effectiveSummary == null) {
          return const Center(child: Text('No data available for this date'));
        }

        final items = <Widget>[];

        effectiveSummary.locationTimes.forEach((location, seconds) {
          items.add(
            TimeItem(
              title: location,
              time: effectiveSummary.getFormattedTimeForLocation(location),
              icon: Icons.location_on,
              color: Colors.blue,
            ),
          );
        });

        items.add(
          TimeItem(
            title: 'Traveling',
            time: effectiveSummary.formattedTravelingTime,
            icon: Icons.directions_car,
            color: Colors.green,
          ),
        );

        if (items.isEmpty) {
          return const Center(child: Text('No time recorded for this date'));
        }

        return ListView(children: items);
      },
      child: const SizedBox(),
    );
  }
}
