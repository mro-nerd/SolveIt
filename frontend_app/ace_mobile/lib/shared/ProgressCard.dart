import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ace_mobile/features/progress/progress_dashboard_screen.dart';

class ProgressGraphCard extends StatelessWidget {
  const ProgressGraphCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = appColors.primary;
    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => const ProgressDashboardScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Overall Development Score",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: primaryColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.bar_chart, size: 18, color: primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "82%",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 32,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.trending_up, size: 16, color: appColors.green),
              const SizedBox(width: 4),
              Text(
                "+15%",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: appColors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: DevelopmentLineChartPainter(color: primaryColor),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ["W1", "W2", "W3", "W4"]
                  .map(
                    (w) => Text(
                      w,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textColors.secondary.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class DevelopmentLineChartPainter extends CustomPainter {
  final Color color;

  DevelopmentLineChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;

    // curve 
    path.moveTo(0, height * 0.8);
    path.cubicTo(
      width * 0.2,
      height * 0.9,
      width * 0.3,
      height * 0.4,
      width * 0.4,
      height * 0.5,
    );
    path.cubicTo(
      width * 0.5,
      height * 0.6,
      width * 0.7,
      height * 0.2,
      width * 0.8,
      height * 0.3,
    );
    path.cubicTo(
      width * 0.9,
      height * 0.4,
      width * 0.95,
      height * 0.1,
      width,
      height * 0.2,
    );

    // Create the background gradient fill
    final fillPath = Path.from(path);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
