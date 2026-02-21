import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/shared/ProgressCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class homeScreen extends StatefulWidget {
  const homeScreen({super.key});

  @override
  State<homeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<homeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                //top
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          "assets/images/poster.png",
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CARING FOR",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.6),
                              ),
                        ),

                        Text(
                          "Diago",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.6),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
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
                SizedBox(height: 40),
                //salutation
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Good Morning,",
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.black),
                        ),
                        Text(
                          "Sarah",
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Spacer(),
                  ],
                ),
                SizedBox(height: 20),
                //status card
                statusCard(),
                const SizedBox(height: 20),
                //Scrollable cards
                SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      DiagnosisCard(
                        title: "Speech\nDelay",
                        icon: Icons.record_voice_over,
                      ),
                      DiagnosisCard(
                        title: "Eye\nContact",
                        icon: Icons.visibility,
                      ),
                      DiagnosisCard(title: "Sensory", icon: Icons.sensors),
                      DiagnosisCard(
                        title: "Social\nSkills",
                        icon: Icons.people,
                      ),
                      DiagnosisCard(title: "Behavior", icon: Icons.psychology),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                ProgressGraphCard(),
                SizedBox(height: 20),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    " Recent Clinical Notes",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textColors.secondary,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                //clinical note container
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            "Dr. Adarsh Sen",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Spacer(),
                          Text(
                            "Feb 20, 2026",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: textColors.secondary.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Container(
                        child: Text(
                          softWrap: true,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          "Showing great progress in assessments , 30% improvement in eye contact , next Screening due in 12 days",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: textColors.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//status card
class statusCard extends StatefulWidget {
  const statusCard({super.key});

  @override
  State<statusCard> createState() => _statusCardState();
}

class _statusCardState extends State<statusCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Summary",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColors.secondary.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    "Great!!",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: appColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Moderate Risk",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          //status
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  softWrap: true,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  "Showing great progress in assessments , 30% improvement in eye contact , next Screening due in 12 days",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: textColors.secondary),
                ),
              ),
              SizedBox(width: 20),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: appColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: appColors.primary.withValues(alpha: 0.3),
                      blurRadius: 3,
                      spreadRadius: 2,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_forward_ios_sharp, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DiagnosisCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const DiagnosisCard({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: appColors.background,

              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, size: 28, color: appColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}
