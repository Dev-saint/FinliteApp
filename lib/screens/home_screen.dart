import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction_details_screen.dart';
import '../models/account.dart' as model_account;
import '../services/database_service.dart';
import 'edit_account_screen.dart'; // Добавлен импорт
import 'dart:io'; // Импортируем dart:io для работы с файлами
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  int? selectedAccountId;
  List<model_account.Account> accounts = [];
  String? selectedCategoryFilter;
  String selectedPeriodFilter = 'Все';
  String selectedTransactionType = 'Все';
  DateTimeRange? customDateRange;
  List<Map<String, dynamic>> categories = [];
  final List<TransactionData> transactions = [];
  double _balance = 0.0;

  @override
  bool get wantKeepAlive => true; // Сохраняем состояние при навигации

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: Column(
        children: [
          // Блок 1: Выбор счета и баланс
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Выбор счета
                Row(
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
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Все'),
                          ),
                          ...accounts.map(
                            (account) => DropdownMenuItem(
                              value: account.id,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                const SizedBox(height: 16),
                // Баланс
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
                        selectedAccountId == null
                            ? _formatBalance(_balance)
                            : _formatBalance(_balance),
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          color:
                              _balance >= 0
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Блок 2: Фильтры (зафиксированный)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Фильтры периода и категории
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPeriodFilter,
                        decoration: InputDecoration(
                          labelText: _getPeriodLabel(),
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
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
                          DropdownMenuItem(
                            value: 'Месяц',
                            child: Text('Месяц'),
                          ),
                          DropdownMenuItem(value: 'Год', child: Text('Год')),
                          DropdownMenuItem(
                            value: 'Произвольный период',
                            child: Text('Выбрать период...'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == 'Произвольный период') {
                            _selectCustomDateRange(context);
                          } else {
                            setState(() {
                              selectedPeriodFilter = value!;
                              customDateRange = null;
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
                                ? int.tryParse(selectedCategoryFilter!)
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
                              value: category['id'],
                              child: Row(
                                children: [
                                  if (category['customIconPath'] != null &&
                                      File(
                                        category['customIconPath'],
                                      ).existsSync())
                                    Image.file(
                                      File(category['customIconPath']),
                                      width: 24,
                                      height: 24,
                                    )
                                  else
                                    Icon(
                                      IconData(
                                        category['icon'] ??
                                            Icons.label.codePoint,
                                        fontFamily: 'MaterialIcons',
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(category['name']),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCategoryFilter = value?.toString();
                          });
                          _loadTransactions();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Селектор типа транзакции
                Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(value: 'Все', label: Text('Все')),
                      ButtonSegment<String>(
                        value: 'Доходы',
                        label: Text('Доходы'),
                        icon: Icon(Icons.arrow_upward, color: Colors.green),
                      ),
                      ButtonSegment<String>(
                        value: 'Расходы',
                        label: Text('Расходы'),
                        icon: Icon(Icons.arrow_downward, color: Colors.red),
                      ),
                    ],
                    selected: {selectedTransactionType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        selectedTransactionType = newSelection.first;
                      });
                      _loadTransactions();
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Theme.of(context).colorScheme.primaryContainer;
                        }
                        return Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest;
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Блок 3: Список транзакций (прокручиваемый)
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Список транзакций
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return TransactionCard(
                          id: transaction.id,
                          category: transaction.category,
                          title: transaction.title,
                          subtitle: transaction.subtitle,
                          amount:
                              (transaction.amount > 0 ? '+' : '') +
                              _formatBalance(transaction.amount),
                          color: transaction.color,
                          comment: transaction.comment,
                          onTap:
                              (context, card) => _openTransactionDetailsScreen(
                                context,
                                card.id.toString(),
                              ),
                        );
                      },
                    ),
                    // Итоги
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerLow,
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
                            value: transactions.fold<double>(
                              0.0,
                              (sum, t) => sum + t.amount,
                            ),
                            valueColor:
                                transactions.fold<double>(
                                          0.0,
                                          (sum, t) => sum + t.amount,
                                        ) >=
                                        0.0
                                    ? Colors.green
                                    : Colors.redAccent,
                            isNegative:
                                transactions.fold<double>(
                                  0.0,
                                  (sum, t) => sum + t.amount,
                                ) <
                                0.0,
                          ),
                          _SummaryDivider(),
                          _SummaryColumn(
                            title: 'Доходы',
                            value: income,
                            valueColor: Colors.green,
                          ),
                          _SummaryDivider(),
                          _SummaryColumn(
                            title: 'Расходы',
                            value: expense.abs(),
                            valueColor: Colors.redAccent,
                            isNegative: true,
                          ),
                        ],
                      ),
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

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadCategories();
    _loadTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем список транзакций при возврате на экран
    // только если это не первая инициализация
    if (transactions.isNotEmpty) {
      _loadTransactions();
    }
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
      locale: const Locale('ru', 'RU'),
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('ru', 'RU'),
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

  String _getPeriodLabel() {
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
    await _updateBalance();
    if (!mounted) return;

    final data = await DatabaseService.getTransactionsByAccount(
      selectedAccountId,
    );
    if (!mounted) return;

    setState(() {
      transactions.clear();
      transactions.addAll(
        data
            .where((t) {
              // Фильтрация по типу транзакции
              if (selectedTransactionType != 'Все') {
                final isIncome = t['amount'] > 0;
                if (selectedTransactionType == 'Доходы' && !isIncome) {
                  return false;
                }
                if (selectedTransactionType == 'Расходы' && isIncome) {
                  return false;
                }
              }

              // Фильтрация по категории
              if (selectedCategoryFilter != null &&
                  selectedCategoryFilter != 'Все' &&
                  t['category_id'] != selectedCategoryFilter) {
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
                category: categories.firstWhere(
                  (cat) => cat['id'] == t['category_id'],
                  orElse:
                      () => {
                        'name': 'Неизвестно',
                        'icon': null,
                        'customIconPath': null,
                      },
                ),
                title: t['title']?.toString() ?? '',
                subtitle:
                    t['date'] != null
                        ? _formatDateTime(DateTime.parse(t['date']))
                        : 'Дата не указана',
                amount: (t['amount'] as num?)?.toDouble() ?? 0.0,
                color: t['amount'] > 0 ? Colors.green : Colors.redAccent,
                comment: t['comment']?.toString() ?? '',
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
      accounts =
          data
              .map(
                (a) => model_account.Account(
                  id: a['id'] as int?,
                  name: a['name'] as String,
                ),
              )
              .toList();
    });
  }

  Future<void> _loadCategories() async {
    final fetchedCategories = await DatabaseService.getAllCategories();
    setState(() {
      categories = List<Map<String, dynamic>>.from(fetchedCategories);
    });
  }

  void _openTransactionDetailsScreen(
    BuildContext context,
    String transactionId,
  ) async {
    final card = transactions.firstWhere(
      (t) => t.id.toString() == transactionId,
    );
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => TransactionDetailsScreen(
              id: card.id.toString(),
              title: card.title,
              subtitle: card.subtitle,
              amount: card.amount.toString(),
              color: card.color,
              category: card.category['name']?.toString() ?? 'Неизвестно',
              comment: card.comment,
            ),
      ),
    );
    if (result == true) {
      await _loadTransactions();
      await _updateBalance();
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

  double get income => transactions
      .where((t) => t.amount > 0)
      .fold<double>(0.0, (sum, t) => sum + t.amount); // расчет доходов

  double get expense => transactions
      .where((t) => t.amount < 0)
      .fold<double>(0.0, (sum, t) => sum + t.amount); // расчет расходов

  String _formatBalance(double balance) {
    return '${balance.toStringAsFixed(2)} ₽';
  }

  // Метод для обновления транзакций, вызываемый извне
  Future<void> updateTransactions() async {
    await _loadTransactions();
  }

  void _openAddTransactionScreen(BuildContext context) async {
    final result = await Navigator.of(
      context,
    ).push(_fadeRoute(const AddTransactionScreen()));
    if (result == true) {
      await _loadTransactions();
      await _updateBalance();
    }
  }

  void _openEditTransactionScreen(
    BuildContext context,
    int transactionId,
  ) async {
    final result = await Navigator.of(
      context,
    ).push(_fadeRoute(EditTransactionScreen(transactionId: transactionId)));
    if (result == true) {
      await _loadTransactions();
      await _updateBalance();
    }
  }

  Future<void> _deleteTransaction(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Удалить транзакцию"),
            content: const Text(
              "Вы уверены, что хотите удалить эту транзакцию?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Отмена"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Удалить"),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await DatabaseService.deleteTransaction(id);
      await _loadTransactions();
    }
  }

  Future<void> _updateBalance() async {
    double newBalance;
    if (selectedAccountId == null) {
      newBalance = await DatabaseService.calculateTotalBalance();
    } else {
      newBalance = await DatabaseService.calculateAccountBalance(
        selectedAccountId!,
      );
    }
    setState(() {
      _balance = newBalance;
    });
  }

  int _parseCategoryId(dynamic id) {
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    return 0;
  }
}

class TransactionData {
  final String id;
  final int accountId;
  final Map<String, dynamic> category;
  final String title;
  final String subtitle;
  final double amount;
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
  final Map<String, dynamic> category;
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
    Widget leadingIcon;
    if (category['customIconPath'] != null &&
        File(category['customIconPath']).existsSync()) {
      leadingIcon = Image.file(
        File(category['customIconPath']),
        width: 32,
        height: 32,
        fit: BoxFit.cover,
      );
    } else {
      leadingIcon = Icon(
        IconData(
          category['icon'] ?? Icons.label.codePoint,
          fontFamily: 'MaterialIcons',
        ),
        color: color,
      );
    }
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
  final double value;
  final Color valueColor;
  final bool isNegative;

  const _SummaryColumn({
    required this.title,
    required this.value,
    required this.valueColor,
    this.isNegative = false,
  });

  static String _shortenNumber(double value) {
    if (value.abs() >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1).replaceAll('.0', '')}B';
    } else if (value.abs() >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1).replaceAll('.0', '')}M';
    } else if (value.abs() >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1).replaceAll('.0', '')}K';
    } else {
      return value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              (isNegative && value > 0 ? '-' : '') + _shortenNumber(value),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
                fontSize: 24,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${value.toStringAsFixed(2)} ₽',
            style: TextStyle(
              color: valueColor.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
