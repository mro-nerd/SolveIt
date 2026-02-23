import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';
import '../data/models/mchat_question.dart';

/// Displays a single M-CHAT-R question with category badge and example text.
class QuestionCard extends StatelessWidget {
  final MchatQuestion question;

  const QuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: appColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge
          _CategoryBadge(category: question.category),
          const SizedBox(height: 20),

          // Question text
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B3C),
              height: 1.45,
            ),
          ),

          // Example text
          if (question.examples.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ExampleBox(text: question.examples),
          ],
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  static const _labels = <String, String>{
    'joint_attention': 'Joint Attention',
    'hearing_response': 'Hearing Response',
    'pretend_play': 'Pretend Play',
    'motor_activity': 'Motor Activity',
    'repetitive_behavior': 'Repetitive Behavior',
    'communication_request': 'Communication',
    'social_interest': 'Social Interest',
    'social_sharing': 'Social Sharing',
    'name_response': 'Name Response',
    'social_reciprocity': 'Social Reciprocity',
    'sensory_sensitivity': 'Sensory Sensitivity',
    'motor_development': 'Motor Development',
    'eye_contact': 'Eye Contact',
    'imitation': 'Imitation',
    'attention_sharing': 'Attention Sharing',
    'language_comprehension': 'Language Comprehension',
    'social_reference': 'Social Reference',
    'sensory_seeking': 'Sensory Seeking',
  };

  static const _colors = <String, Color>{
    'joint_attention': Color(0xFF3B82F6),
    'hearing_response': Color(0xFFF59E0B),
    'pretend_play': Color(0xFF8B5CF6),
    'motor_activity': Color(0xFF10B981),
    'repetitive_behavior': Color(0xFFEF4444),
    'communication_request': Color(0xFF06B6D4),
    'social_interest': Color(0xFF6366F1),
    'social_sharing': Color(0xFFF97316),
    'name_response': Color(0xFF14B8A6),
    'social_reciprocity': Color(0xFFEC4899),
    'sensory_sensitivity': Color(0xFFEF4444),
    'motor_development': Color(0xFF84CC16),
    'eye_contact': Color(0xFF0EA5E9),
    'imitation': Color(0xFFA855F7),
    'attention_sharing': Color(0xFF6366F1),
    'language_comprehension': Color(0xFF22C55E),
    'social_reference': Color(0xFFE879F9),
    'sensory_seeking': Color(0xFF3B82F6),
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[category] ?? category;
    final color = _colors[category] ?? appColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleBox extends StatelessWidget {
  final String text;
  const _ExampleBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: appColors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: appColors.secondary.withValues(alpha: 0.85),
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
