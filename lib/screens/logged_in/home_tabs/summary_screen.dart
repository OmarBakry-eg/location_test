import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/location_tracking_provider.dart';
import '../../../providers/summary_provider.dart';
import '../../../providers/summary_screen_provider.dart';
import 'summary_screen_widgets/date_selector.dart';
import 'summary_screen_widgets/time_summary.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locationTrackingProvider =
        Provider.of<LocationTrackingProvider>(context, listen: false);
    final summaryProvider =
        Provider.of<SummaryProvider>(context, listen: false);

    return ChangeNotifierProvider(
      create: (_) =>
          SummaryScreenProvider(locationTrackingProvider, summaryProvider),
      child: Consumer<SummaryScreenProvider>(
        builder: (context, provider, child) => Scaffold(
          appBar: AppBar(
            title: const Text('Time Summary'),
            actions: [
              if (locationTrackingProvider.isTracking.value) ...{
                IconButton(
                  icon: const Icon(Icons.stop),
                  tooltip: 'Clock Out',
                  onPressed: provider.clockOut,
                ),
              } else ...{
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Clock In',
                  onPressed: provider.clockIn,
                ),
              },
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.errorMessage != null
                    ? Center(child: Text(provider.errorMessage!))
                    : const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DateSelector(),
                          SizedBox(height: 16),
                          Expanded(child: TimeSummary()),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
