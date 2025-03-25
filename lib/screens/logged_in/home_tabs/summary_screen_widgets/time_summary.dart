import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'time_item.dart';
import '../../../../providers/location_tracking_provider.dart';
import '../../../../providers/summary_provider.dart';
import '../../../../providers/summary_screen_provider.dart';

class TimeSummary extends StatelessWidget {
  const TimeSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SummaryScreenProvider>(
      builder: (context, screenProvider, child) {
        final summary = screenProvider.getSummary();

        if (summary == null) {
          return const Center(child: Text('No data available for this date'));
        }

        final items = <Widget>[];

        summary.locationTimes.forEach((location, seconds) {
          items.add(
            TimeItem(
              title: location,
              time: summary.getFormattedTimeForLocation(location),
              icon: Icons.location_on,
              color: Colors.blue,
            ),
          );
        });

        items.add(
          TimeItem(
            title: 'Traveling',
            time: summary.formattedTravelingTime,
            icon: Icons.directions_car,
            color: Colors.green,
          ),
        );

        if (items.isEmpty) {
          return const Center(child: Text('No time recorded for this date'));
        }

        return Consumer2<LocationTrackingProvider, SummaryProvider>(
          builder: (c, locationProvider, summaryProvider, ch) => ListView(
            children: items,
          ),
        );
      },
    );
  }
}
