import 'package:flutter/material.dart';

class GeoFenceItem extends StatelessWidget {
  final String name;
  final Duration duration;
  final bool isCustom;
  final VoidCallback? onDelete;

  const GeoFenceItem({
    required this.name,
    required this.duration,
    required this.isCustom,
    super.key,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return Card(
      margin:
          const EdgeInsets.only(bottom: 8), // Assuming 'bottom' was intended
      child: ListTile(
        leading: Icon(
          isCustom ? Icons.star : Icons.location_on,
          color: isCustom ? Colors.amber : Colors.blue,
        ),
        title: Text(name),
        subtitle: Text('Time spent: ${hours}h ${minutes}m ${seconds}s'),
        trailing: isCustom
            ? IconButton(
                icon: const Icon(Icons.delete),
                onPressed: onDelete,
              )
            : null,
      ),
    );
  }
}
