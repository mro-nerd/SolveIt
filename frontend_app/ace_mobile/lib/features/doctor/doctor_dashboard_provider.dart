import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ace_mobile/backend/backend.dart';

class DoctorDashboardProvider extends ChangeNotifier {
  final ChildService _childService;

  DoctorDashboardProvider({ChildService? childService})
      : _childService = childService ?? ChildService();

  List<Map<String, dynamic>> patients = [];
  bool isLoading = false;
  String? error;

  // ── Realtime stream subscription ────────────────────────────────────────
  StreamSubscription<List<Map<String, dynamic>>>? _therapyStreamSub;

  // ── Computed getters ────────────────────────────────────────────────────

  int get highRiskCount =>
      patients.where((p) => p['diagnosis_status'] == 'high').length;

  int get totalPatients => patients.length;

  double get avgLastScore {
    if (patients.isEmpty) return 0.0;
    double total = 0;
    int count = 0;
    for (var p in patients) {
      final session = p['latest_session'];
      if (session != null && session['score'] != null) {
        total += (session['score'] as num).toDouble();
        count++;
      }
    }
    return count == 0 ? 0.0 : total / count;
  }

  /// Count of sessions completed today across all patients.
  int get sessionsToday {
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    int count = 0;
    for (var p in patients) {
      final session = p['latest_session'];
      if (session != null && session['completed_at'] != null) {
        final completedDate =
            (session['completed_at'] as String).split('T').first;
        if (completedDate == todayStr) count++;
      }
    }
    return count;
  }

  /// Count of patients with high risk flags this week.
  int get highRiskThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = weekStart.toIso8601String().split('T').first;
    int count = 0;
    for (var p in patients) {
      final session = p['latest_session'];
      if (session != null &&
          session['risk_flag'] == 'high' &&
          session['completed_at'] != null) {
        final completedDate =
            (session['completed_at'] as String).split('T').first;
        if (completedDate.compareTo(weekStartStr) >= 0) count++;
      }
    }
    return count;
  }

  /// Top 3 most recently active patients (sorted by latest session date).
  List<Map<String, dynamic>> get recentPatients {
    final withSessions =
        patients.where((p) => p['latest_session'] != null).toList();
    withSessions.sort((a, b) {
      final dateA = a['latest_session']['completed_at'] as String? ?? '';
      final dateB = b['latest_session']['completed_at'] as String? ?? '';
      return dateB.compareTo(dateA); // Newest first
    });
    return withSessions.take(3).toList();
  }

  // ── Load patients ────────────────────────────────────────────────────────

  Future<void> loadPatients(String doctorId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final data = await _childService.getChildrenForDoctor(doctorId);
      
      // Sort: high risk first, then medium, then low, then pending
      final statusWeight = {
        'high': 0,
        'medium': 1,
        'low': 2,
        'pending': 3,
      };

      data.sort((a, b) {
        final statusA = a['diagnosis_status'] ?? 'pending';
        final statusB = b['diagnosis_status'] ?? 'pending';
        return (statusWeight[statusA] ?? 3).compareTo(statusWeight[statusB] ?? 3);
      });

      patients = data;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Realtime therapy actions listener ────────────────────────────────────

  /// Start listening to therapy_actions realtime changes.
  void startListening() {
    _therapyStreamSub?.cancel();
    _therapyStreamSub = SupabaseClientManager.client
        .from('therapy_actions')
        .stream(primaryKey: ['id'])
        .listen((data) {
      _onTherapyActionsUpdated(data);
    });
  }

  /// Stop listening to realtime changes.
  void stopListening() {
    _therapyStreamSub?.cancel();
    _therapyStreamSub = null;
  }

  void _onTherapyActionsUpdated(List<Map<String, dynamic>> data) {
    // Trigger a rebuild so UI reflects updated therapy action states
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
