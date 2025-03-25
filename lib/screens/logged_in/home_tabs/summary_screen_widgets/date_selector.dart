import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../components/glass_container.dart';
import '../../../../providers/summary_screen_provider.dart';
class DateSelector extends StatelessWidget {
  const DateSelector({super.key});

  String _formatDisplayDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final today = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today (${DateFormat('MMM d').format(date)})';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday (${DateFormat('MMM d').format(date)})';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SummaryScreenProvider>(
      builder: (context, provider, child) => GlassContainer(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: provider.selectedDate,
              isExpanded: true,
              items: provider.availableDates.map((date) {
                final displayDate = _formatDisplayDate(date);
                return DropdownMenuItem<String>(
                  value: date,
                  child: Text(displayDate),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  provider.selectDate(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
