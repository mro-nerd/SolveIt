import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/profile/profile_provider.dart';
import 'package:ace_mobile/features/progress/progress_provider.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  /// Tracks which session_type groups are expanded.
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final profile = context.read<ProfileProvider>();
    final childId = profile.currentChild?['id'] as String?;
    final diagnosis =
        profile.currentChild?['diagnosis_status'] as String? ?? 'pending';
    if (childId != null && childId.isNotEmpty) {
      context
          .read<ProgressProvider>()
          .loadSessions(childId, diagnosisStatus: diagnosis);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final provider = context.watch<ProgressProvider>();

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        title: Text(
          '${profile.displayChildName}\'s Progress',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          _RiskBadge(risk: provider.overallRisk),
          const SizedBox(width: 12),
        ],
      ),
      body: provider.isLoading
          ? _buildShimmer()
          : provider.errorMessage != null
              ? _buildError(provider)
              : !provider.hasSessions
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: () async => _loadData(),
                      color: appColors.primary,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildScoreCards(provider),
                          const SizedBox(height: 20),
                          _buildChart(provider),
                          const SizedBox(height: 20),
                          _buildSessionHistory(provider),
                        ],
                      ),
                    ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SCORE CARDS — 2×2 grid
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScoreCards(ProgressProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: kSessionTypes.map((type) {
        return _ScoreCard(
          label: kSessionTypeLabels[type] ?? type,
          score: provider.latestScores[type],
          delta: provider.scoreDeltas[type],
          color: _colorForType(type),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LINE CHART (fl_chart)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildChart(ProgressProvider provider) {
    return Container(
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
          const Text(
            'Score Trends',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        // We'll use the index; actual dates are per-line
                        return Text(
                          '${value.toInt() + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: _buildLineBarsData(provider),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map((spot) => LineTooltipItem(
                              '${spot.y.toStringAsFixed(0)}%',
                              TextStyle(
                                color: spot.bar.color ?? Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData(ProgressProvider provider) {
    final bars = <LineChartBarData>[];

    for (final type in kSessionTypes) {
      final sessions = provider.sessionsByType[type] ?? [];
      if (sessions.isEmpty) continue;

      // Reverse so oldest → newest left to right
      final reversed = sessions.reversed.toList();

      final spots = <FlSpot>[];
      for (int i = 0; i < reversed.length; i++) {
        final score = (reversed[i]['score'] as num?)?.toDouble() ?? 0;
        spots.add(FlSpot(i.toDouble(), score));
      }

      bars.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: _colorForType(type),
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
            radius: 3,
            color: _colorForType(type),
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        belowBarData: BarAreaData(show: false),
      ));
    }

    return bars;
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: kSessionTypes.map((type) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _colorForType(type),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              kSessionTypeLabels[type] ?? type,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SESSION HISTORY — grouped by type, expandable
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSessionHistory(ProgressProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Session History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        ...kSessionTypes.map((type) {
          final sessions = provider.sessionsByType[type] ?? [];
          if (sessions.isEmpty) return const SizedBox.shrink();

          final isExpanded = _expanded[type] ?? false;
          final displayed = isExpanded ? sessions : sessions.take(3).toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
              children: [
                // ── Group header ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _colorForType(type).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _iconForType(type),
                          size: 16,
                          color: _colorForType(type),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        kSessionTypeLabels[type] ?? type,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${sessions.length} sessions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ── Session items ──
                ...displayed.map((session) => _SessionTile(session: session)),

                // ── "Show all" / "Show less" ──
                if (sessions.length > 3)
                  InkWell(
                    onTap: () =>
                        setState(() => _expanded[type] = !isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        isExpanded ? 'Show less' : 'Show all ${sessions.length}',
                        style: TextStyle(
                          fontSize: 13,
                          color: appColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LOADING / ERROR / EMPTY states
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Score card skeletons
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                4,
                (_) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Chart skeleton
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            // List skeletons
            ...List.generate(
              3,
              (_) => Container(
                height: 80,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ProgressProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            provider.errorMessage ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No assessments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first assessment\nto see progress here',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static Color _colorForType(String type) {
    switch (type) {
      case 'mchat':
        return const Color(0xFF7C3AED);
      case 'emotion_assessment':
        return const Color(0xFFF59E0B);
      case 'eye_contact':
        return const Color(0xFF0284C7);
      case 'imitation':
        return const Color(0xFF10B981);
      default:
        return appColors.primary;
    }
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'mchat':
        return Icons.quiz_outlined;
      case 'emotion_assessment':
        return Icons.sentiment_satisfied_alt;
      case 'eye_contact':
        return Icons.visibility_outlined;
      case 'imitation':
        return Icons.accessibility_new;
      default:
        return Icons.assessment;
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SUB WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

/// 2×2 score card.
class _ScoreCard extends StatelessWidget {
  final String label;
  final double? score;
  final double? delta;
  final Color color;

  const _ScoreCard({
    required this.label,
    required this.score,
    required this.delta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score != null ? score!.toStringAsFixed(0) : '—',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 6),
              if (delta != null)
                _DeltaChip(delta: delta!)
              else if (score != null)
                Text(
                  'First session',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small ↑ +8 or ↓ -3 chip.
class _DeltaChip extends StatelessWidget {
  final double delta;
  const _DeltaChip({required this.delta});

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon = isPositive ? '↑' : '↓';
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$icon $sign${delta.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Risk badge for the AppBar.
class _RiskBadge extends StatelessWidget {
  final String risk;
  const _RiskBadge({required this.risk});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (risk) {
      case 'high':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
      case 'medium':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      case 'low':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        risk.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Individual session tile in the history list.
class _SessionTile extends StatelessWidget {
  final Map<String, dynamic> session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final score = (session['score'] as num?)?.toDouble() ?? 0;
    final riskFlag = session['risk_flag'] as String? ?? '';
    final summary = session['ai_summary'] as String?;
    final dateStr = session['completed_at'] as String?;
    final dateFormatted = _formatDate(dateStr);

    Color riskColor;
    switch (riskFlag) {
      case 'high':
        riskColor = const Color(0xFFEF4444);
        break;
      case 'medium':
        riskColor = const Color(0xFFF59E0B);
        break;
      case 'low':
        riskColor = const Color(0xFF10B981);
        break;
      default:
        riskColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Score
              Text(
                score.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 8),
              // Risk badge
              if (riskFlag.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    riskFlag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: riskColor,
                    ),
                  ),
                ),
              const Spacer(),
              // Date
              Text(
                dateFormatted,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          // AI summary
          if (summary != null && summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                summary,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return '';
    }
  }
}
