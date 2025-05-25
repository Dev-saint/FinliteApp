import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_service.dart';

class EditTransactionScreen extends StatefulWidget {
  final int transactionId;

  const EditTransactionScreen({super.key, required this.transactionId});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  String _selectedType = 'расход'; // По умолчанию расход
  List<Map<String, dynamic>> categories = []; // Список категорий из базы данных
  int? selectedCategoryId; // Выбранная категория
  Map<String, dynamic>? selectedCategoryItem; // Выбранная категория как Map

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadTransactionDetails();
    _loadCategories();
  }

  Future<void> _loadTransactionDetails() async {
    final transaction = await DatabaseService.getTransactionById(
      widget.transactionId.toString(),
    );
    if (transaction != null) {
      setState(() {
        _amountController.text = transaction['amount'].toString();
        _descriptionController.text = transaction['description'] ?? '';
        _selectedType = transaction['type'];
        selectedCategoryId = transaction['categoryId'] as int?;
      });
    }
  }

  Future<void> _loadCategories() async {
    final fetchedCategories = await DatabaseService.getAllCategories();
    setState(() {
      categories = List<Map<String, dynamic>>.from(fetchedCategories);
      if (selectedCategoryId != null) {
        selectedCategoryItem = categories.firstWhere(
          (cat) => cat['id'] == selectedCategoryId,
          orElse: () => <String, dynamic>{},
        );
      }
    });
  }

  Future<void> _resizeAndSaveCustomIcon(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image != null) {
      final resized = img.copyResize(image, width: 48, height: 48);
      final resizedBytes = img.encodePng(resized);
      await file.writeAsBytes(resizedBytes);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать транзакцию')),
      body: Material(
        color: colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Center(
                child: CategoryIconDisplay(category: selectedCategoryItem),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Сумма'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Тип: ', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedType,
                    items: const [
                      DropdownMenuItem(value: 'доход', child: Text('Доход')),
                      DropdownMenuItem(value: 'расход', child: Text('Расход')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedType = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                decoration: const InputDecoration(labelText: 'Категория *'),
                value:
                    categories.any((cat) => cat['id'] == selectedCategoryId)
                        ? selectedCategoryId
                        : null,
                hint: const Text('Выберите категорию'),
                items:
                    categories.map((category) {
                      return DropdownMenuItem<int?>(
                        value: category['id'],
                        child: Row(
                          children: [
                            CategoryIconDisplay(category: category),
                            const SizedBox(width: 8),
                            Text(category['name']),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final selected = categories.firstWhere(
                      (cat) => cat['id'] == value,
                      orElse: () => <String, dynamic>{},
                    );
                    setState(() {
                      selectedCategoryId = value;
                      selectedCategoryItem = selected;
                    });
                  }
                },
                validator:
                    (value) => value == null ? 'Выберите категорию' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final updatedTransaction = {
                    'id': widget.transactionId,
                    'amount': double.tryParse(_amountController.text.trim()),
                    'description': _descriptionController.text.trim(),
                    'type': _selectedType,
                    'categoryId': selectedCategoryId,
                  };
                  await DatabaseService.updateTransaction(updatedTransaction);
                  if (!mounted) return;
                  Navigator.pop(context, true);
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

class CategoryIconDisplay extends StatelessWidget {
  final Map<String, dynamic>? category;

  const CategoryIconDisplay({super.key, this.category});

  @override
  Widget build(BuildContext context) {
    if (category == null) return const Icon(Icons.label, size: 48);

    final String? customIconPath = category!['customIconPath'];
    final int? iconCode = category!['icon'];

    if (customIconPath != null && File(customIconPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(customIconPath),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    } else if (iconCode != null) {
      return Icon(IconData(iconCode, fontFamily: 'MaterialIcons'), size: 48);
    } else {
      return const Icon(Icons.label, size: 48);
    }
  }
}
