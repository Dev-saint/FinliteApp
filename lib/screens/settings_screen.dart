import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDarkTheme = false; // пока не подключено

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Тёмная тема'),
            value: isDarkTheme,
            onChanged: (_) {
              // TODO: переключение темы
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Функция в разработке')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Экспорт данных'),
            onTap: () {
              // TODO: экспорт
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Экспорт ещё не реализован')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Создать резервную копию'),
            onTap: () {
              // TODO: резервное копирование
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Копирование ещё не реализовано')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Восстановить из копии'),
            onTap: () {
              // TODO: восстановление
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Восстановление ещё не реализовано')),
              );
            },
          ),
        ],
      ),
    );
  }
}
