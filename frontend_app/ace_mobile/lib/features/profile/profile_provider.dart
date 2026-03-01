import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ace_mobile/backend/backend.dart';

class ProfileProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _kParentName = 'profile_parent_name';
  static const _kParentEmail = 'profile_parent_email';
  static const _kChildName = 'profile_child_name';
  static const _kChildDob = 'profile_child_dob';
  static const _kChildGender = 'profile_child_gender';
  static const _kChildDiagnosis = 'profile_child_diagnosis';
  static const _kPhotoPath = 'profile_photo_path';
  static const _kUserRole = 'user_role';

  // ── State ─────────────────────────────────────────────────────────────────
  String parentName = '';
  String parentEmail = '';
  String childName = '';
  String childDob = '';
  String childGender = '';
  String childDiagnosis = '';
  String? photoPath; // local file path after image-pick
  String userRole = ''; // 'parent' | 'doctor' | ''

  bool _loaded = false;
  bool get isLoaded => _loaded;

  // ── Load from prefs ───────────────────────────────────────────────────────
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    parentName = prefs.getString(_kParentName) ?? '';
    parentEmail = prefs.getString(_kParentEmail) ?? '';
    childName = prefs.getString(_kChildName) ?? '';
    childDob = prefs.getString(_kChildDob) ?? '';
    childGender = prefs.getString(_kChildGender) ?? '';
    childDiagnosis = prefs.getString(_kChildDiagnosis) ?? '';
    photoPath = prefs.getString(_kPhotoPath);
    userRole = prefs.getString(_kUserRole) ?? '';
    _loaded = true;
    notifyListeners();
    // Auto-sync on load to ensure Supabase has the latest data
    await syncToSupabase();

    // If local name is empty but Supabase has it, load it down
    if (childName.isEmpty) {
      final childData = await _supabase.getChild();
      if (childData != null && childData['child_name'] != null) {
        childName = childData['child_name'];
        if (childData['date_of_birth'] != null) {
          childDob = childData['date_of_birth'];
        }
        if (childData['gender'] != null) {
          childGender = childData['gender'];
        }
        notifyListeners();
      }
    }
  }

  // ── Supabase Sync ─────────────────────────────────────────────────────────
  Future<void> syncToSupabase() async {
    if (parentName.isNotEmpty && parentEmail.isNotEmpty) {
      await _supabase.upsertProfile(parentName, parentEmail);
    }
    
    // As long as there is a child name, sync the child profile.
    if (childName.isNotEmpty) {
      final dob = DateTime.tryParse(childDob) ?? DateTime.now();
      await _supabase.saveChild(childName, dob, childGender);
    }
  }

  // ── Save helpers ──────────────────────────────────────────────────────────
  Future<void> _save(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> updateParentName(String v, {bool sync = true}) async {
    parentName = v;
    await _save(_kParentName, v);
    notifyListeners();
    if (sync) await syncToSupabase();
  }

  Future<void> updateParentEmail(String v, {bool sync = true}) async {
    parentEmail = v;
    await _save(_kParentEmail, v);
    notifyListeners();
    if (sync) await syncToSupabase();
  }

  Future<void> updateChildName(String v, {bool sync = true}) async {
    childName = v;
    await _save(_kChildName, v);
    notifyListeners();
    if (sync) await syncToSupabase();
  }

  Future<void> updateChildDob(String v, {bool sync = true}) async {
    childDob = v;
    await _save(_kChildDob, v);
    notifyListeners();
    if (sync) await syncToSupabase();
  }

  Future<void> updateChildGender(String v, {bool sync = true}) async {
    childGender = v;
    await _save(_kChildGender, v);
    notifyListeners();
    if (sync) await syncToSupabase();
  }

  Future<void> updateChildDiagnosis(String v, {bool sync = true}) async {
    childDiagnosis = v;
    await _save(_kChildDiagnosis, v);
    notifyListeners();
    if (sync) await syncToSupabase(); // Diagnosis is not currently sent to Supabase in saveChild, but keeping pattern consistent
  }

  Future<void> updatePhotoPath(String path) async {
    photoPath = path;
    await _save(_kPhotoPath, path);
    notifyListeners();
  }

  Future<void> updateUserRole(String role) async {
    userRole = role;
    await _save(_kUserRole, role);
    notifyListeners();
  }

  bool get hasSelectedRole => userRole.isNotEmpty;
  bool get isDoctor => userRole == 'doctor';
  bool get isParent => userRole == 'parent';

  // ── Avatar widget helper ──────────────────────────────────────────────────
  ImageProvider get avatarImage {
    if (photoPath != null && File(photoPath!).existsSync()) {
      return FileImage(File(photoPath!));
    }
    return const AssetImage('assets/images/poster.png');
  }

  // ── Display helpers ───────────────────────────────────────────────────────
  String get displayParentName => parentName.isNotEmpty ? parentName : 'You';

  String get displayChildName =>
      childName.isNotEmpty ? childName : 'Your Child';
}
