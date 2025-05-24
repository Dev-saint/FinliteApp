import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  IconData? _selectedIcon;
  String? _customIconPath;
  String _selectedType = 'расход'; // По умолчанию расход
  List<Map<String, dynamic>> categories = []; // Список категорий из базы данных
  int? selectedCategoryId; // Выбранная категория

  static const List<IconData> _iconOptions = [
    Icons.shopping_cart,
    Icons.directions_car,
    Icons.movie,
    Icons.attach_money,
    Icons.fastfood,
    Icons.home,
    Icons.sports_soccer,
    Icons.pets,
    Icons.cake,
    Icons.label,
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadTransactionDetails(); // Загружаем данные транзакции
    _loadCategories(); // Загружаем категории из базы данных
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
        selectedCategoryId =
            transaction['categoryId'] as int?; // Приводим к int?
      });
    }
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

  Future<void> _pickCustomIcon() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _customIconPath = pickedFile.path;
      });
    }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать транзакцию')),
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Сумма'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  // Форматирование ввода суммы
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Иконка',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children:
                    _iconOptions.map((icon) {
                      final isSelected =
                          _selectedIcon == icon && _customIconPath == null;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIcon = icon;
                            _customIconPath = null;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor:
                              isSelected
                                  ? Theme.of(context).colorScheme.primary
                                      .withAlpha((0.2 * 255).toInt())
                                  : Colors.grey.shade200,
                          child: Icon(
                            icon,
                            color:
                                isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.black54,
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _pickCustomIcon();
                        setState(() {
                          _selectedIcon = null;
                          // _customIconPath уже обновлён
                        });
                      },
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Загрузить свою иконку'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    if (_customIconPath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              _customIconPath!.startsWith('assets/')
                                  ? Image.asset(
                                    _customIconPath!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  )
                                  : Icon(
                                    Icons.image,
                                    size: 48,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: selectedCategoryId,
                hint: const Text('Выберите категорию'),
                items:
                    categories.map((category) {
                      return DropdownMenuItem<int?>(
                        value: category['id'],
                        child: Text(category['name']),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategoryId = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_customIconPath != null) {
                    await _resizeAndSaveCustomIcon(_customIconPath!);
                  }
                  final updatedTransaction = {
                    'id': widget.transactionId,
                    'amount': double.tryParse(_amountController.text.trim()),
                    'description': _descriptionController.text.trim(),
                    'icon':
                        _selectedIcon?.codePoint, // Сохраняем только codePoint
                    'type': _selectedType,
                    'customIconPath': _customIconPath,
                    'categoryId': selectedCategoryId,
                  };
                  await DatabaseService.updateTransaction(
                    updatedTransaction,
                  ); // Сохраняем в БД
                  if (!mounted) return;
                  Navigator.pop(
                    context,
                    true,
                  ); // Возвращаемся с флагом обновления
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
