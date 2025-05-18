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
      body: ListView(
        padding: const EdgeInsets.all(16),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTransactionScreen(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
