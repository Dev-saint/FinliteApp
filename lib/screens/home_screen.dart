import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction_details_screen.dart';
import '../models/account.dart' as model_account;
import '../services/database_service.dart';
import 'edit_account_screen.dart'; // Добавлен импорт
import 'dart:io'; // Импортируем dart:io для работы с файлами

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return buildTransactionSummary(
      context,
    ); // Заменяем статический виджет на вызов метода
  }

  List<model_account.Account> accounts = [];
  int selectedAccountIndex = 0;
  int? selectedAccountId; // Добавлено: ID выбранного счета (null для "Все")

  // Удален список примеров транзакций
  final List<TransactionData> transactions = [];

  String? selectedCategoryFilter;
  String selectedPeriodFilter = 'Все'; // По умолчанию показываем все периоды
  DateTimeRange? customDateRange; // Для произвольного периода

  List<Map<String, dynamic>> categories = []; // Список категорий из базы данных

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadCategories(); // Загружаем категории из базы данных
    _loadTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions(); // Обновляем список транзакций при возвращении на экран
    });
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange:
          customDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      locale: const Locale('ru', 'RU'), // Устанавливаем русский язык
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('ru', 'RU'), // Принудительная локализация
          child: child,
        );
      },
    );
    if (result != null) {
      setState(() {
        customDateRange = result;
        selectedPeriodFilter = 'Произвольный период';
      });
      _loadTransactions();
    }
  }

  String _getPeriodFilterLabel() {
    if (selectedPeriodFilter == 'Произвольный период' &&
        customDateRange != null) {
      final start = _formatDate(customDateRange!.start);
      final end = _formatDate(customDateRange!.end);
      return '$start - $end';
    }
    return selectedPeriodFilter;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy', 'ru').format(date);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMMM yyyy, HH:mm', 'ru').format(dateTime);
  }

  Future<void> _loadTransactions() async {
    final data = await DatabaseService.getTransactionsByAccount(
      selectedAccountId,
    );
    setState(() {
      transactions.clear();
      transactions.addAll(
        data
            .where((t) {
              // Фильтрация по категории
              if (selectedCategoryFilter != null &&
                  selectedCategoryFilter != 'Все' &&
                  t['category'] != selectedCategoryFilter) {
                return false;
              }

              // Фильтрация по периоду
              if (selectedPeriodFilter != 'Все') {
                final transactionDate = DateTime.parse(t['date']);
                final now = DateTime.now();
                if (selectedPeriodFilter == 'Сегодня' &&
                    !isSameDay(transactionDate, now)) {
                  return false;
                } else if (selectedPeriodFilter == 'Неделя' &&
                    transactionDate.isBefore(
                      now.subtract(const Duration(days: 7)),
                    )) {
                  return false;
                } else if (selectedPeriodFilter == 'Месяц' &&
                    transactionDate.isBefore(
                      DateTime(now.year, now.month - 1, now.day),
                    )) {
                  return false;
                } else if (selectedPeriodFilter == 'Год' &&
                    transactionDate.isBefore(
                      DateTime(now.year - 1, now.month, now.day),
                    )) {
                  return false;
                } else if (selectedPeriodFilter == 'Произвольный период' &&
                    (customDateRange == null ||
                        transactionDate.isBefore(customDateRange!.start) ||
                        transactionDate.isAfter(customDateRange!.end))) {
                  return false;
                }
              }

              return true;
            })
            .map(
              (t) => TransactionData(
                id: t['id'].toString(),
                accountId: t['account_id'],
                category: t['category'],
                title: t['title'],
                subtitle:
                    t['date'] != null
                        ? _formatDateTime(DateTime.parse(t['date']))
                        : 'Дата не указана',
                amount: t['amount'],
                color: t['amount'] > 0 ? Colors.green : Colors.redAccent,
                comment: t['comment'] ?? '',
              ),
            )
            .toList(),
      );
    });
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _loadAccounts() async {
    final data = await DatabaseService.getAllAccounts();
    setState(() {
      accounts.clear();
      accounts.addAll(
        data.map(
          (a) => model_account.Account(
            id: a['id'], // Убедитесь, что id не null
            name: a['name'],
          ),
        ),
      );

      // Сбрасываем selectedAccountId, если оно не соответствует ни одному id
      if (!accounts.any((account) => account.id == selectedAccountId)) {
        selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;
      }
    });
  }

  Future<void> _loadCategories() async {
    final fetchedCategories = await DatabaseService.getAllCategories();
    setState(() {
      categories =
          fetchedCategories.map((category) {
            return {'id': category['id'], 'name': category['name']};
          }).toList();
    });
  }

  Future<void> _openTransactionDetailsScreen(
    BuildContext context,
    TransactionCard card,
  ) async {
    final result = await Navigator.of(context).push(
      _fadeRoute(
        TransactionDetailsScreen(
          id: card.id, // Передаем id транзакции
          icon: _buildCategoryIcon(
            card.category,
          ), // Используем _buildCategoryIcon
          title: card.title,
          subtitle: card.subtitle,
          amount: card.amount,
          color: card.color,
          category: card.category['name'], // Передаем название категории
          comment: card.comment,
        ),
      ),
    );
    if (result == true) {
      _loadTransactions(); // Обновляем список транзакций
    }
  }

  void _openAddAccountScreen(BuildContext context) async {
    final result = await Navigator.of(context).push<model_account.Account>(
      _fadeRoute<model_account.Account>(EditAccountScreen()),
    );
    if (result != null) {
      await _loadAccounts(); // Загружаем актуальный список счетов из базы
      setState(() {
        selectedAccountId = result.id; // Устанавливаем ID нового счета
      });
      _loadTransactions(); // Обновляем список транзакций для нового счета
    }
  }

  void _openEditAccountScreen(
    BuildContext context,
    model_account.Account account,
  ) async {
    final result = await Navigator.of(context).push<model_account.Account>(
      _fadeRoute<model_account.Account>(
        EditAccountScreen(
          initialName: account.name, // Удалён параметр initialBalance
        ),
      ),
    );
    if (result != null) {
      await DatabaseService.updateAccount(result.toMap());
      await _loadAccounts(); // Обновляем список счетов
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

  // Добавлено: метод для обновления транзакций
  Future<void> updateTransactions() async {
    await _loadTransactions();
  }

  String _calculateAccountBalance(int accountId) {
    final accountTransactions = transactions.where(
      (t) => t.accountId == accountId,
    );
    final balance = accountTransactions.fold<int>(
      0,
      (sum, t) => sum + t.amount,
    );
    return '$balance ₽';
  }

  String _calculateTotalBalance() {
    final totalBalance = transactions.fold<int>(0, (sum, t) => sum + t.amount);
    return '$totalBalance ₽';
  }

  Widget buildTransactionSummary(BuildContext context) {
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
        child: Column(
          children: [
            // --- Баланс и выбор счета ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value:
                          accounts.any(
                                (account) => account.id == selectedAccountId,
                              )
                              ? selectedAccountId
                              : null,
                      decoration: const InputDecoration(
                        labelText: 'Счёт',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Все')),
                        ...accounts.map(
                          (account) => DropdownMenuItem(
                            value: account.id,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(account.name),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed:
                                      () => _openEditAccountScreen(
                                        context,
                                        account,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      onChanged: (id) {
                        setState(() {
                          selectedAccountId = id;
                        });
                        _loadTransactions();
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
            ),
            // --- Фильтры ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedPeriodFilter,
                      decoration: const InputDecoration(
                        labelText: 'Период',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Все', child: Text('Все')),
                        DropdownMenuItem(
                          value: 'Сегодня',
                          child: Text('Сегодня'),
                        ),
                        DropdownMenuItem(
                          value: 'Неделя',
                          child: Text('Неделя'),
                        ),
                        DropdownMenuItem(value: 'Месяц', child: Text('Месяц')),
                        DropdownMenuItem(value: 'Год', child: Text('Год')),
                        DropdownMenuItem(
                          value: 'Произвольный период',
                          child: Text('Произвольный период'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == 'Произвольный период') {
                          _selectCustomDateRange(context);
                        } else {
                          setState(() {
                            selectedPeriodFilter = value!;
                          });
                          _loadTransactions();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value:
                          selectedCategoryFilter != null
                              ? int.tryParse(
                                selectedCategoryFilter!,
                              ) // Преобразуем строку в int
                              : null,
                      decoration: const InputDecoration(
                        labelText: 'Категория',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Все категории'),
                        ),
                        ...categories.map((category) {
                          return DropdownMenuItem<int?>(
                            value: category['id'], // Используем id категории
                            child: Text(category['name']),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryFilter =
                              value?.toString(); // Сохраняем id как строку
                        });
                        _loadTransactions();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Выбранный период: ${_getPeriodFilterLabel()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            // --- Баланс выбранного счета или общий баланс ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
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
                      selectedAccountId == null
                          ? _calculateTotalBalance() // Общий баланс для всех счетов
                          : _calculateAccountBalance(selectedAccountId!),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // --- Список транзакций и итоги ---
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children:
                          transactions
                              .map(
                                (transaction) => TransactionCard(
                                  id: transaction.id,
                                  category: categories.firstWhere(
                                    (category) =>
                                        category['id'] ==
                                        int.tryParse(transaction.category),
                                    orElse:
                                        () => {
                                          'name': 'Неизвестно',
                                          'customIconPath': null,
                                          'icon': null,
                                        },
                                  ), // Передаем всю категорию как Map<String, dynamic>
                                  title: transaction.title,
                                  subtitle: transaction.subtitle,
                                  amount:
                                      '${transaction.amount > 0 ? '+' : ''}${transaction.amount} ₽',
                                  color: transaction.color,
                                  comment: transaction.comment,
                                  onTap:
                                      (context, card) =>
                                          _openTransactionDetailsScreen(
                                            context,
                                            card,
                                          ),
                                ),
                              )
                              .toList(), // Преобразуем Iterable в List
                    ),
                  ),
                  // Итоги
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
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
                          valueColor:
                              total >= 0 ? Colors.green : Colors.redAccent,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionData {
  final String id; // Добавлено поле id
  final int accountId; // Добавлено поле accountId
  final String category;
  final String title;
  final String subtitle;
  final int amount;
  final Color color;
  final String comment;

  TransactionData({
    required this.id,
    required this.accountId,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    required this.comment,
  });
}

// --- Карточка транзакции ---
class TransactionCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic>
  category; // Передаем категорию как Map<String, dynamic>
  final String title;
  final String subtitle;
  final String amount;
  final Color color;
  final String comment;
  final void Function(BuildContext, TransactionCard)? onTap;

  const TransactionCard({
    super.key,
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    required this.comment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget leadingIcon = _buildCategoryIcon(
      category,
    ); // Используем _buildCategoryIcon
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
              color: valueColor,
              fontSize: 17,
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

Widget _buildCategoryIcon(Map<String, dynamic> category) {
  final String? customIconPath = category['customIconPath'];
  final int? iconCode = category['icon'];

  if (customIconPath != null && File(customIconPath).existsSync()) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(
        File(customIconPath),
        width: 32,
        height: 32,
        fit: BoxFit.cover,
      ),
    );
  } else if (iconCode != null) {
    return Icon(IconData(iconCode, fontFamily: 'MaterialIcons'), size: 32);
  } else {
    return const Icon(Icons.label, size: 32);
  }
}
