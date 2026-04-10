import 'package:ace_mobile/backend/backend.dart';
import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/doctor/screens/patient_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class DoctorProgressScreen extends StatefulWidget {
  final PatientData patient;

  const DoctorProgressScreen({super.key, required this.patient});

  @override
  State<DoctorProgressScreen> createState() => _DoctorProgressScreenState();
}

class _DoctorProgressScreenState extends State<DoctorProgressScreen> {
  final SessionService _sessionService = SessionService();

  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = '3 Months';

  List<Map<String, dynamic>> _allSessions = [];
  Map<String, List<Map<String, dynamic>>> _sessionsByType = {};

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
        limit: 50,
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
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[DoctorProgressScreen] Error: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ── Period filtering ──────────────────────────────────────────────────────

  int _periodDays() {
    switch (_selectedPeriod) {
      case '1 Month':
        return 30;
      case '3 Months':
        return 90;
      case '6 Months':
        return 180;
      case '1 Year':
        return 365;
      default:
        return 90;
    }
  }

  List<Map<String, dynamic>> _filteredSessions() {
    final cutoff = DateTime.now().subtract(Duration(days: _periodDays()));
    return _allSessions.where((s) {
      final dateStr = s['completed_at'] as String?;
      if (dateStr == null) return false;
      try {
        return DateTime.parse(dateStr).isAfter(cutoff);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _filteredByType() {
    final cutoff = DateTime.now().subtract(Duration(days: _periodDays()));
    final result = <String, List<Map<String, dynamic>>>{};
    for (final entry in _sessionsByType.entries) {
      final filtered = entry.value.where((s) {
        final dateStr = s['completed_at'] as String?;
        if (dateStr == null) return false;
        try {
          return DateTime.parse(dateStr).isAfter(cutoff);
        } catch (_) {
          return false;
        }
      }).toList();
      if (filtered.isNotEmpty) {
        result[entry.key] = filtered;
      }
    }
    return result;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
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
        return const Color(0xFFDC2626);
      case 'medium':
        return Colors.amber.shade700;
      case 'low':
        return const Color(0xFF059669);
      default:
        return Colors.grey;
    }
  }

  double _avgScoreForSessions(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) return 0;
    double total = 0;
    for (final s in sessions) {
      total += (s['score'] as num? ?? 0).toDouble();
    }
    return total / sessions.length;
  }

  // Compute delta % between latest and previous session of same type
  Map<String, double?> _computeDeltas() {
    final deltas = <String, double?>{};
    for (final entry in _sessionsByType.entries) {
      final sessions = entry.value;
      if (sessions.length >= 2) {
        final latest = (sessions.first['score'] as num?)?.toDouble() ?? 0;
        final prev = (sessions[1]['score'] as num?)?.toDouble() ?? 0;
        deltas[entry.key] = prev > 0 ? ((latest - prev) / prev) * 100 : null;
      } else {
        deltas[entry.key] = null;
      }
    }
    return deltas;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
              height: 180,
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
    final filtered = _filteredSessions();
    final filteredByType = _filteredByType();
    final overallAvg = _avgScoreForSessions(filtered);
    final deltas = _computeDeltas();

    // Compute overall delta (average of all type deltas)
    final nonNullDeltas = deltas.values.whereType<double>().toList();
    final overallDelta =
        nonNullDeltas.isNotEmpty
            ? nonNullDeltas.reduce((a, b) => a + b) / nonNullDeltas.length
            : null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header with back button ──
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
            const SizedBox(height: 16),
            // ── Patient name & title ──
            Text(
              widget.patient.name,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Developmental Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: appColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.ios_share_rounded,
                        size: 16,
                        color: appColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Share',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: appColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Period Filter Tabs ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    ['1 Month', '3 Months', '6 Months', '1 Year'].map((
                      period,
                    ) {
                      final isSelected = _selectedPeriod == period;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPeriod = period),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? appColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? appColors.primary
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              period,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // ── Overall Score Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
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
                  Text(
                    'Overall Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    _buildNoDataCard(
                      'No sessions in this period',
                      'Complete assessments to see progress data here.',
                    )
                  else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            'Score: ${overallAvg.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (overallDelta != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (overallDelta >= 0
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626))
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  overallDelta >= 0
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  size: 14,
                                  color: overallDelta >= 0
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626),
                                ),
                                Text(
                                  '${overallDelta >= 0 ? '+' : ''}${overallDelta.toStringAsFixed(0)}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: overallDelta >= 0
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Text(
                      'vs previous period',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Per-type score bars
                    ...filteredByType.entries.map((entry) {
                      final type = entry.key;
                      final avg = _avgScoreForSessions(entry.value);
                      final color = _colorForType(type);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 70,
                              child: Text(
                                _formatTypeLabel(type),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (avg / 100).clamp(0.0, 1.0),
                                  backgroundColor: color.withValues(alpha: 0.1),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              avg.toStringAsFixed(0),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color,
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
            const SizedBox(height: 24),

            // ── AI Summary (latest session) ──
            _buildAiSummaryCard(),
            const SizedBox(height: 24),

            // ── Session Breakdown ──
            if (filteredByType.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.assessment_rounded,
                    size: 22,
                    color: Color(0xFF374151),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Session Breakdown',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ...filteredByType.entries.map((entry) {
                final type = entry.key;
                final sessions = entry.value;
                final avg = _avgScoreForSessions(sessions);
                final delta = deltas[type];

                return _SessionBreakdownCard(
                  typeLabel: _formatTypeLabel(type),
                  typeColor: _colorForType(type),
                  avgScore: avg,
                  delta: delta,
                  sessionCount: sessions.length,
                  latestRisk: sessions.isNotEmpty
                      ? sessions.first['risk_flag'] as String?
                      : null,
                  riskColor: _riskColor,
                );
              }),
            ] else
              _buildNoDataCard(
                'No sessions found',
                'Complete assessments to see a detailed breakdown.',
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSummaryCard() {
    // Get the latest session's AI summary
    String? aiSummary;
    String? sessionType;
    String? completedAt;

    if (_allSessions.isNotEmpty) {
      final latest = _allSessions.first;
      aiSummary = latest['ai_summary'] as String?;
      sessionType = latest['session_type'] as String?;
      completedAt = latest['completed_at'] as String?;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
        ),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI Assessment Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              if (sessionType != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _colorForType(sessionType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatTypeLabel(sessionType),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _colorForType(sessionType),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (aiSummary != null && aiSummary.isNotEmpty)
            Text(
              aiSummary,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF6B7280),
                height: 1.6,
              ),
            )
          else
            Text(
              _allSessions.isEmpty
                  ? 'No sessions available. Complete an assessment to generate an AI summary.'
                  : 'Summary not yet generated for the latest session.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic,
              ),
            ),
          if (completedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Latest session: ${_formatDate(completedAt)}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoDataCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.show_chart_rounded,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
}

// ── Session Breakdown Card ──────────────────────────────────────────────────────

class _SessionBreakdownCard extends StatelessWidget {
  final String typeLabel;
  final Color typeColor;
  final double avgScore;
  final double? delta;
  final int sessionCount;
  final String? latestRisk;
  final Color Function(String?) riskColor;

  const _SessionBreakdownCard({
    required this.typeLabel,
    required this.typeColor,
    required this.avgScore,
    required this.delta,
    required this.sessionCount,
    required this.latestRisk,
    required this.riskColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                avgScore.toStringAsFixed(0),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  '$sessionCount session${sessionCount != 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          // Delta badge
          if (delta != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (delta! >= 0
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    delta! >= 0
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 12,
                    color: delta! >= 0
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                  ),
                  Text(
                    '${delta! >= 0 ? '+' : ''}${delta!.toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: delta! >= 0
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            )
          else if (latestRisk != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: riskColor(latestRisk).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                latestRisk!.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: riskColor(latestRisk),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
