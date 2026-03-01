import 'package:flutter/foundation.dart';
import 'package:ace_mobile/backend/backend.dart';

class ProgressProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _sessions = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get sessions => _sessions;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSessionHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sessions = await _supabase.getSessionHistory();
    } catch (e) {
      _errorMessage = 'Failed to load progress history: $e';
      print('Error fetching sessions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to get the average score for a specific session type
  double getAverageScore(String type) {
    final typeSessions = _sessions.where((s) => s['session_type'] == type).toList();
    if (typeSessions.isEmpty) return 0.0;
    
    double total = 0;
    for (var session in typeSessions) {
      // Handle parsing if it comes back as int or double
      total += (session['score'] as num?)?.toDouble() ?? 0.0;
    }
    return total / typeSessions.length;
  }
}
