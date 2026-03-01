import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/progress/progress_provider.dart';
import 'package:intl/intl.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().fetchSessionHistory();
    });
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'Unknown Date';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatSessionType(String type) {
    switch (type) {
      case 'eye_contact':
        return 'Eye Contact';
      case 'imitation':
        return 'Pose Imitation';
      case 'emotion':
        return 'Emotion Assessment';
      default:
        return type.toUpperCase();
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'eye_contact':
        return Icons.visibility;
      case 'imitation':
        return Icons.accessibility_new;
      case 'emotion':
        return Icons.sensors;
      default:
        return Icons.games;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Progress History'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!))
              : provider.sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 60, color: textColors.secondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            "No session history yet.",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: textColors.secondary.withValues(alpha: 0.6),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Play a game to see your progress here!",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: textColors.secondary.withValues(alpha: 0.5),
                                ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.fetchSessionHistory(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.sessions.length,
                        itemBuilder: (context, index) {
                          final session = provider.sessions[index];
                          final type = session['session_type'] as String? ?? 'unknown';
                          final score = (session['score'] as num?)?.toDouble() ?? 0.0;
                          final dateStr = session['completed_at'] as String?;
                          final summary = session['ai_summary'] as String? ?? 'No summary available.';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: appColors.primary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getIconForType(type),
                                          color: appColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatSessionType(type),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              _formatDate(dateStr),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: score >= 70 ? appColors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${score.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            color: score >= 70 ? appColors.green : Colors.orange[800],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    summary,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
