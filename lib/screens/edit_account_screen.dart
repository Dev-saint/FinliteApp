import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/database_service.dart';

class EditAccountScreen extends StatefulWidget {
  final String? initialName;

  const EditAccountScreen({super.key, this.initialName});

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

  Future<void> _saveAccount() async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = nameController.text.trim();

      final account = Account(
        id:
            widget.initialName != null
                ? await _getAccountIdByName(widget.initialName!)
                : null,
        name: name,
      );

      if (account.id == null) {
        await DatabaseService.insertAccount(account.toMap());
      } else {
        await DatabaseService.updateAccount(account.toMap());
      }

      if (!mounted) return;
      Navigator.pop(context, account);
    }
  }

  Future<int?> _getAccountIdByName(String name) async {
    final accounts = await DatabaseService.getAllAccounts();
    final account = accounts.firstWhere(
      (a) => a['name'] == name,
      orElse: () => {}, // Возвращаем пустую карту вместо null
    );
    return account.isNotEmpty
        ? account['id'] as int?
        : null; // Убираем ? перед ['id']
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
