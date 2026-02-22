import 'package:ace_mobile/core/constants.dart';
import 'package:ace_mobile/features/AI_Chat_Assistant/aiChatScreen.dart';
import 'package:ace_mobile/features/HomeScreen.dart';
import 'package:ace_mobile/features/community/community.dart';
import 'package:ace_mobile/features/Therapy/therapyScreen.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  List<Widget> _buildScreens() {
    return const [
      homeScreen(),
      TherapyScreen(),
      Center(child: Text("Assessment")),
      CommunityPage(),
    ];
  }

  // Navbar Item
  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: "Home",
        activeColorPrimary: appColors.primary,
        inactiveColorPrimary: textColors.secondary.withValues(alpha: 0.8),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.medical_services),
        title: "Therapy",
        activeColorPrimary: appColors.primary,
        inactiveColorPrimary: textColors.secondary.withValues(alpha: 0.8),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person),
        title: "Assessment",
        activeColorPrimary: appColors.primary,
        inactiveColorPrimary: textColors.secondary.withValues(alpha: 0.8),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.people),
        title: "Community",
        activeColorPrimary: appColors.primary,
        inactiveColorPrimary: textColors.secondary.withValues(alpha: 0.8),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //app copilot
      floatingActionButton: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AIChatScreen()),
          );
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 60),
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: appColors.primary,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.chat_bubble_outlined,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
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
              offset: Offset(0, 0),
              blurStyle: BlurStyle.outer,
            ),
          ],
        ),
        handleAndroidBackButtonPress: true,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        hideNavigationBarWhenKeyboardAppears: true,

        //Animations
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

        padding: EdgeInsets.all(4),

        backgroundColor: Colors.white,
        navBarStyle: NavBarStyle.style14,
      ),
    );
  }
}
