import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../main.dart'; // Добавлен импорт для доступа к глобальному методу
import '../models/account.dart'; // Добавьте этот импорт, если Account определён в models/account.dart

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final commentController = TextEditingController();
  final timeController = TextEditingController();
  final titleController = TextEditingController(); // Добавлено
  String? selectedType;
  String? selectedCategory;
  DateTime? selectedDateTime;
  int? selectedAccountId;
  final List<String> categories = [
    'Продукты',
    'Транспорт',
    'Развлечения',
    'Зарплата',
    'Другое',
  ];
  final List<Account> accounts = []; // Удалено поле balance из Account

  @override
  void initState() {
    super.initState();
    _loadAccounts(); // Загружаем список счетов при инициализации
  }

  @override
  void dispose() {
    titleController.dispose(); // Добавлено
    amountController.dispose();
    commentController.dispose();
    timeController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final data = await DatabaseService.getAllAccounts();
    setState(() {
      accounts.clear();
      accounts.addAll(data.map((a) => Account(id: a['id'], name: a['name'])));
    });
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    if (!mounted) return;
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ru', 'RU'), // Устанавливаем русский язык
    );
    if (!mounted) return;
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? now),
        builder: (ctx, child) {
          return Localizations.override(
            context: ctx,
            locale: const Locale('ru', 'RU'), // Устанавливаем русский язык
            child: child,
          );
        },
      );
      if (!mounted) return;
      if (time != null) {
        setState(() {
          selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          timeController.text = _formatDateTime(selectedDateTime!);
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMMM yyyy, HH:mm', 'ru').format(dateTime);
  }

  Future<void> _saveTransaction() async {
    if (formKey.currentState?.validate() ?? false) {
      final transaction = {
        'title': titleController.text,
        'amount':
            int.parse(amountController.text) *
            (selectedType == 'расход' ? -1 : 1), // Учитываем тип
        'type': selectedType,
        'category': selectedCategory,
        'date': selectedDateTime?.toIso8601String(),
        'comment': commentController.text,
        'account_id': selectedAccountId, // Привязка к счету
      };

      try {
        final id = await DatabaseService.insertTransaction(transaction);
        if (id > 0) {
          updateHomeScreenTransactions(); // Вызываем глобальный метод обновления
          if (!mounted) return;
          Navigator.pop(context, true); // Возвращаемся на главный экран
        } else {
          throw Exception('Ошибка при сохранении транзакции');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить операцию')),
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название транзакции',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Тип *'),
                  items: const [
                    DropdownMenuItem(value: 'доход', child: Text('Доход')),
                    DropdownMenuItem(value: 'расход', child: Text('Расход')),
                  ],
                  value: selectedType,
                  onChanged: (value) {
                    setState(() {
                      selectedType = value;
                    });
                  },
                  validator: (value) => value == null ? 'Выберите тип' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Сумма *'),
                  keyboardType: TextInputType.number,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Введите сумму'
                              : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Категория *'),
                  items:
                      categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                  value: selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                  validator:
                      (value) => value == null ? 'Выберите категорию' : null,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _pickDateTime(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Дата и время *',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Выберите дату и время'
                                  : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: commentController,
                  decoration: const InputDecoration(labelText: 'Комментарий'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(labelText: 'Счёт *'),
                  items:
                      accounts
                          .map(
                            (account) => DropdownMenuItem(
                              value:
                                  account
                                      .id, // Убедитесь, что передается правильный id счета
                              child: Text(account.name),
                            ),
                          )
                          .toList(),
                  value: selectedAccountId,
                  onChanged: (value) {
                    setState(() {
                      selectedAccountId = value; // Сохраняем выбранный id счета
                    });
                  },
                  validator: (value) {
                    if (accounts.isEmpty) {
                      return 'Сначала создайте хотя бы один счёт.';
                    }
                    return value == null ? 'Выберите счёт' : null;
                  },
                ),
                if (accounts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Сначала создайте хотя бы один счёт.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveTransaction,
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
