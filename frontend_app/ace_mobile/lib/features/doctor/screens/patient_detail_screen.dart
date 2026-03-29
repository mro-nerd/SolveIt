import 'package:ace_mobile/backend/backend.dart';
import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/doctor/screens/doctor_therapy_plan_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

/// Shared patient data model used across doctor screens.
class PatientData {
  final String name;
  final int age;
  final String diagnosis;
  final String lastVisit;
  final String status;
  final String since;
  final String? childId;

  const PatientData({
    required this.name,
    required this.age,
    required this.diagnosis,
    required this.lastVisit,
    required this.status,
    required this.since,
    this.childId,
  });
}

class PatientDetailScreen extends StatefulWidget {
  final PatientData patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final SessionService _sessionService = SessionService();
  final TherapyService _therapyService = TherapyService();

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _allSessions = [];
  Map<String, List<Map<String, dynamic>>> _sessionsByType = {};
  Map<String, dynamic>? _therapyPlan;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
      final sessions = await _sessionService.getSessionsForChild(
        widget.patient.childId!,
        limit: 20,
      );
      final plan = await _therapyService.getPlanForChild(
        widget.patient.childId!,
      );

      // Group sessions by type
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final session in sessions) {
        final type = session['session_type'] as String? ?? 'unknown';
        grouped.putIfAbsent(type, () => []);
        grouped[type]!.add(session);
      }

      setState(() {
        _allSessions = sessions;
        _sessionsByType = grouped;
        _therapyPlan = plan;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[PatientDetailScreen] Error: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _formatTypeLabel(String type) {
    switch (type) {
      case 'mchat':
        return 'M-CHAT';
      case 'emotion_assessment':
        return 'Emotion';
      case 'eye_contact':
        return 'Eye Contact';
      case 'imitation':
        return 'Imitation';
      default:
        return type
            .split('_')
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'mchat':
        return const Color(0xFF0284C7);
      case 'emotion_assessment':
        return const Color(0xFFF59E0B);
      case 'eye_contact':
        return const Color(0xFF059669);
      case 'imitation':
        return const Color(0xFF7C3AED);
      default:
        return Colors.grey;
    }
  }

  Color _riskColor(String? risk) {
    switch (risk) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.amber.shade700;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }

  String _formatKeyNicely(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
        .join(' ');
  }

  double _avgScoreForType(String type) {
    final sessions = _sessionsByType[type];
    if (sessions == null || sessions.isEmpty) return 0;
    double total = 0;
    for (final s in sessions) {
      total += (s['score'] as num? ?? 0).toDouble();
    }
    return total / sessions.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: _isLoading
            ? _buildSkeleton()
            : _error != null
                ? _buildError()
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
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 100,
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
                  height: 80,
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

  Widget _buildError() {
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
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back button ──
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Row(
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
            const SizedBox(height: 20),

            // ── App Bar: Child name + age ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.name,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '${widget.patient.age} years old',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _riskColor(widget.patient.diagnosis.toLowerCase())
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.patient.diagnosis.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color:
                          _riskColor(widget.patient.diagnosis.toLowerCase()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Risk Trend Mini-Chart ──
            if (_allSessions.isNotEmpty) _buildMiniChart(),
            if (_allSessions.isNotEmpty) const SizedBox(height: 24),

            // ── Active Therapy Plan Card ──
            _buildTherapyPlanCard(),
            const SizedBox(height: 24),

            // ── Session History ──
            if (_allSessions.isEmpty)
              _buildEmptyState()
            else
              _buildSessionHistory(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Mini Chart ──
  Widget _buildMiniChart() {
    return GestureDetector(
      onTap: _showLegendSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Score Trends',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                Icon(Icons.touch_app, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  'Tap for legend',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: _sessionsByType.entries.map((entry) {
                    final type = entry.key;
                    final sessions = entry.value.take(7).toList().reversed.toList();
                    return LineChartBarData(
                      spots: sessions.asMap().entries.map((e) {
                        return FlSpot(
                          e.key.toDouble(),
                          (e.value['score'] as num? ?? 0).toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: _colorForType(type),
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLegendSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chart Legend',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._sessionsByType.keys.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _colorForType(type),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatTypeLabel(type),
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        'Avg: ${_avgScoreForType(type).toStringAsFixed(1)}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── Therapy Plan Card ──
  Widget _buildTherapyPlanCard() {
    if (_therapyPlan == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade200,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No therapy plan set',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.patient.childId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorTherapyPlanScreen(
                        patient: widget.patient,
                      ),
                    ),
                  ).then((_) => _loadData());
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final level = _therapyPlan!['therapy_level'] ?? 'beginner';
    final notes = _therapyPlan!['notes'] as String?;
    final actions = _therapyPlan!['therapy_actions'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: appColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.assignment_rounded,
                  size: 20,
                  color: appColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Therapy Plan',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      '${actions.length} actions assigned',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  level.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ),
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                notes,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorTherapyPlanScreen(
                      patient: widget.patient,
                    ),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Plan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: appColors.primary,
                side: BorderSide(color: appColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No assessments completed yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Session History ──
  Widget _buildSessionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session History',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        ..._sessionsByType.entries.map((entry) {
          final type = entry.key;
          final sessions = entry.value;
          final avgScore = _avgScoreForType(type);

          return _SessionTypeGroup(
            typeLabel: _formatTypeLabel(type),
            avgScore: avgScore,
            typeColor: _colorForType(type),
            sessions: sessions,
            riskColor: _riskColor,
            formatDate: _formatDate,
            formatKeyNicely: _formatKeyNicely,
          );
        }),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
//  Session Type Group (expandable)
// ════════════════════════════════════════════════════════════════════════════════

class _SessionTypeGroup extends StatefulWidget {
  final String typeLabel;
  final double avgScore;
  final Color typeColor;
  final List<Map<String, dynamic>> sessions;
  final Color Function(String?) riskColor;
  final String Function(String?) formatDate;
  final String Function(String) formatKeyNicely;

  const _SessionTypeGroup({
    required this.typeLabel,
    required this.avgScore,
    required this.typeColor,
    required this.sessions,
    required this.riskColor,
    required this.formatDate,
    required this.formatKeyNicely,
  });

  @override
  State<_SessionTypeGroup> createState() => _SessionTypeGroupState();
}

class _SessionTypeGroupState extends State<_SessionTypeGroup> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final visibleSessions =
        _showAll ? widget.sessions : widget.sessions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.typeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: widget.typeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.typeLabel,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Text(
                'Avg: ${widget.avgScore.toStringAsFixed(1)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.typeColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Session cards
        ...visibleSessions.map(
          (session) => _SessionCard(
            session: session,
            riskColor: widget.riskColor,
            formatDate: widget.formatDate,
            formatKeyNicely: widget.formatKeyNicely,
          ),
        ),

        // Show all toggle
        if (widget.sessions.length > 3)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(
                _showAll ? 'Show less' : 'Show all (${widget.sessions.length})',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: appColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
//  Session Card (expandable raw_metrics)
// ════════════════════════════════════════════════════════════════════════════════

class _SessionCard extends StatefulWidget {
  final Map<String, dynamic> session;
  final Color Function(String?) riskColor;
  final String Function(String?) formatDate;
  final String Function(String) formatKeyNicely;

  const _SessionCard({
    required this.session,
    required this.riskColor,
    required this.formatDate,
    required this.formatKeyNicely,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final score = (widget.session['score'] as num?)?.toDouble() ?? 0;
    final riskFlag = widget.session['risk_flag'] as String?;
    final aiSummary = widget.session['ai_summary'] as String?;
    final completedAt = widget.session['completed_at'] as String?;
    final rawMetrics = widget.session['raw_metrics'] as Map<String, dynamic>?;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Score
                Text(
                  score.toStringAsFixed(0),
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/100',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 12),
                // Risk badge
                if (riskFlag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: widget.riskColor(riskFlag).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      riskFlag.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.riskColor(riskFlag),
                      ),
                    ),
                  ),
                const Spacer(),
                // Date
                Text(
                  widget.formatDate(completedAt),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),

            // AI Summary
            if (aiSummary != null && aiSummary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    aiSummary,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Summary generating...',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),

            // Expanded raw_metrics
            if (_expanded && rawMetrics != null) ...[
              const Divider(height: 24),
              Text(
                'Raw Metrics',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              ...rawMetrics.entries.map((entry) {
                final value = entry.value;
                String displayValue;
                if (value is List) {
                  displayValue = value.length > 5
                      ? '[${value.take(5).join(', ')}... +${value.length - 5} more]'
                      : value.toString();
                } else if (value is Map) {
                  displayValue = '{${value.length} entries}';
                } else {
                  displayValue = value.toString();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          widget.formatKeyNicely(entry.key),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          displayValue,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
