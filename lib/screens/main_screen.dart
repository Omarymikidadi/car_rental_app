import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';
import 'cars_screen.dart';
import 'notifications_screen.dart';
import 'driver/driver_main_screen.dart';
import 'admin/admin_main_screen.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Ikiwa bado tunapakia taarifa, onyesha loading spinner
    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF1D275F)),
              SizedBox(height: 20),
              Text("Inapakia taarifa...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // DASHBOARD ROUTING KULINGANA NA ROLE
    if (userProvider.role == 'admin') {
      return const AdminMainScreen();
    } else if (userProvider.role == 'driver') {
      return const DriverMainScreen();
    }

    // DEFAULT: CUSTOMER UI
    return _buildCustomerUI(context);
  }

  Widget _buildCustomerUI(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);
    
    final List<Widget> screens = [
      const HomeScreen(),
      const CarsScreen(type: 'all'),
      const MyBookingsScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: theme.brightness == Brightness.dark ? Colors.blueAccent : const Color(0xFF003399),
        unselectedItemColor: Colors.grey,
        backgroundColor: theme.cardColor,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_filled), label: lang.translate('Home', 'Mwanzo')),
          BottomNavigationBarItem(icon: const Icon(Icons.directions_car_filled), label: lang.translate('Cars', 'Magari')),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_month), label: lang.translate('Bookings', 'Safari')),
          BottomNavigationBarItem(icon: const Icon(Icons.notifications), label: lang.translate('Notifications', 'Taarifa')),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: lang.translate('Profile', 'Mimi')),
        ],
      ),
    );
  }
}
