import 'package:ace_mobile/backend/backend.dart';
import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/doctor/screens/patient_detail_screen.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class DoctorTherapyPlanScreen extends StatefulWidget {
  final PatientData patient;

  const DoctorTherapyPlanScreen({super.key, required this.patient});

  @override
  State<DoctorTherapyPlanScreen> createState() =>
      _DoctorTherapyPlanScreenState();
}

class _DoctorTherapyPlanScreenState extends State<DoctorTherapyPlanScreen> {
  final TherapyService _therapyService = TherapyService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // Plan data
  String? _planId;
  String _selectedLevel = 'beginner';
  final TextEditingController _notesCtrl = TextEditingController();
  List<Map<String, dynamic>> _actions = [];

  // Levels
  static const _levels = ['beginner', 'intermediate', 'advanced'];
  static const _levelLabels = {
    'beginner': 'Beginner',
    'intermediate': 'Intermediate',
    'advanced': 'Advanced',
  };
  static const _levelIcons = {
    'beginner': Icons.looks_one_rounded,
    'intermediate': Icons.looks_two_rounded,
    'advanced': Icons.looks_3_rounded,
  };
  static const _levelColors = {
    'beginner': Color(0xFF059669),
    'intermediate': Color(0xFF0284C7),
    'advanced': Color(0xFF7C3AED),
  };

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    if (widget.patient.childId == null) {
      setState(() {
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final plan = await _therapyService.getPlanForChild(
        widget.patient.childId!,
      );

      if (plan != null) {
        _planId = plan['id'] as String?;
        _selectedLevel = plan['therapy_level'] as String? ?? 'beginner';
        _notesCtrl.text = plan['notes'] as String? ?? '';
        final rawActions = plan['therapy_actions'] as List? ?? [];
        _actions = rawActions
            .map((a) => Map<String, dynamic>.from(a as Map))
            .toList();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('[TherapyPlanScreen] Error loading plan: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _savePlan() async {
    if (widget.patient.childId == null) return;

    final profileProvider = context.read<ProfileProvider>();
    final doctorId = profileProvider.currentProfile?['id'] as String?;
    if (doctorId == null) {
      _showError('Doctor profile not found');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final planId = await _therapyService.upsertPlan(
        childId: widget.patient.childId!,
        doctorId: doctorId,
        level: _selectedLevel,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      _planId = planId;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Plan saved successfully',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('[TherapyPlanScreen] Save error: $e');
      _showError('Failed to save plan. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteAction(String actionId, int index) async {
    try {
      await _therapyService.deleteAction(actionId);
      setState(() => _actions.removeAt(index));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Action deleted',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('[TherapyPlanScreen] Delete error: $e');
      _showError('Failed to delete action');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text('Error', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: GoogleFonts.poppins(color: appColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showAddActionSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isSavingAction = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Add Therapy Action',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  _SheetField(
                    label: 'Title *',
                    controller: titleCtrl,
                    hint: 'e.g. Eye contact exercise',
                  ),
                  const SizedBox(height: 14),

                  // Description
                  _SheetField(
                    label: 'Description',
                    controller: descCtrl,
                    hint: 'Optional details...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),

                  // Due date
                  Text(
                    'Due Date',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (c, child) => Theme(
                          data: Theme.of(c).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: appColors.primary,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: appColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('MMM d, yyyy').format(selectedDate),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSavingAction || titleCtrl.text.trim().isEmpty
                          ? null
                          : () async {
                              if (titleCtrl.text.trim().isEmpty) return;
                              if (_planId == null) {
                                Navigator.pop(ctx);
                                _showError(
                                  'Please save the plan first before adding actions.',
                                );
                                return;
                              }

                              setSheetState(() => isSavingAction = true);
                              try {
                                await _therapyService.upsertAction(
                                  planId: _planId!,
                                  title: titleCtrl.text.trim(),
                                  description: descCtrl.text.trim().isEmpty
                                      ? null
                                      : descCtrl.text.trim(),
                                  dueDate: selectedDate,
                                );
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  _loadPlan(); // Refresh
                                }
                              } catch (e) {
                                setSheetState(() => isSavingAction = false);
                                debugPrint(
                                  '[TherapyPlanScreen] Add action error: $e',
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: isSavingAction
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Add Action',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: _isLoading
            ? _buildSkeleton()
            : _error != null
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: GoogleFonts.poppins(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _loadPlan,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_ios_rounded,
                              size: 20,
                              color: appColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Back',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: appColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Therapy Plan',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 50), // balance
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Patient name
                  Center(
                    child: Text(
                      widget.patient.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Therapy Level Selector ──
                  Text(
                    'Therapy Level',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _levels.map((level) {
                      final isSelected = _selectedLevel == level;
                      final color = _levelColors[level]!;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: level != 'advanced' ? 8 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedLevel = level),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color
                                    : color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : color.withValues(alpha: 0.2),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _levelIcons[level],
                                    size: 22,
                                    color: isSelected ? Colors.white : color,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _levelLabels[level]!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isSelected ? Colors.white : color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Notes ──
                  Text(
                    'Notes',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _notesCtrl,
                      maxLines: 4,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Add clinical notes (optional)...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF9CA3AF),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Daily Actions ──
                  Row(
                    children: [
                      Text(
                        'Daily Actions',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _planId != null
                            ? _showAddActionSheet
                            : () => _showError(
                                  'Save the plan first to add actions.',
                                ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: appColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add,
                                size: 16,
                                color: appColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Add',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: appColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_actions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.checklist_rounded,
                            size: 40,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No actions yet',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _planId == null
                                ? 'Save the plan first, then add actions'
                                : 'Tap "Add" to create therapy actions',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._actions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final action = entry.value;
                      return _ActionCard(
                        action: action,
                        onDelete: () {
                          final actionId = action['id'] as String?;
                          if (actionId != null) {
                            _deleteAction(actionId, index);
                          }
                        },
                      );
                    }),

                  const SizedBox(height: 16),

                  // ── AI Suggest Button ──
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✨ AI suggestions coming soon!',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            backgroundColor: const Color(0xFF7C3AED),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        'Suggest with AI',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        side: const BorderSide(color: Color(0xFF7C3AED)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),

        // ── Bottom save button ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _savePlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _planId != null ? 'Update Plan' : 'Save Plan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Action Card (dismissible)
// ═══════════════════════════════════════════════════════════════════════════════

class _ActionCard extends StatelessWidget {
  final Map<String, dynamic> action;
  final VoidCallback onDelete;

  const _ActionCard({required this.action, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final title = action['title'] as String? ?? 'Untitled';
    final desc = action['description'] as String?;
    final dueDate = action['due_date'] as String?;
    final isCompleted = action['is_completed'] as bool? ?? false;

    return Dismissible(
      key: Key(action['id']?.toString() ?? title),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF059669).withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 18,
                color: isCompleted ? const Color(0xFF059669) : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (desc != null && desc.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        desc,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (dueDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: appColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDueDate(dueDate),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: appColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDueDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Sheet Field widget
// ═══════════════════════════════════════════════════════════════════════════════

class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _SheetField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: appColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
