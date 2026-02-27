import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/doctor/screens/doctor_therapy_plan_screen.dart';
import 'package:ace_mobile/features/doctor/screens/doctor_progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared patient data model used across doctor screens.
class PatientData {
  final String name;
  final int age;
  final String diagnosis;
  final String lastVisit;
  final String status;
  final String since;

  const PatientData({
    required this.name,
    required this.age,
    required this.diagnosis,
    required this.lastVisit,
    required this.status,
    required this.since,
  });
}

class PatientDetailScreen extends StatelessWidget {
  final PatientData patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final isActive = patient.status == 'Active';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                const SizedBox(height: 24),

                // ── Patient Header ──
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFE8F4F0)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive
                                ? appColors.primary.withValues(alpha: 0.3)
                                : Colors.grey.shade300,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            patient.name.split(' ').map((n) => n[0]).join(),
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isActive ? appColors.primary : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        patient.name,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF059669).withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          patient.status,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? const Color(0xFF059669)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Info Cards ──
                Row(
                  children: [
                    _InfoCard(
                      icon: Icons.cake_rounded,
                      label: 'Age',
                      value: '${patient.age} years',
                      color: const Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 12),
                    _InfoCard(
                      icon: Icons.medical_information_rounded,
                      label: 'Diagnosis',
                      value: patient.diagnosis,
                      color: const Color(0xFF0284C7),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoCard(
                      icon: Icons.calendar_today_rounded,
                      label: 'Last Visit',
                      value: patient.lastVisit,
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 12),
                    _InfoCard(
                      icon: Icons.access_time_rounded,
                      label: 'Since',
                      value: patient.since,
                      color: const Color(0xFF059669),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Action Buttons ──
                Text(
                  'Patient Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),

                // Therapy Plan button
                _ActionButton(
                  icon: Icons.assignment_rounded,
                  title: 'Therapy Plan',
                  subtitle: 'View and manage assigned games & difficulty',
                  color: const Color(0xFF0284C7),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DoctorTherapyPlanScreen(patient: patient),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Progress button
                _ActionButton(
                  icon: Icons.insights_rounded,
                  title: 'Developmental Progress',
                  subtitle: 'Score trends, milestones & regression alerts',
                  color: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorProgressScreen(patient: patient),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Notes button (placeholder)
                _ActionButton(
                  icon: Icons.note_alt_rounded,
                  title: 'Clinical Notes',
                  subtitle: 'Add or review session notes',
                  color: const Color(0xFFF59E0B),
                  onTap: () {},
                ),
                const SizedBox(height: 12),

                // Contact parent button (placeholder)
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Contact Parent',
                  subtitle: 'Send a message to the parent',
                  color: const Color(0xFF059669),
                  onTap: () {},
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

// ── Info Card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
