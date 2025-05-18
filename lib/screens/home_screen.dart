import 'package:flutter/material.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openAddTransactionScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Тип'),
                    items: const [
                      DropdownMenuItem(value: 'все', child: Text('Все')),
                      DropdownMenuItem(value: 'доход', child: Text('Доход')),
                      DropdownMenuItem(value: 'расход', child: Text('Расход')),
                    ],
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Период'),
                    items: const [
                      DropdownMenuItem(value: 'месяц', child: Text('Месяц')),
                      DropdownMenuItem(value: 'неделя', child: Text('Неделя')),
                      DropdownMenuItem(value: 'всё', child: Text('Всё время')),
                    ],
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.arrow_upward, color: Colors.red),
                    title: Text('Продукты'),
                    subtitle: Text('12 мая 2025'),
                    trailing: Text('-650 ₽'),
                  ),
                  ListTile(
                    leading: Icon(Icons.arrow_downward, color: Colors.green),
                    title: Text('Зарплата'),
                    subtitle: Text('10 мая 2025'),
                    trailing: Text('+15000 ₽'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTransactionScreen(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
