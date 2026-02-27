import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

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
                // ── Top bar ──
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: appColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFE0F2FE),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CLINICIAN',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            letterSpacing: 1.0,
                            color: appColors.primary.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Dr. Sarah Jenkins',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: appColors.primary.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(
                        Icons.notifications,
                        color: appColors.primary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Greeting ──
                Text(
                  _greeting(),
                  style: GoogleFonts.poppins(fontSize: 24, color: Colors.black),
                ),
                Text(
                  'Dr. Sarah',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: appColors.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Stats Row ──
                Row(
                  children: [
                    _StatCard(
                      value: '42',
                      label: 'Patients',
                      icon: Icons.people_rounded,
                      color: const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      value: '4.9',
                      label: 'Rating',
                      icon: Icons.star_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      value: '15',
                      label: 'Exp. Years',
                      icon: Icons.workspace_premium_rounded,
                      color: const Color(0xFF7C3AED),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Quick Actions ──
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColors.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      _QuickActionCard(
                        icon: Icons.person_add_rounded,
                        label: 'New Patient',
                        color: Color(0xFF059669),
                      ),
                      _QuickActionCard(
                        icon: Icons.assignment_add,
                        label: 'New Plan',
                        color: Color(0xFF0284C7),
                      ),
                      _QuickActionCard(
                        icon: Icons.schedule_rounded,
                        label: 'Schedule',
                        color: Color(0xFF7C3AED),
                      ),
                      _QuickActionCard(
                        icon: Icons.assessment_rounded,
                        label: 'Reports',
                        color: Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Today's Schedule ──
                Row(
                  children: [
                    Text(
                      "Today's Schedule",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColors.secondary,
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

                _AppointmentCard(
                  name: 'Liam Johnson',
                  type: 'Therapy Session',
                  time: '10:00 AM',
                  status: 'Upcoming',
                  statusColor: const Color(0xFF0284C7),
                ),
                const SizedBox(height: 10),
                _AppointmentCard(
                  name: 'Emma Wilson',
                  type: 'Progress Review',
                  time: '11:30 AM',
                  status: 'In Progress',
                  statusColor: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 10),
                _AppointmentCard(
                  name: 'Noah Davis',
                  type: 'Initial Assessment',
                  time: '2:00 PM',
                  status: 'Upcoming',
                  statusColor: const Color(0xFF0284C7),
                ),
                const SizedBox(height: 24),

                // ── Recent Activity ──
                Text(
                  'Recent Activity',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColors.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                _ActivityTile(
                  icon: Icons.edit_note_rounded,
                  text: 'Updated therapy plan for Liam Johnson',
                  time: '2 hours ago',
                ),
                _ActivityTile(
                  icon: Icons.assessment_rounded,
                  text: 'Completed assessment for Emma Wilson',
                  time: '5 hours ago',
                ),
                _ActivityTile(
                  icon: Icons.message_rounded,
                  text: 'New message from Noah\'s parent',
                  time: 'Yesterday',
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

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
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
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action Card ─────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Appointment Card ──────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final String name;
  final String type;
  final String time;
  final String status;
  final Color statusColor;

  const _AppointmentCard({
    required this.name,
    required this.type,
    required this.time,
    required this.status,
    required this.statusColor,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.person, size: 24, color: appColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  '$type • $time',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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

// ── Activity Tile ─────────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final String time;

  const _ActivityTile({
    required this.icon,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: appColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: appColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF374151),
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
