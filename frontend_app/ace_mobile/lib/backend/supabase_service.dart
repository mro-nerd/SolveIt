import 'package:ace_mobile/backend/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupabaseService {
  SupabaseClient get _db => SupabaseClientManager.client;
  String? get _firebaseUid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> upsertProfile(String parentName, String email) async {
    try {
      await _db.from('profiles').upsert({
        'firebase_uid': _firebaseUid,
        'parent_name': parentName,
        'email': email,
      }, onConflict: 'firebase_uid');
    } catch (e) {
      print('Error in upsertProfile: $e');
    }
  }

  Future<String?> getProfileId() async {
    try {
      final response = await _db
          .from('profiles')
          .select('id')
          .eq('firebase_uid', _firebaseUid!)
          .maybeSingle();
      return response?['id'] as String?;
    } catch (e) {
      print('Error in getProfileId: $e');
      return null;
    }
  }

  Future<void> saveChild(String childName, DateTime dob, String gender) async {
    try {
      final profileId = await getProfileId();
      if (profileId == null) return;

      await _db.from('children').upsert({
        'parent_id': profileId,
        'child_name': childName,
        'date_of_birth': dob.toIso8601String(),
        'gender': gender,
      });
    } catch (e) {
      print('Error in saveChild: $e');
    }
  }

  Future<Map<String, dynamic>?> getChild() async {
    try {
      final profileId = await getProfileId();
      if (profileId == null) return null;

      final response = await _db
          .from('children')
          .select()
          .eq('parent_id', profileId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error in getChild: $e');
      return null;
    }
  }

  Future<void> saveSession(String sessionType, double score,
      Map<String, dynamic> rawMetrics, {String? aiSummary}) async {
    try {
      final child = await getChild();
      if (child == null) return;

      await _db.from('sessions').insert({
        'child_id': child['id'],
        'session_type': sessionType,
        'score': score,
        'raw_metrics': rawMetrics,
        'ai_summary': aiSummary,
      });
    } catch (e) {
      print('Error in saveSession: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSessionHistory() async {
    try {
      final child = await getChild();
      if (child == null) return [];

      final response = await _db
          .from('sessions')
          .select()
          .eq('child_id', child['id'])
          .order('completed_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error in getSessionHistory: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLatestSession(String sessionType) async {
    try {
      final child = await getChild();
      if (child == null) return null;

      final response = await _db
          .from('sessions')
          .select()
          .eq('child_id', child['id'])
          .eq('session_type', sessionType)
          .order('completed_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error in getLatestSession: $e');
      return null;
    }
  }
}
