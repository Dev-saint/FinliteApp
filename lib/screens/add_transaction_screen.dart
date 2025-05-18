import 'package:flutter/material.dart';

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
  String? selectedType;
  String? selectedCategory;
  final List<String> categories = [
    'Продукты',
    'Транспорт',
    'Развлечения',
    'Зарплата',
    'Другое',
  ];

  @override
  void dispose() {
    amountController.dispose();
    commentController.dispose();
    timeController.dispose();
    super.dispose();
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
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Тип'),
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
                  decoration: const InputDecoration(labelText: 'Сумма'),
                  keyboardType: TextInputType.number,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Введите сумму'
                              : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Категория'),
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
                TextFormField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Время (например, 14:30)',
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Введите время'
                              : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: commentController,
                  decoration: const InputDecoration(labelText: 'Комментарий'),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(context); // Здесь можно добавить сохранение
                    }
                  },
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
