import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'theme/theme_provider.dart';
import 'theme/app_themes.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const FinliteApp(),
    ),
  );
}

class FinliteApp extends StatelessWidget {
  const FinliteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Finlite',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.currentTheme,
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

  // Добавлено: открыть экран добавления транзакции с fade-анимацией
  Future<void> _openAddTransactionScreen(BuildContext context) async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const AddTransactionScreen(),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
    // После сохранения возвращаемся на главный экран
    if (result == true) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  PageTransitionSwitcherTransitionBuilder _getTransitionBuilder(int index) {
    return (child, animation, secondaryAnimation) =>
        FadeTransition(opacity: animation, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final navColor = Theme.of(context).colorScheme.primary;
    final navFg = Theme.of(context).colorScheme.onPrimary;
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        reverse: false,
        transitionBuilder: _getTransitionBuilder(_selectedIndex),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex > 1 ? _selectedIndex + 1 : _selectedIndex,
        onDestinationSelected: (index) {
          // Если нажали на центральную кнопку (+), открываем AddTransactionScreen
          if (index == 2) {
            _openAddTransactionScreen(context);
          } else {
            // Корректируем индекс, чтобы пропустить центральную кнопку
            _onItemTapped(index > 2 ? index - 1 : index);
          }
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home), label: 'Главная'),
          const NavigationDestination(
            icon: Icon(Icons.category),
            label: 'Категории',
          ),
          // Центральная кнопка "+" (без label)
          NavigationDestination(
            icon: Container(
              decoration: BoxDecoration(
                color: navColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: navColor.withAlpha((0.18 * 255).round()),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.add, color: navFg, size: 28),
            ),
            label: '',
          ),
          const NavigationDestination(
            icon: Icon(Icons.pie_chart),
            label: 'Отчёты',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
