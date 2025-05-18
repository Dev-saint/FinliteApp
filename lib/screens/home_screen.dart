import 'package:flutter/material.dart';
import 'add_transaction_screen.dart';
import 'transaction_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openAddTransactionScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  }

  void _openTransactionDetailsScreen(
    BuildContext context,
    TransactionCard card,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => TransactionDetailsScreen(
              icon: card.icon,
              title: card.title,
              subtitle: card.subtitle,
              amount: card.amount,
              color: card.color,
              category: card.category,
              comment: card.comment,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
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
                        DropdownMenuItem(
                          value: 'расход',
                          child: Text('Расход'),
                        ),
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
                        DropdownMenuItem(
                          value: 'неделя',
                          child: Text('Неделя'),
                        ),
                        DropdownMenuItem(
                          value: 'всё',
                          child: Text('Всё время'),
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    TransactionCard(
                      icon: Icons.arrow_upward,
                      title: 'Продукты',
                      subtitle: '12 мая 2025, 14:30',
                      amount: '-650 ₽',
                      color: Colors.redAccent,
                      category: 'Продукты',
                      comment: 'Покупка в супермаркете',
                      onTap:
                          (context, card) =>
                              _openTransactionDetailsScreen(context, card),
                    ),
                    TransactionCard(
                      icon: Icons.arrow_downward,
                      title: 'Зарплата',
                      subtitle: '10 мая 2025, 09:00',
                      amount: '+15000 ₽',
                      color: Colors.green,
                      category: 'Зарплата',
                      comment: 'Майская зарплата',
                      onTap:
                          (context, card) =>
                              _openTransactionDetailsScreen(context, card),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTransactionScreen(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TransactionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle; // теперь дата и время в одной строке
  final String amount;
  final Color color;
  final String category;
  final String comment;
  final void Function(BuildContext, TransactionCard)? onTap;

  const TransactionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    required this.category,
    required this.comment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        onTap: onTap != null ? () => onTap!(context, this) : null,
      ),
    );
  }
}
