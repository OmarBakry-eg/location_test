import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/main_screen_provider.dart';

class AddGeoFenceDialog extends StatelessWidget {
  const AddGeoFenceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final ValueNotifier<double> radiusValue = ValueNotifier(50.0);

    return AlertDialog(
      title: const Text('Add Custom Geo-Fence'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Location Name',
              hintText: 'e.g., Gym, Coffee Shop',
            ),
          ),
          const SizedBox(height: 16),
          const Text('Radius (meters):'),
          ValueListenableBuilder<double>(
            valueListenable: radiusValue,
            builder: (context, value, child) => Column(
              children: [
                Slider(
                  value: value,
                  min: 10,
                  max: 200,
                  divisions: 19,
                  label: value.round().toString(),
                  onChanged: (newValue) => radiusValue.value = newValue,
                ),
                Text('${value.round()} meters'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (nameController.text.isNotEmpty) {
              Provider.of<MainScreenProvider>(context, listen: false)
                  .addCustomGeoFence(nameController.text, radiusValue.value);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}