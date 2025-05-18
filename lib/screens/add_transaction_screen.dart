import 'package:flutter/material.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController();
    final _commentController = TextEditingController();
    final _timeController = TextEditingController();
    String? _selectedType;
    String? _selectedCategory;
    final List<String> _categories = [
      'Продукты',
      'Транспорт',
      'Развлечения',
      'Зарплата',
      'Другое',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Добавить операцию')),
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Тип'),
                  items: const [
                    DropdownMenuItem(value: 'доход', child: Text('Доход')),
                    DropdownMenuItem(value: 'расход', child: Text('Расход')),
                  ],
                  value: _selectedType,
                  onChanged: (value) {
                    _selectedType = value;
                  },
                  validator: (value) => value == null ? 'Выберите тип' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
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
                      _categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                  value: _selectedCategory,
                  onChanged: (value) {
                    _selectedCategory = value;
                  },
                  validator:
                      (value) => value == null ? 'Выберите категорию' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _timeController,
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
                  controller: _commentController,
                  decoration: const InputDecoration(labelText: 'Комментарий'),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
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
