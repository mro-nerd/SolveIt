import 'package:flutter/material.dart';
import 'package:ace_mobile/backend/backend.dart';

/// Manages state for the doctor-side clinical notes composer and sent-notes
/// history. Used by the doctor dashboard to send messages to parents.
class ClinicalNotesProvider extends ChangeNotifier {
  final ClinicalNotesService _service = ClinicalNotesService();

  // ── Compose state ─────────────────────────────────────────────────────
  String _messageText = '';
  String _targetType = 'all'; // 'all' or 'specific'
  String? _selectedParentUid;
  bool _isSending = false;
  String? _sendError;
  bool _sendSuccess = false;

  // ── Parent list for dropdown ──────────────────────────────────────────
  List<Map<String, dynamic>> _parentList = [];
  bool _isLoadingParents = false;

  // ── Sent notes history ────────────────────────────────────────────────
  List<Map<String, dynamic>> _sentNotes = [];
  bool _isLoadingNotes = false;

  // ── Patient-side notes ────────────────────────────────────────────────
  List<Map<String, dynamic>> _parentNotes = [];
  bool _isLoadingParentNotes = false;

  // ── Getters ───────────────────────────────────────────────────────────
  String get messageText => _messageText;
  String get targetType => _targetType;
  String? get selectedParentUid => _selectedParentUid;
  bool get isSending => _isSending;
  String? get sendError => _sendError;
  bool get sendSuccess => _sendSuccess;
  List<Map<String, dynamic>> get parentList => _parentList;
  bool get isLoadingParents => _isLoadingParents;
  List<Map<String, dynamic>> get sentNotes => _sentNotes;
  bool get isLoadingNotes => _isLoadingNotes;
  List<Map<String, dynamic>> get parentNotes => _parentNotes;
  bool get isLoadingParentNotes => _isLoadingParentNotes;

  // ── Compose actions ───────────────────────────────────────────────────

  void setMessageText(String text) {
    _messageText = text;
    // Don't notifyListeners for every keystroke — only on meaningful changes
  }

  void setTargetType(String type) {
    _targetType = type;
    if (type == 'all') _selectedParentUid = null;
    _sendSuccess = false;
    _sendError = null;
    notifyListeners();
  }

  void setSelectedParent(String? parentUid) {
    _selectedParentUid = parentUid;
    _sendSuccess = false;
    _sendError = null;
    notifyListeners();
  }

  void clearComposer() {
    _messageText = '';
    _targetType = 'all';
    _selectedParentUid = null;
    _sendError = null;
    _sendSuccess = false;
    notifyListeners();
  }

  // ── Send note ─────────────────────────────────────────────────────────

  Future<void> sendNote(String doctorId) async {
    if (_messageText.trim().isEmpty) {
      _sendError = 'Please enter a message';
      notifyListeners();
      return;
    }
    if (_targetType == 'specific' && _selectedParentUid == null) {
      _sendError = 'Please select a patient';
      notifyListeners();
      return;
    }

    _isSending = true;
    _sendError = null;
    _sendSuccess = false;
    notifyListeners();

    try {
      await _service.sendNote(
        doctorId: doctorId,
        targetType: _targetType,
        targetParentUid: _selectedParentUid,
        message: _messageText.trim(),
      );
      _sendSuccess = true;
      _messageText = '';
      // Refresh sent notes
      await loadSentNotes(doctorId);
    } catch (e) {
      _sendError = 'Failed to send: $e';
      debugPrint('[ClinicalNotesProvider] sendNote error: $e');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ── Load parent list for dropdown ─────────────────────────────────────

  Future<void> loadParentList(String doctorId) async {
    _isLoadingParents = true;
    notifyListeners();

    try {
      _parentList = await _service.getParentListForDoctor(doctorId);
    } catch (e) {
      debugPrint('[ClinicalNotesProvider] loadParentList error: $e');
      _parentList = [];
    } finally {
      _isLoadingParents = false;
      notifyListeners();
    }
  }

  // ── Load sent notes history ───────────────────────────────────────────

  Future<void> loadSentNotes(String doctorId) async {
    _isLoadingNotes = true;
    notifyListeners();

    try {
      _sentNotes = await _service.getNotesForDoctor(doctorId);
    } catch (e) {
      debugPrint('[ClinicalNotesProvider] loadSentNotes error: $e');
      _sentNotes = [];
    } finally {
      _isLoadingNotes = false;
      notifyListeners();
    }
  }

  // ── Patient-side: load notes for parent ───────────────────────────────

  Future<void> loadNotesForParent(String parentUid) async {
    _isLoadingParentNotes = true;
    notifyListeners();

    try {
      _parentNotes = await _service.getNotesForParent(parentUid);
    } catch (e) {
      debugPrint('[ClinicalNotesProvider] loadNotesForParent error: $e');
      _parentNotes = [];
    } finally {
      _isLoadingParentNotes = false;
      notifyListeners();
    }
  }
}
