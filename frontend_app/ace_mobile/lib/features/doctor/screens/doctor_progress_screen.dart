import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorProgressScreen extends StatefulWidget {
  const DoctorProgressScreen({super.key});

  @override
  State<DoctorProgressScreen> createState() => _DoctorProgressScreenState();
}

class _DoctorProgressScreenState extends State<DoctorProgressScreen> {
  String _selectedPeriod = '3 Months';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Text(
                      'Developmental Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
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
                    children: ['1 Month', '3 Months', '6 Months', '1 Year'].map(
                      (period) {
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
                      },
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Communication Skills Score ──
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
                        'Communication Skills',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Score: 78',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF059669,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 14,
                                  color: Color(0xFF059669),
                                ),
                                Text(
                                  '+5%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'vs last 3 months',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Score chart
                      SizedBox(
                        height: 140,
                        child: CustomPaint(
                          size: const Size(double.infinity, 140),
                          painter: _ProgressChartPainter(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ['Nov', 'Dec', 'Jan', 'Feb']
                            .map(
                              (m) => Text(
                                m,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Regression Alerts ──
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 22,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Regression Alerts',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _RegressionAlertCard(
                  title: 'Verbal Output Decrease',
                  description:
                      'Significant drop in verbal output count observed over the last 5 days compared to baseline.',
                  severity: 'ALERT',
                  severityColor: const Color(0xFFDC2626),
                ),
                const SizedBox(height: 24),

                // ── Milestone Tracking ──
                Row(
                  children: [
                    Text(
                      'Milestone Tracking',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'See All',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: appColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _MilestoneCard(
                  title: 'Eye Contact',
                  description: 'Consistent engagement',
                  status: 'Normal',
                  statusColor: const Color(0xFF059669),
                  icon: Icons.visibility_rounded,
                  iconColor: const Color(0xFF059669),
                ),
                const SizedBox(height: 10),
                _MilestoneCard(
                  title: 'Joint Attention',
                  description: 'Inconsistent response',
                  status: 'Concern',
                  statusColor: const Color(0xFFF59E0B),
                  icon: Icons.people_rounded,
                  iconColor: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 10),
                _MilestoneCard(
                  title: 'Social Smiling',
                  description: 'Rarely observed',
                  status: 'High Risk',
                  statusColor: const Color(0xFFDC2626),
                  icon: Icons.sentiment_satisfied_rounded,
                  iconColor: const Color(0xFFDC2626),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Progress Chart Painter ────────────────────────────────────────────────────

class _ProgressChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [0.55, 0.5, 0.58, 0.62, 0.6, 0.68, 0.72, 0.78];
    final paint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0284C7).withValues(alpha: 0.12),
          const Color(0xFF0284C7).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - (points[i] * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = ((i - 1) / (points.length - 1)) * size.width;
        final prevY = size.height - (points[i - 1] * size.height);
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw end dot
    final lastX = size.width;
    final lastY = size.height - (points.last * size.height);
    canvas.drawCircle(
      Offset(lastX, lastY),
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      3,
      Paint()
        ..color = const Color(0xFF0284C7)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Regression Alert Card ─────────────────────────────────────────────────────

class _RegressionAlertCard extends StatelessWidget {
  final String title;
  final String description;
  final String severity;
  final Color severityColor;

  const _RegressionAlertCard({
    required this.title,
    required this.description,
    required this.severity,
    required this.severityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: severityColor.withValues(alpha: 0.2)),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  severity,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'View Details →',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: appColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Milestone Card ────────────────────────────────────────────────────────────

class _MilestoneCard extends StatelessWidget {
  final String title;
  final String description;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color iconColor;

  const _MilestoneCard({
    required this.title,
    required this.description,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
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
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
