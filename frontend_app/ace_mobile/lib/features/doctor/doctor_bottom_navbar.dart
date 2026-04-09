import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/AI_Chat_Assistant/aiChatScreen.dart';
import 'package:ace_mobile/features/doctor/screens/doctor_dashboard_screen.dart';
import 'package:ace_mobile/features/doctor/screens/doctor_patients_screen.dart';
import 'package:ace_mobile/features/doctor/screens/doctor_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class DoctorBottomNavBar extends StatefulWidget {
  const DoctorBottomNavBar({super.key});

  @override
  State<DoctorBottomNavBar> createState() => DoctorBottomNavBarState();
}

class DoctorBottomNavBarState extends State<DoctorBottomNavBar> {
  late PersistentTabController _controller;
  int _currentIndex = 0;

  /// Programmatically switch to a specific tab index.
  void switchToTab(int index) {
    _controller.jumpToTab(index);
  }

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
    _controller.addListener(() {
      if (_controller.index != _currentIndex) {
        setState(() => _currentIndex = _controller.index);
      }
    });
  }

  /// Chat FAB is shown on Dashboard (0) and Patients (1) tabs only.
  bool get _shouldShowChatFab => _currentIndex == 0 || _currentIndex == 1;

  List<Widget> _buildScreens() {
    return const [
      DoctorDashboardScreen(),
      DoctorPatientsScreen(),
      DoctorProfileScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.dashboard_rounded),
        title: "Dashboard",
        activeColorPrimary: appColors.primary,
        inactiveColorPrimary: textColors.secondary.withValues(alpha: 0.8),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.people_rounded),
        title: "Patients",
        activeColorPrimary: appColors.primary,
        inactiveColorPrimary: textColors.secondary.withValues(alpha: 0.8),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person_rounded),
        title: "Profile",
        activeColorPrimary: appColors.primary,
        inactiveColorPrimary: textColors.secondary.withValues(alpha: 0.8),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Chat FAB — only on Dashboard and Patients tabs, hidden when keyboard open
      floatingActionButton: _shouldShowChatFab
          ? Builder(builder: (context) {
              final isKeyboardOpen =
                  MediaQuery.of(context).viewInsets.bottom > 0;
              if (isKeyboardOpen) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: FloatingActionButton(
                  elevation: 5,
                  backgroundColor: appColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AIChatScreen()),
                    );
                  },
                  child: const Icon(Icons.chat_bubble_outlined),
                ),
              );
            })
          : null,
      body: PersistentTabView(
        context,
        controller: _controller,
        screens: _buildScreens(),
        items: _navBarsItems(),
        decoration: NavBarDecoration(
          border: Border.all(
            color: textColors.secondary.withValues(alpha: 0.5),
            width: 0.1,
          ),
          boxShadow: [
            BoxShadow(
              color: appColors.primary.withValues(alpha: 0.1),
              offset: const Offset(0, 0),
              blurStyle: BlurStyle.outer,
            ),
          ],
        ),
        handleAndroidBackButtonPress: true,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        hideNavigationBarWhenKeyboardAppears: true,
        animationSettings: const NavBarAnimationSettings(
          navBarItemAnimation: ItemAnimationSettings(
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          ),
          screenTransitionAnimation: ScreenTransitionAnimationSettings(
            animateTabTransition: true,
            duration: Duration(milliseconds: 300),
            screenTransitionAnimationType: ScreenTransitionAnimationType.slide,
          ),
        ),
        confineToSafeArea: true,
        navBarHeight: 60,
        padding: const EdgeInsets.all(4),
        backgroundColor: Colors.white,
        navBarStyle: NavBarStyle.style14,
      ),
    );
  }
}
