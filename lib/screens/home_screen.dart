import 'package:flutter/material.dart';
import 'add_transaction_screen.dart';
import 'transaction_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Добавлено: функция для получения иконки по категории
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Продукты':
        return Icons.shopping_cart;
      case 'Транспорт':
        return Icons.directions_car;
      case 'Развлечения':
        return Icons.movie;
      case 'Зарплата':
        return Icons.attach_money;
      default:
        return Icons.label;
    }
  }

  void _openAddTransactionScreen(BuildContext context) {
    Navigator.of(context).push(_fadeRoute(const AddTransactionScreen()));
  }

  void _openTransactionDetailsScreen(
    BuildContext context,
    TransactionCard card,
  ) {
    Navigator.of(context).push(
      _fadeRoute(
        TransactionDetailsScreen(
          icon: _getCategoryIcon(card.category),
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

  // Добавлено: универсальный fade route
  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder:
          (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 220),
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
                      // icon теперь не нужен, вычисляется внутри TransactionCard
                      category: 'Продукты',
                      title: 'Продукты',
                      subtitle: '12 мая 2025, 14:30',
                      amount: '-650 ₽',
                      color: Colors.redAccent,
                      comment: 'Покупка в супермаркете',
                      onTap:
                          (context, card) =>
                              _openTransactionDetailsScreen(context, card),
                      getCategoryIcon: _getCategoryIcon, // передаём функцию
                    ),
                    TransactionCard(
                      category: 'Зарплата',
                      title: 'Зарплата',
                      subtitle: '10 мая 2025, 09:00',
                      amount: '+15000 ₽',
                      color: Colors.green,
                      comment: 'Майская зарплата',
                      onTap:
                          (context, card) =>
                              _openTransactionDetailsScreen(context, card),
                      getCategoryIcon: _getCategoryIcon,
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

// Обновлённый TransactionCard
class TransactionCard extends StatelessWidget {
  // icon убран, добавлена функция для получения иконки
  final String category;
  final String title;
  final String subtitle;
  final String amount;
  final Color color;
  final String comment;
  final void Function(BuildContext, TransactionCard)? onTap;
  final IconData Function(String)? getCategoryIcon;

  const TransactionCard({
    super.key,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    required this.comment,
    this.onTap,
    this.getCategoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Используем иконку по категории
    final icon =
        getCategoryIcon != null ? getCategoryIcon!(category) : Icons.label;
    Widget leadingIcon = Icon(icon, color: color);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: leadingIcon,
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
