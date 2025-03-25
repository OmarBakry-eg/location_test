import 'package:hive/hive.dart';

part 'daily_summary.g.dart';

@HiveType(typeId: 1)
class DailySummary {
  @HiveField(0)
  final String date; // Format: YYYY-MM-DD

  @HiveField(1)
  final Map<String, int> locationTimes; // Location name -> seconds spent

  @HiveField(2)
  final int travelingTime; // seconds spent traveling

  DailySummary({
    required this.date,
    required this.locationTimes,
    required this.travelingTime,
  });

  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${seconds}s ${minutes}m';
    }
  }

  String getFormattedTimeForLocation(String locationName) {
    final seconds = locationTimes[locationName] ?? 0;
    return formatDuration(seconds);
  }

  String get formattedTravelingTime => formatDuration(travelingTime);

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: json['date'],
      locationTimes: Map<String, int>.from(json['locationTimes']),
      travelingTime: json['travelingTime'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'locationTimes': locationTimes,
      'travelingTime': travelingTime,
    };
  }
}
