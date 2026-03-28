import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ace_mobile/backend/backend.dart';

class ProfileProvider extends ChangeNotifier {
  // ── New domain services (injected or defaulted) ──────────────────────────
  final ProfileService _profileService;
  final ChildService _childService;

  ProfileProvider({
    ProfileService? profileService,
    ChildService? childService,
  })  : _profileService = profileService ?? ProfileService(),
        _childService = childService ?? ChildService();

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _kParentName = 'profile_parent_name';
  static const _kParentEmail = 'profile_parent_email';
  static const _kChildName = 'profile_child_name';
  static const _kChildDob = 'profile_child_dob';
  static const _kChildGender = 'profile_child_gender';
  static const _kChildDiagnosis = 'profile_child_diagnosis';
  static const _kPhotoPath = 'profile_photo_path';
  static const _kUserRole = 'user_role';

  // ── State (local / SharedPreferences) ────────────────────────────────────
  String parentName = '';
  String parentEmail = '';
  String childName = '';
  String childDob = '';
  String childGender = '';
  String childDiagnosis = '';
  String? photoPath;
  String userRole = ''; // 'parent' | 'doctor' | ''

  // ── Supabase-backed state ────────────────────────────────────────────────
  Map<String, dynamic>? _profile;       // full profile row from Supabase
  Map<String, dynamic>? _currentChild;  // current child row from Supabase

  Map<String, dynamic>? get currentProfile => _profile;
  Map<String, dynamic>? get currentChild => _currentChild;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Role resolved from Supabase profile, falling back to local prefs.
  String get currentRole {
    if (_profile != null && _profile!['role'] != null) {
      return _profile!['role'] as String;
    }
    return userRole.isNotEmpty ? userRole : 'parent';
  }

  bool get isDoctor => currentRole == 'doctor';
  bool get isParent => currentRole == 'parent';
  bool get hasSelectedRole => userRole.isNotEmpty || _profile?['role'] != null;

  // ── Load from SharedPreferences ──────────────────────────────────────────
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

    // If local child name is empty, try pulling from Supabase
    if (childName.isEmpty) {
      await _loadChildFromSupabase();
    }
  }

  // ── Load profile from Supabase using Firebase UID ────────────────────────
  /// Call this after Firebase sign-in to hydrate the provider with
  /// the Supabase profile + children data.
  Future<void> loadProfile(String firebaseUid) async {
    try {
      _profile = await _profileService.getProfile(firebaseUid);

      if (_profile != null) {
        // Sync role from Supabase → local
        userRole = _profile!['role'] as String? ?? 'parent';
        await _save(_kUserRole, userRole);

        // Sync display name → local
        final dn = _profile!['display_name'] as String? ?? '';
        if (dn.isNotEmpty) {
          parentName = dn;
          await _save(_kParentName, parentName);
        }

        // Load first child for this parent
        await _loadChildFromSupabase();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[ProfileProvider] loadProfile error: $e');
    }
  }

  /// Pulls the first child row from Supabase for the current profile.
  Future<void> _loadChildFromSupabase() async {
    if (_profile == null) return;
    try {
      final children =
          await _childService.getChildrenForParent(_profile!['id']);
      if (children.isNotEmpty) {
        _currentChild = children.first;
        childName = _currentChild!['child_name'] ?? '';
        childDob = _currentChild!['date_of_birth'] ?? '';
        childGender = _currentChild!['gender'] ?? '';
        childDiagnosis = _currentChild!['diagnosis_status'] ?? '';
        await _save(_kChildName, childName);
        await _save(_kChildDob, childDob);
        await _save(_kChildGender, childGender);
        await _save(_kChildDiagnosis, childDiagnosis);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ProfileProvider] _loadChildFromSupabase error: $e');
    }
  }

  // ── Supabase Sync ────────────────────────────────────────────────────────
  Future<void> syncToSupabase() async {
    try {
      if (parentName.isNotEmpty && parentEmail.isNotEmpty) {
        final firebaseUid =
            _profile?['firebase_uid'] as String? ?? '';
        if (firebaseUid.isNotEmpty) {
          await _profileService.upsertProfile(
            firebaseUid: firebaseUid,
            role: currentRole,
            displayName: parentName,
            email: parentEmail,
          );
        }
      }
    } catch (e) {
      debugPrint('[ProfileProvider] syncToSupabase error: $e');
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
    if (sync) await syncToSupabase();
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
