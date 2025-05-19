import 'package:flutter/material.dart';
import 'transaction_details_screen.dart';
import 'edit_account_screen.dart';
import '../models/account.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Пример счетов
  List<Account> accounts = [
    Account(name: 'Основной', balance: 14350),
    Account(name: 'Карта', balance: 5000),
  ];
  int selectedAccountIndex = 0;

  // Пример транзакций
  final List<_TransactionData> transactions = [
    _TransactionData(
      category: 'Продукты',
      title: 'Продукты',
      subtitle: '12 мая 2025, 14:30',
      amount: -650,
      color: Colors.redAccent,
      comment: 'Покупка в супермаркете',
    ),
    _TransactionData(
      category: 'Зарплата',
      title: 'Зарплата',
      subtitle: '10 мая 2025, 09:00',
      amount: 15000,
      color: Colors.green,
      comment: 'Майская зарплата',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final data = await DatabaseService.getAllTransactions();
    setState(() {
      transactions.clear();
      transactions.addAll(
        data.map(
          (t) => _TransactionData(
            category: t['category'],
            title: t['title'] ?? 'Без названия',
            subtitle: t['date'],
            amount: t['amount'],
            color: t['amount'] > 0 ? Colors.green : Colors.redAccent,
            comment: t['comment'] ?? '',
          ),
        ),
      );
    });
  }

  // Получить иконку по категории
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

  void _openEditAccountScreen(
    BuildContext context,
    Account account,
    int index,
  ) async {
    final result = await Navigator.of(context).push<Account>(
      _fadeRoute<Account>(
        EditAccountScreen(
          initialName: account.name,
          initialBalance: account.balance,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        accounts[index] = result;
      });
    }
  }

  void _openAddAccountScreen(BuildContext context) async {
    final result = await Navigator.of(
      context,
    ).push<Account>(_fadeRoute<Account>(EditAccountScreen()));
    if (result != null) {
      setState(() {
        accounts.add(result);
        selectedAccountIndex = accounts.length - 1;
      });
    }
  }

  // Универсальный fade route
  PageRouteBuilder<T> _fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder:
          (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 220),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Сводка по транзакциям
    final total = transactions.fold<int>(0, (sum, t) => sum + t.amount);
    final income = transactions
        .where((t) => t.amount > 0)
        .fold<int>(0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.amount < 0)
        .fold<int>(0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // --- Баланс и выбор счета ---
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedAccountIndex,
                      decoration: const InputDecoration(
                        labelText: 'Счёт',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: List.generate(
                        accounts.length,
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Row(
                            children: [
                              Text(accounts[i].name),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap:
                                    () => _openEditAccountScreen(
                                      context,
                                      accounts[i],
                                      i,
                                    ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      onChanged: (i) {
                        if (i != null) setState(() => selectedAccountIndex = i);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _openAddAccountScreen(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить счёт'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // --- Баланс выбранного счета ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withAlpha((0.07 * 255).round()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Баланс', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      '${accounts[selectedAccountIndex].balance} ₽',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // --- Фильтры ---
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
              // --- Список транзакций ---
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(
                    bottom: 90,
                  ), // чтобы не перекрывать итогами
                  children:
                      transactions
                          .map(
                            (t) => TransactionCard(
                              category: t.category,
                              title: t.title,
                              subtitle: t.subtitle,
                              amount: '${t.amount > 0 ? '+' : ''}${t.amount} ₽',
                              color: t.color,
                              comment: t.comment,
                              onTap:
                                  (context, card) =>
                                      _openTransactionDetailsScreen(
                                        context,
                                        card,
                                      ),
                              getCategoryIcon: _getCategoryIcon,
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      // Итоги внизу экрана, поверх body
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Итоги внизу экрана, поверх body
          Positioned(
            right: 0,
            left: 0,
            bottom: 0,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha((0.08 * 255).round()),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SummaryColumn(
                      title: 'Итого',
                      value: '$total ₽',
                      valueColor: total >= 0 ? Colors.green : Colors.redAccent,
                    ),
                    _SummaryDivider(),
                    _SummaryColumn(
                      title: 'Доходы',
                      value: '+$income ₽',
                      valueColor: Colors.green,
                    ),
                    _SummaryDivider(),
                    _SummaryColumn(
                      title: 'Расходы',
                      value: '$expense ₽',
                      valueColor: Colors.redAccent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Пример модели транзакции ---
class _TransactionData {
  final String category;
  final String title;
  final String subtitle;
  final int amount;
  final Color color;
  final String comment;
  _TransactionData({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    required this.comment,
  });
}

// Обновлённый TransactionCard
class TransactionCard extends StatelessWidget {
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

class _SummaryColumn extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  const _SummaryColumn({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: valueColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 1.2,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Theme.of(context).dividerColor.withAlpha((0.25 * 255).round()),
    );
  }
}
