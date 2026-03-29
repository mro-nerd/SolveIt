import 'package:flutter/material.dart';
import 'package:ace_mobile/backend/backend.dart';

class DoctorDashboardProvider extends ChangeNotifier {
  final ChildService _childService;

  DoctorDashboardProvider({ChildService? childService})
      : _childService = childService ?? ChildService();

  List<Map<String, dynamic>> patients = [];
  bool isLoading = false;
  String? error;

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
}
