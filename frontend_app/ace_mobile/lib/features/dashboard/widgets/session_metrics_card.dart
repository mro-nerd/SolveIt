import 'package:flutter/material.dart';

class SessionMetricsCard extends StatelessWidget {
  final String sessionType;
  final Map<String, dynamic> rawMetrics;
  final double score;
  final String riskFlag;
  final DateTime completedAt;

  const SessionMetricsCard({
    super.key,
    required this.sessionType,
    required this.rawMetrics,
    required this.score,
    required this.riskFlag,
    required this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatSessionType(sessionType),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _RiskBadge(riskFlag: riskFlag),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Completed: ${_formatDate(completedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const Divider(height: 20),
            // Score row
            _MetricRow(label: 'Score', value: '${score.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            // Dynamic metrics based on session type
            ..._buildMetricRows(sessionType, rawMetrics),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMetricRows(String type, Map<String, dynamic> metrics) {
    switch (type) {
      case 'mchat':
        return [
          _MetricRow(label: 'Total Flags', value: '${metrics['total_flags'] ?? '-'}'),
          _MetricRow(label: 'Critical Flags', value: '${metrics['critical_flags'] ?? '-'}'),
          _MetricRow(label: 'Questions Answered', value: '${metrics['answered'] ?? '-'}'),
        ];
      case 'imitation':
        return [
          _MetricRow(label: 'Poses Attempted', value: '${metrics['poses_attempted'] ?? '-'}'),
          _MetricRow(label: 'Poses Matched', value: '${metrics['poses_matched'] ?? '-'}'),
          _MetricRow(label: 'Avg Match %', value: '${metrics['avg_match_percent']?.toStringAsFixed(1) ?? '-'}%'),
          _MetricRow(label: 'Best Match', value: '${metrics['best_match_percent']?.toStringAsFixed(1) ?? '-'}%'),
        ];
      case 'eye_contact':
        return [
          _MetricRow(label: 'Tracking Duration', value: '${metrics['duration_seconds'] ?? '-'}s'),
          _MetricRow(label: 'Contact Frames', value: '${metrics['contact_frames'] ?? '-'}'),
          _MetricRow(label: 'Avg Gaze Score', value: '${metrics['avg_gaze_score']?.toStringAsFixed(1) ?? '-'}%'),
        ];
      case 'emotion_assessment':
        return [
          _MetricRow(label: 'Dominant Emotion', value: '${metrics['dominant_emotion'] ?? '-'}'),
          _MetricRow(label: 'Emotions Detected', value: '${(metrics['emotions_detected'] as List?)?.join(', ') ?? '-'}'),
          _MetricRow(label: 'Frames Analyzed', value: '${metrics['frames_analyzed'] ?? '-'}'),
        ];
      default:
        // Fallback: display all key-value pairs cleanly
        return metrics.entries.map((e) =>
          _MetricRow(label: _formatKey(e.key), value: '${e.value}')
        ).toList();
    }
  }

  String _formatSessionType(String type) {
    const names = {
      'mchat': 'M-CHAT Assessment',
      'imitation': 'Copy the Pose',
      'eye_contact': 'Follow the Butterfly',
      'emotion_assessment': 'Emotion Check',
    };
    return names[type] ?? type;
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatKey(String key) {
    return key.replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final String riskFlag;
  const _RiskBadge({required this.riskFlag});

  @override
  Widget build(BuildContext context) {
    final color = switch (riskFlag) {
      'high'   => Colors.red,
      'medium' => Colors.orange,
      'low'    => Colors.green,
      _        => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        riskFlag.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
