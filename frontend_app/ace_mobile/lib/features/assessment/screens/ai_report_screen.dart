import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/models/screening_session.dart';
import '../providers/assessment_provider.dart';
import '../providers/mchat_ai_provider.dart';
import '../widgets/ai_streaming_card.dart';

/// Three-tab AI report screen: Interpretation | Full Report | History.
class AiReportScreen extends StatefulWidget {
  const AiReportScreen({super.key});

  @override
  State<AiReportScreen> createState() => _AiReportScreenState();
}

class _AiReportScreenState extends State<AiReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Auto-generate interpretation on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final assessment = context.read<AssessmentProvider>();
      final ai = context.read<MchatAiProvider>();
      if (ai.interpretationText.isEmpty && !ai.isGeneratingInterpretation) {
        ai.generateInterpretation(assessment);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AssessmentProvider, MchatAiProvider>(
      builder: (context, assessment, ai, _) {
        return Scaffold(
          backgroundColor: appColors.background,
          appBar: _buildAppBar(context, assessment, ai),
          body: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _InterpretationTab(assessment: assessment, ai: ai),
                    _ReportTab(assessment: assessment, ai: ai),
                    _HistoryTab(ai: ai),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AssessmentProvider assessment,
    MchatAiProvider ai,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: Color(0xFF1A2B3C),
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: const Text(
        'AI Analysis',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Color(0xFF1A2B3C),
        ),
      ),
      actions: [
        // Save session button
        IconButton(
          icon: const Icon(Icons.save_alt_rounded, color: appColors.primary),
          tooltip: 'Save to history',
          onPressed: () async {
            await ai.saveCompletedSession(assessment);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session saved to history'),
                  backgroundColor: appColors.primary,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: appColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: appColors.secondary.withValues(alpha: 0.7),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(text: 'Interpretation'),
          Tab(text: 'Full Report'),
          Tab(text: 'History'),
        ],
      ),
    );
  }
}

// ─── Tab 1: Interpretation ────────────────────────────────────────────────────

class _InterpretationTab extends StatelessWidget {
  final AssessmentProvider assessment;
  final MchatAiProvider ai;

  const _InterpretationTab({required this.assessment, required this.ai});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk badge summary
          _RiskSummaryRow(
            score: assessment.riskScore,
            level: assessment.riskLevel,
          ),
          const SizedBox(height: 20),

          AiStreamingCard(
            text: ai.interpretationText,
            isStreaming: ai.isGeneratingInterpretation,
            title: 'Behaviour Interpretation',
            icon: Icons.psychology_rounded,
            accentColor: appColors.primary,
          ),

          const SizedBox(height: 16),

          // Re-generate button
          if (!ai.isGeneratingInterpretation)
            Center(
              child: TextButton.icon(
                onPressed: () => ai.generateInterpretation(assessment),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Regenerate'),
                style: TextButton.styleFrom(
                  foregroundColor: appColors.secondary.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Tab 2: Full Report ───────────────────────────────────────────────────────

class _ReportTab extends StatelessWidget {
  final AssessmentProvider assessment;
  final MchatAiProvider ai;

  const _ReportTab({required this.assessment, required this.ai});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          if (ai.reportText.isEmpty && !ai.isGeneratingReport)
            _GenerateReportCta(onGenerate: () => ai.generateReport(assessment))
          else
            AiStreamingCard(
              text: ai.reportText,
              isStreaming: ai.isGeneratingReport,
              title: 'Screening Report',
              icon: Icons.article_rounded,
              accentColor: const Color(0xFF8B5CF6),
            ),

          const SizedBox(height: 16),
          if (ai.reportText.isNotEmpty && !ai.isGeneratingReport)
            Center(
              child: TextButton.icon(
                onPressed: () => ai.generateReport(assessment),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Regenerate'),
                style: TextButton.styleFrom(
                  foregroundColor: appColors.secondary.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GenerateReportCta extends StatelessWidget {
  final VoidCallback onGenerate;
  const _GenerateReportCta({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.article_rounded,
              color: Color(0xFF8B5CF6),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Generate Full Report',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1A2B3C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI will generate a structured clinical-style report including strengths, concerns, risk explanation, and therapy suggestions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: appColors.secondary.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onGenerate,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Generate Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 3: History ───────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final MchatAiProvider ai;
  const _HistoryTab({required this.ai});

  @override
  Widget build(BuildContext context) {
    if (ai.isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: appColors.primary),
      );
    }

    if (ai.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: appColors.secondary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'No past screenings yet',
              style: TextStyle(
                fontSize: 14,
                color: appColors.secondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: ai.history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = ai.history[index];
        final isLatest = index == 0;
        return _HistoryCard(
          session: session,
          isLatest: isLatest,
          onCompare: ai.history.length > 1 && isLatest
              ? () => ai.compareWithSession(
                  current: session,
                  previous: ai.history[1],
                )
              : null,
          comparisonText: ai.comparisonText,
          isComparing: ai.isGeneratingComparison,
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ScreeningSession session;
  final bool isLatest;
  final VoidCallback? onCompare;
  final String comparisonText;
  final bool isComparing;

  const _HistoryCard({
    required this.session,
    required this.isLatest,
    this.onCompare,
    required this.comparisonText,
    required this.isComparing,
  });

  Color get _levelColor {
    switch (session.riskLevel) {
      case 'Low Risk':
        return const Color(0xFF22C55E);
      case 'Medium Risk':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'MMM d, yyyy · h:mm a',
    ).format(session.completedAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLatest
            ? Border.all(color: appColors.primary.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isLatest)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: appColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Latest',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: appColors.primary,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: appColors.secondary.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _levelColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${session.riskScore}/20 · ${session.riskLevel}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _levelColor,
                  ),
                ),
              ),
            ],
          ),

          // Compare button (only on latest when history > 1)
          if (onCompare != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (comparisonText.isNotEmpty || isComparing)
              AiStreamingCard(
                text: comparisonText,
                isStreaming: isComparing,
                title: 'Progress Comparison',
                icon: Icons.compare_arrows_rounded,
                accentColor: const Color(0xFF3B82F6),
              )
            else
              GestureDetector(
                onTap: onCompare,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.compare_arrows_rounded,
                        color: Color(0xFF3B82F6),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Compare with previous screening',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _RiskSummaryRow extends StatelessWidget {
  final int score;
  final String level;

  const _RiskSummaryRow({required this.score, required this.level});

  Color get _color {
    switch (level) {
      case 'Low Risk':
        return const Color(0xFF22C55E);
      case 'Medium Risk':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: _color, size: 20),
          const SizedBox(width: 10),
          Text(
            'Clinical Score: $score/20 · $level',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: _color,
            ),
          ),
          const Spacer(),
          Text(
            '(unmodified by AI)',
            style: TextStyle(
              fontSize: 10,
              color: _color.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
