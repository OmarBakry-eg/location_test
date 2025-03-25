import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/daily_summary.dart';
import 'location_tracking_provider.dart';
import 'summary_provider.dart';

class SummaryScreenProvider with ChangeNotifier {
  final LocationTrackingProvider _locationTrackingProvider;
  final SummaryProvider _summaryProvider;

  SummaryScreenProvider(this._locationTrackingProvider, this._summaryProvider) {
    initData();
  }

  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  List<String> _availableDates = [];
  bool _isLoading = true;
  String? _errorMessage;

  String get selectedDate => _selectedDate;
  List<String> get availableDates => _availableDates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _locationTrackingProvider.init();
      await _summaryProvider.init();
      _loadAvailableDates();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadAvailableDates() {
    final summaries = _summaryProvider.getAllDailySummaries();
    if (kDebugMode) {
      for (final s in summaries) {
        print(s.toJson());
      }
    }
    _availableDates = summaries.map((s) => s.date).toList();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (!_availableDates.contains(today)) {
      _availableDates.add(today);
    }
    _availableDates.sort((a, b) => b.compareTo(a));
  }

  void selectDate(String date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> clockOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _locationTrackingProvider.stopTracking();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to clock out: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clockIn() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _locationTrackingProvider.startTracking();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to clock in: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DailySummary? getSummary() {
    final isToday =
        _selectedDate == DateFormat('yyyy-MM-dd').format(DateTime.now());
    return isToday
        ? _summaryProvider.getTodaySummary(
            _locationTrackingProvider.getTravelingTimeToday(),
            _locationTrackingProvider.getAllGeoFencesTimeSpent(),
          )
        : _summaryProvider.getDailySummary(_selectedDate);
  }
}
