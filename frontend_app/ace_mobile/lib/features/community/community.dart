import 'package:ace_mobile/core/constants.dart';
import 'package:flutter/material.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColors.background,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildSectionHeader(context, "Your Groups", showSeeAll: true),
              const SizedBox(height: 12),
              _buildGroupList(),
              const SizedBox(height: 24),
              _buildSectionHeader(context, "Latest Activity"),
              const SizedBox(height: 12),
              _buildActivityList(context),
              const SizedBox(height: 80), // Space for FAB and navbar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.menu, color: appColors.primary),
          ),
          Text(
            "ACE Community",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: appColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_outlined, color: appColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    bool showSeeAll = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: appColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showSeeAll)
            Text(
              "See All",
              style: TextStyle(
                color: appColors.primary.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupList() {
    final groups = [
      {
        'title': 'Toddlers 2-4',
        'members': '1.2k members',
        'image':
            'https://img.freepik.com/free-photo/medium-shot-kids-playing-together_23-2149035912.jpg',
      },
      {
        'title': 'New York Chapter',
        'members': '850 members',
        'image':
            'https://img.freepik.com/free-photo/new-york-city-skyline-daytime_23-2149139825.jpg',
      },
    ];

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    group['image']!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['title']!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group['members']!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColors.secondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityList(BuildContext context) {
    final posts = [
      {
        'user': 'Sarah Miller',
        'location': 'Brooklyn, NY',
        'time': '2 HOURS AGO',
        'tag': 'Celebrate',
        'tagColor': appColors.green,
        'content':
            '"My son made eye contact today during play for nearly 10 seconds! This is such a huge milestone for us. Feeling so grateful today."',
        'likes': '48',
        'comments': '12',
        'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
      },
      {
        'user': 'David Chen',
        'location': 'Queens, NY',
        'time': '5 HOURS AGO',
        'tag': 'Question',
        'tagColor': const Color(0xFFF9A825),
        'content':
            '"Any recommendations for sensory-friendly parks in Brooklyn? Looking for somewhere quiet with soft flooring for our weekend outing."',
        'likes': '24',
        'comments': '31',
        'avatar': 'https://randomuser.me/api/portraits/men/32.jpg',
      },
      {
        'user': 'Elena Rodriguez',
        'location': 'Manhattan, NY',
        'time': 'YESTERDAY',
        'tag': 'Resource',
        'tagColor': appColors.primary,
        'content':
            'Found a great occupational therapist who specializes in picky eaters. DM me if you\'re in the city and want their info!',
        'likes': '56',
        'comments': '8',
        'avatar': 'https://randomuser.me/api/portraits/women/65.jpg',
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final tagColor = post['tagColor'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(post['avatar'] as String),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['user'] as String,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${post['time']} • ${post['location']}",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: textColors.secondary.withValues(
                                  alpha: 0.6,
                                ),
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.more_horiz,
                    color: textColors.secondary.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post['tag'] as String,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tagColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                post['content'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: textColors.secondary.withValues(alpha: 0.05),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.favorite, color: appColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    post['likes'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(
                    Icons.chat_bubble_outline,
                    color: textColors.secondary.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    post['comments'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.share_outlined,
                    color: textColors.secondary.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
