import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/daily_summary.dart';

class SummaryProvider with ChangeNotifier {
  static final SummaryProvider _singleton = SummaryProvider._internal();

  factory SummaryProvider() => _singleton;

  SummaryProvider._internal();

  Box<DailySummary>? _summaryBox;

  int get getTravelingTimeToday =>
      _summaryBox?.get(_currentDate)?.travelingTime ?? 0;
      
  String get _currentDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> init() async {
    if (_summaryBox != null) return;

    final appDir = await getApplicationDocumentsDirectory();
    Hive.init(appDir.path);

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DailySummaryAdapter());
    }

    _summaryBox = await Hive.openBox<DailySummary>('dailySummaries');
  }

  void persistDailySummary(
    int travelingTime,
    Map<String, Duration> geoFenceTimes,
  ) {
    if (_summaryBox == null) return;

    final Map<String, int> locationTimes = {};
    for (final entry in geoFenceTimes.entries) {
      locationTimes[entry.key] = entry.value.inSeconds;
    }

    final summary = DailySummary(
      date: _currentDate,
      locationTimes: locationTimes,
      travelingTime: travelingTime,
    );

    _summaryBox!.put(_currentDate, summary);
    notifyListeners();
  }

  DailySummary? getDailySummary(String date) {
    return _summaryBox?.get(date);
  }

  DailySummary getTodaySummary(
    int travelingTime,
    Map<String, Duration> geoFenceTimes,
  ) {
    final Map<String, int> locationTimes = {};
    for (final entry in geoFenceTimes.entries) {
      locationTimes[entry.key] = entry.value.inSeconds;
    }

    return DailySummary(
      date: _currentDate,
      locationTimes: locationTimes,
      travelingTime: travelingTime,
    );
  }

  List<DailySummary> getAllDailySummaries() {
    if (_summaryBox == null) return [];
    return _summaryBox!.values.toList();
  }
}
