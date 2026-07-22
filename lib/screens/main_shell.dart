import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/lilypad_app_bar.dart';
import 'dashboard_screen.dart';
import 'weather_screen.dart';
import 'calendar_screen.dart';
import 'lily_chat_screen.dart';
import 'finance_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 2; // Start on Home/Dashboard

  // _screens list is now generated dynamically in the build method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const LilypadAppBar(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const WeatherScreen(),
                const CalendarScreen(),
                DashboardScreen(
                  onNavigateToFinance: () {
                    setState(() {
                      _currentIndex = 4;
                    });
                  },
                ),
                const LilyChatScreen(),
                const FinanceScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: LilypadBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
