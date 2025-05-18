import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const FinliteApp());
}

class FinliteApp extends StatelessWidget {
  const FinliteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finlite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    HomeScreen(),
    CategoriesScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.category), label: 'Категории'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Отчёты'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}
