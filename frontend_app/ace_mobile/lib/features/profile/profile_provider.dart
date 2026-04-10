import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ace_mobile/backend/backend.dart';

class ProfileProvider extends ChangeNotifier {
  // ── New domain services (injected or defaulted) ──────────────────────────
  final ChildService _childService;
  final AuthService _authService;

  ProfileProvider({
    ChildService? childService,
    AuthService? authService,
  })  : _childService = childService ?? ChildService(),
        _authService = authService ?? AuthService();

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

  /// Expose the AuthService so screens can call signIn / signUp / signOut.
  AuthService get authService => _authService;

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

    // If user is logged in via Supabase, hydrate from remote
    if (SupabaseClientManager.isLoggedIn) {
      await initializeFromSupabase();
    }
  }

  // ── Initialize profile from Supabase Auth ───────────────────────────────
  /// Called after Supabase session is confirmed (login or cold start).
  /// Fetches the Supabase profile; if none exists, [profileExists] will
  /// be false → AuthWrapper sends user to the role-selection screen.
  Future<void> initializeFromSupabase() async {
    try {
      _profile = await _authService.fetchCurrentProfile();

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
      debugPrint('[ProfileProvider] initializeFromSupabase error: $e');
      // Fallback: mark loaded so the app doesn't get stuck
      _loaded = true;
      notifyListeners();
    }
  }

  /// Whether a Supabase profile has been fetched/created.
  bool get profileExists => _profile != null;

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
  /// Immediately updates UI — zero network calls. Sessions refresh in background.
  void switchChild(Map<String, dynamic> child) {
    _currentChild = child;
    _hydrateLocalFromChild(child);
    notifyListeners();
    // Refresh sessions silently in background
    _refreshSessionsForChild(child['id'] as String);
  }

  /// Sessions for the current child — updated in background after switchChild.
  List<Map<String, dynamic>> _currentChildSessions = [];
  List<Map<String, dynamic>> get currentChildSessions => _currentChildSessions;

  Future<void> _refreshSessionsForChild(String childId) async {
    try {
      final sessions = await SessionService().getSessionsForChild(childId);
      _currentChildSessions = sessions;
      notifyListeners();
    } catch (e) {
      debugPrint('[ProfileProvider] Background session refresh failed: $e');
    }
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

  /// Update an existing child's details in Supabase, then reload the list.
  Future<void> updateChildInSupabase({
    required String childId,
    required String name,
    required String dob,
    required String gender,
    String? diagnosisStatus,
  }) async {
    await _childService.updateChild(
      childId: childId,
      name: name,
      dob: dob,
      gender: gender,
      diagnosisStatus: diagnosisStatus ?? 'pending',
    );
    // Reload the children list so the UI reflects changes
    await _loadChildFromSupabase();
    // If editing the currently active child, re-hydrate local state
    if (_currentChild != null && _currentChild!['id'] == childId) {
      final updated = _children.firstWhere(
        (c) => c['id'] == childId,
        orElse: () => _currentChild!,
      );
      _currentChild = updated;
      _hydrateLocalFromChild(updated);
    }
    notifyListeners();
  }

  // ── Supabase Sync ────────────────────────────────────────────────────────
  Future<void> syncToSupabase() async {
    try {
      if (parentName.isNotEmpty && parentEmail.isNotEmpty && _profile != null) {
        final profileId = _profile!['id'] as String?;
        if (profileId != null) {
          await SupabaseClientManager.client
              .from('profiles')
              .update({
                'display_name': parentName,
                'email': parentEmail,
                'role': currentRole,
              })
              .eq('id', profileId);
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

  // ── Full logout / reset ─────────────────────────────────────────────────
  /// Clears ALL in-memory state and removes every profile-related key from
  /// SharedPreferences. Call this during sign-out so the next launch
  /// starts completely fresh (GetStarted → ChooseProfession).
  Future<void> clearAll() async {
    // 1. Wipe in-memory state
    parentName = '';
    parentEmail = '';
    childName = '';
    childDob = '';
    childGender = '';
    childDiagnosis = '';
    photoPath = null;
    userRole = '';
    _profile = null;
    _currentChild = null;
    _children = [];
    _loaded = false;

    // 2. Wipe SharedPreferences (all profile + onboarding keys)
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }
}
