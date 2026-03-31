import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' show User;
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
  List<Map<String, dynamic>> _children = []; // all children for this parent

  Map<String, dynamic>? get currentProfile => _profile;
  Map<String, dynamic>? get currentChild => _currentChild;
  List<Map<String, dynamic>> get children => _children;
  bool get hasMultipleChildren => _children.length > 1;

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

  /// Whether a Supabase profile has been fetched/created.
  bool get profileExists => _profile != null;

  /// Called by AuthWrapper after Firebase sign-in.
  /// Fetches the existing Supabase profile; if none exists,
  /// [profileExists] will be false → AuthWrapper sends user
  /// to the role-selection screen.
  Future<void> initializeFromFirebase(User firebaseUser) async {
    try {
      _profile = await _profileService.getProfile(firebaseUser.uid);

      if (_profile != null) {
        // Existing user — hydrate local state from Supabase
        userRole = _profile!['role'] as String? ?? 'parent';
        await _save(_kUserRole, userRole);

        final dn = _profile!['display_name'] as String? ?? '';
        if (dn.isNotEmpty) {
          parentName = dn;
          await _save(_kParentName, parentName);
        }

        final em = _profile!['email'] as String? ?? '';
        if (em.isNotEmpty) {
          parentEmail = em;
          await _save(_kParentEmail, parentEmail);
        }

        await _loadChildFromSupabase();
      }
      // If _profile is null, user has never selected a role yet.
      // AuthWrapper will check profileExists and route to RoleSelectionScreen.
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[ProfileProvider] initializeFromFirebase error: $e');
      // Fallback: mark loaded so the app doesn't get stuck
      _loaded = true;
      notifyListeners();
    }
  }

  /// Pulls all children from Supabase for the current profile
  /// and sets the first one (or previously selected one) as active.
  Future<void> _loadChildFromSupabase() async {
    if (_profile == null) return;
    try {
      _children =
          await _childService.getChildrenForParent(_profile!['id']);
      if (_children.isNotEmpty) {
        // Keep current child if still valid, otherwise pick first
        if (_currentChild != null) {
          final stillExists = _children.any(
            (c) => c['id'] == _currentChild!['id'],
          );
          if (!stillExists) _currentChild = _children.first;
        } else {
          _currentChild = _children.first;
        }
        _hydrateLocalFromChild(_currentChild!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ProfileProvider] _loadChildFromSupabase error: $e');
    }
  }

  /// Hydrate local SharedPreferences state from a child map.
  Future<void> _hydrateLocalFromChild(Map<String, dynamic> child) async {
    childName = child['child_name'] ?? '';
    childDob = child['date_of_birth'] ?? '';
    childGender = child['gender'] ?? '';
    childDiagnosis = child['diagnosis_status'] ?? '';
    await _save(_kChildName, childName);
    await _save(_kChildDob, childDob);
    await _save(_kChildGender, childGender);
    await _save(_kChildDiagnosis, childDiagnosis);
  }

  /// Switch the active child (used when parent has multiple children).
  void switchChild(Map<String, dynamic> child) {
    _currentChild = child;
    _hydrateLocalFromChild(child);
    notifyListeners();
  }

  /// Add a brand-new child via the "Add Child" flow.
  /// Returns the newly created child map (which includes the generated join_code).
  Future<Map<String, dynamic>> addChild({
    required String name,
    required DateTime dob,
    required String gender,
  }) async {
    if (_profile == null) throw Exception('Profile not loaded');
    final newChild = await _childService.createChild(
      parentId: _profile!['id'],
      name: name,
      dob: dob,
      gender: gender,
    );
    // Reload list & switch to the new child
    await _loadChildFromSupabase();
    switchChild(newChild);
    return newChild;
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

      if (_currentChild != null) {
        final childId = _currentChild!['id'] as String?;
        if (childId != null && childName.isNotEmpty) {
          String formattedDob = childDob;
          // Frontend typically sets dob as 'DD / MM / YYYY'
          if (childDob.contains('/')) {
            final parts = childDob.split('/');
            if (parts.length == 3) {
              final d = parts[0].trim().padLeft(2, '0');
              final m = parts[1].trim().padLeft(2, '0');
              final y = parts[2].trim();
              formattedDob = '$y-$m-$d';
            }
          }
          await _childService.updateChild(
            childId: childId,
            name: childName,
            dob: formattedDob,
            gender: childGender.isNotEmpty ? childGender : 'Not specified',
            diagnosisStatus: childDiagnosis,
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
