import 'package:flutter/material.dart';
class TimeItem extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  const TimeItem({
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(
          time,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
