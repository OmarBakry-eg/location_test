import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/geo_fence_provider.dart';
import 'geo_fence_item.dart';

class GeoFencesList extends StatelessWidget {
  const GeoFencesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GeoFenceProvider>(
      builder: (context, provider, child) {
        final allGeoFences = provider.getAllGeoFencesTimeSpent();

        if (allGeoFences.isEmpty) {
          return const Center(child: Text('No geo-fences available'));
        }

        return ListView.builder(
          itemCount: allGeoFences.length,
          itemBuilder: (context, index) {
            final name = allGeoFences.keys.elementAt(index);
            final duration = allGeoFences.values.elementAt(index);
            final isCustom = provider.customGeoFences.containsKey(name);

            return GeoFenceItem(
              name: name,
              duration: duration,
              isCustom: isCustom,
              onDelete: isCustom ? () => provider.removeCustomGeoFence(name) : null,
            );
          },
        );
      },
    );
  }
}