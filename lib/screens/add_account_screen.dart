import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/database_service.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = nameController.text.trim();

      final account = Account(name: name);

      await DatabaseService.insertAccount(account.toMap());
      if (!mounted) return;
      Navigator.pop(context, account);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить счёт')),
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
                onPressed: _saveAccount,
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
