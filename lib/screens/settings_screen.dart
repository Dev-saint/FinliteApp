import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        child: ListView(
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
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Вывести транзакции в консоль'),
              onTap: () async {
                await DatabaseService.printAllTransactions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Транзакции выведены в консоль'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
