import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_home_screen.dart';
import '../my_bookings_screen.dart';
import 'users_management_screen.dart';
import '../profile_screen.dart';
import '../../providers/language_provider.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminHomeScreen(),
    const MyBookingsScreen(),
    const UsersManagementScreen(), // Imebadilishwa kutoka CarsScreen kwenda UsersManagement
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF1D275F),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_customize_outlined),
            label: lang.translate('Dashboard', 'Panel'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics_outlined),
            label: lang.translate('Bookings', 'Safari'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.manage_accounts_outlined),
            label: lang.translate('Users', 'Watumiaji'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: lang.translate('Account', 'Akaunti'),
          ),
        ],
      ),
    );
  }
}
