import 'package:flutter/material.dart';
import '../services/database_service.dart';

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
  final List<String> categories = [
    'Продукты',
    'Транспорт',
    'Развлечения',
    'Зарплата',
    'Другое',
  ];

  @override
  void dispose() {
    titleController.dispose(); // Добавлено
    amountController.dispose();
    commentController.dispose();
    timeController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? now),
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
    const months = [
      '',
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    final day = dateTime.day;
    final month = months[dateTime.month];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
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
      };
      final id = await DatabaseService.insertTransaction(transaction);
      if (id > 0) {
        if (!mounted) return;
        Navigator.pop(context, true); // Возвращаем true для обновления списка
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при сохранении транзакции')),
        );
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
