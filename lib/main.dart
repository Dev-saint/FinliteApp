import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Убедились, что импорт корректен
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'theme/theme_provider.dart';
import 'theme/app_themes.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/database_service.dart';
import 'package:logging/logging.dart';

void main() async {
  // Настройка логгера
  Logger.root.level = Level.ALL; // Уровень логов, которые ты хочешь видеть
  Logger.root.onRecord.listen((record) {
    // Вывод логов в консоль
    print(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
  });

  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null); // Инициализация локали

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create:
              (_) => ThemeProvider(), // Убедились, что ThemeProvider передается
        ),
      ],
      child: Builder(
        // Оборачиваем FinliteApp в Builder
        builder: (context) => const FinliteApp(),
      ),
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
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ], // Убрано const, так как список содержит не константы
      supportedLocales: const [
        Locale('ru', 'RU'), // Русская локализация
        Locale('en', 'US'), // Английская локализация
      ],
      home: const MainNavigation(),
    );
  }
}

// Добавлено: глобальная функция для обновления транзакций
final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

void updateHomeScreenTransactions() {
  homeScreenKey.currentState?.updateTransactions();
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(key: homeScreenKey), // Главная
    const CategoriesScreen(), // Категории
    const ReportsScreen(), // Отчёты
    const SettingsScreen(), // Настройки
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
                const AddTransactionScreen(), // Убедились, что AddTransactionScreen доступен
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
    // После сохранения возвращаемся на главный экран
    if (result == true) {
      updateHomeScreenTransactions(); // Вызываем глобальный метод обновления
      setState(() {
        _selectedIndex = 0; // Возвращаемся на главный экран
      });
    }
  }

  Future<void> _clearDatabase() async {
    await DatabaseService.clearTransactions();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('База данных очищена от транзакций')),
    );
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
      body: IndexedStack(
        index: _selectedIndex,
        children:
            _screens, // Используем IndexedStack для сохранения состояния экранов
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            // Центральная кнопка "+" открывает AddTransactionScreen
            _openAddTransactionScreen(context);
          } else {
            _onItemTapped(index < 2 ? index : index - 1); // Корректируем индекс
          }
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home), label: 'Главная'),
          const NavigationDestination(
            icon: Icon(Icons.category),
            label: 'Категории',
          ),
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
