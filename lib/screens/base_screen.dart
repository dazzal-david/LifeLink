import 'package:flutter/material.dart';
import 'package:elderly_care/widgets/bottom_nav_bar.dart';
import 'package:elderly_care/screens/dashboard/dashboard_screen.dart';
import 'package:elderly_care/screens/ai_doctor/ai_doctor_screen.dart';
import 'package:elderly_care/screens/connect/connect_screen.dart';
import 'package:elderly_care/screens/profile/profile_screen.dart';

class BaseScreen extends StatefulWidget {
  final int initialIndex;

  const BaseScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const DashboardScreen(),
    const AIDoctorScreen(),
    const ConnectScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}