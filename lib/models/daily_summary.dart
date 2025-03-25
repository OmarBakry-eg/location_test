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

  // Format a duration in seconds to a human-readable string (e.g., "2h 30m")
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${seconds}s ${minutes}m';
    }
  }

  // Get formatted time for a specific location
  String getFormattedTimeForLocation(String locationName) {
    final seconds = locationTimes[locationName] ?? 0;
    return formatDuration(seconds);
  }

  // Get formatted traveling time
  String get formattedTravelingTime => formatDuration(travelingTime);

  // Create a copy with updated values
  DailySummary copyWith({
    String? date,
    Map<String, int>? locationTimes,
    int? travelingTime,
  }) {
    return DailySummary(
      date: date ?? this.date,
      locationTimes: locationTimes ?? Map.from(this.locationTimes),
      travelingTime: travelingTime ?? this.travelingTime,
    );
  }

  // Factory to create an empty summary for a given date
  factory DailySummary.empty(String date) {
    return DailySummary(
      date: date,
      locationTimes: {},
      travelingTime: 0,
    );
  }

  // Factory to create from JSON
  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: json['date'],
      locationTimes: Map<String, int>.from(json['locationTimes']),
      travelingTime: json['travelingTime'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'locationTimes': locationTimes,
      'travelingTime': travelingTime,
    };
  }
}
