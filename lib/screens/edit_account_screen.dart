import 'package:flutter/material.dart';
import '../models/account.dart';

class EditAccountScreen extends StatefulWidget {
  final String? initialName;
  final int? initialBalance;

  const EditAccountScreen({super.key, this.initialName, this.initialBalance});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  late TextEditingController nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialName == null ? 'Создать счёт' : 'Редактировать счёт',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название счёта'),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Введите название счёта'
                            : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final name = nameController.text.trim();
                    final balance = widget.initialBalance ?? 0;
                    Navigator.pop(
                      context,
                      Account(name: name, balance: balance),
                    );
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
