import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/daily_summary.dart';
import 'location_tracking_provider.dart';
import 'summary_provider.dart';

class SummaryScreenProvider with ChangeNotifier {
  final LocationTrackingProvider _locationTrackingProvider;
  final SummaryProvider _summaryProvider;

  // ValueNotifier for real-time summary updates
  final ValueNotifier<DailySummary?> currentSummary =
      ValueNotifier<DailySummary?>(null);

  // Timer for periodic updates when tracking is active
  Timer? _updateTimer;

  SummaryScreenProvider(this._locationTrackingProvider, this._summaryProvider) {
    initData();
    // Listen to changes in the tracking status
    _locationTrackingProvider.isTracking.addListener(_onTrackingStatusChanged);
  }

  void _onTrackingStatusChanged() {
    // Update the summary when tracking status changes
    _updateCurrentSummary();

    // Start or stop the update timer based on tracking status
    if (_locationTrackingProvider.isTracking.value) {
      _startPeriodicUpdates();
    } else {
      _stopPeriodicUpdates();
    }

    // Notify listeners to update the UI when tracking status changes
    notifyListeners();
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

      // Initialize the current summary
      _updateCurrentSummary();

      // Start periodic updates if tracking is active
      if (_locationTrackingProvider.isTracking.value) {
        _startPeriodicUpdates();
      }

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

    // Update the current summary for the new date
    final isToday = date == DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (isToday) {
      // For today, start periodic updates if tracking is active
      _updateCurrentSummary();
      if (_locationTrackingProvider.isTracking.value) {
        _startPeriodicUpdates();
      }
    } else {
      // For past dates, stop periodic updates and update the summary once
      _stopPeriodicUpdates();
      currentSummary.value = _summaryProvider.getDailySummary(date);
    }

    notifyListeners();
  }

  Future<void> clockOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _locationTrackingProvider.stopTracking();
      // Reload available dates after clocking out to ensure the UI is updated
      _loadAvailableDates();
      // Update the current summary one last time
      _updateCurrentSummary();
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
      // Reload available dates after clocking in to ensure the UI is updated
      _loadAvailableDates();
      // Update the current summary and start periodic updates
      _updateCurrentSummary();
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

    if (isToday) {
      // For today, update the current summary ValueNotifier
      final todaySummary = _summaryProvider.getTodaySummary(
        _locationTrackingProvider.getTravelingTimeToday(),
        _locationTrackingProvider.getAllGeoFencesTimeSpent(),
      );

      // Only update if tracking is active or if the value has changed
      if (_locationTrackingProvider.isTracking.value ||
          currentSummary.value != todaySummary) {
        currentSummary.value = todaySummary;
      }

      return todaySummary;
    } else {
      // For past dates, just get the stored summary
      final pastSummary = _summaryProvider.getDailySummary(_selectedDate);

      // Update the current summary ValueNotifier for consistency
      currentSummary.value = pastSummary;

      return pastSummary;
    }
  }

  // Start periodic updates when tracking is active
  void _startPeriodicUpdates() {
    // Cancel any existing timer
    _stopPeriodicUpdates();

    // Update every second when tracking is active
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_locationTrackingProvider.isTracking.value) {
        _updateCurrentSummary();
      }
    });
  }

  // Stop periodic updates when tracking is inactive
  void _stopPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  // Update the current summary ValueNotifier
  void _updateCurrentSummary() {
    final isToday =
        _selectedDate == DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (isToday) {
      currentSummary.value = _summaryProvider.getTodaySummary(
        _locationTrackingProvider.getTravelingTimeToday(),
        _locationTrackingProvider.getAllGeoFencesTimeSpent(),
      );
    }
  }

  @override
  void dispose() {
    // Cancel the timer when the provider is disposed
    _stopPeriodicUpdates();

    // Remove the listener when the provider is disposed
    _locationTrackingProvider.isTracking
        .removeListener(_onTrackingStatusChanged);

    // Dispose the ValueNotifier
    currentSummary.dispose();

    super.dispose();
  }
}
