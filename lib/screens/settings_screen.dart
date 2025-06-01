import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(
      context,
    ); // Убедились, что ThemeProvider доступен

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: SingleChildScrollView(
        // Добавлен для предотвращения переполнения
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: ListView(
            shrinkWrap: true, // Установлено для предотвращения переполнения
            children: [
              SwitchListTile(
                title: const Text('Тёмная тема'),
                value: themeProvider.isDark,
                onChanged: (value) => themeProvider.toggleTheme(value),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Экспорт данных'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Экспорт ещё не реализован')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Создать резервную копию'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Копирование ещё не реализовано'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Восстановить из копии'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Восстановление ещё не реализовано'),
                    ),
                  );
                },
              ),
              const Divider(),
            ],
          ),
        ),
      ),
    );
  }
}
