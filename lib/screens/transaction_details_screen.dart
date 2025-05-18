import 'package:flutter/material.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color color;
  final String category;
  final String comment;

  const TransactionDetailsScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    required this.category,
    required this.comment,
  });

  // Локальная функция для получения иконки по категории
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

  @override
  Widget build(BuildContext context) {
    // Используем иконку по категории
    final categoryIcon = _getCategoryIcon(category);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget iconWidget = Icon(categoryIcon, color: color, size: 48);
    return Scaffold(
      appBar: AppBar(title: const Text('Детали операции')),
      body: Material(
        color: colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(height: 24),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Категория: $category',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? colorScheme.surfaceContainerLow
                          : colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isDark
                            ? colorScheme.primary.withOpacity(0.25)
                            : Colors.blueAccent.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Комментарий',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comment.isNotEmpty ? comment : 'Нет комментария',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Назад'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
