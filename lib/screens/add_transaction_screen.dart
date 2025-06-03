import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../main.dart'; // Добавлен импорт для доступа к глобальному методу
import '../models/account.dart'; // Добавьте этот импорт, если Account определён в models/account.dart
import 'dart:io'; // Импортируем dart:io для работы с File
import '../services/file_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import '../widgets/calculator_dialog.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionAttachment {
  final String fileName;
  final String filePath;
  final bool isImage;
  _AddTransactionAttachment({
    required this.fileName,
    required this.filePath,
    required this.isImage,
  });
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final commentController = TextEditingController();
  final timeController = TextEditingController();
  final titleController = TextEditingController(); // Добавлено
  String? selectedType;
  int? selectedCategoryId; // Выбранная категория
  DateTime? selectedDateTime;
  int? selectedAccountId;
  List<Map<String, dynamic>> categories = []; // Список категорий из базы данных
  final List<Account> accounts = []; // Удалено поле balance из Account
  List<_AddTransactionAttachment> attachments = [];
  final TextEditingController calculatorController = TextEditingController();
  String calculatorResult = '';

  @override
  void initState() {
    super.initState();
    _loadAccounts(); // Загружаем список счетов при инициализации
    _loadCategories(); // Загружаем категории из базы данных
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

  Future<void> _loadCategories() async {
    final fetchedCategories = await DatabaseService.getAllCategories();
    setState(() {
      categories = List<Map<String, dynamic>>.from(fetchedCategories);
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

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      for (final file in result.files) {
        if (file.path != null) {
          final copiedPath = await FileService.copyToAttachments(
            File(file.path!),
          );
          setState(() {
            attachments.add(
              _AddTransactionAttachment(
                fileName: file.name,
                filePath: copiedPath,
                isImage: FileService.isImage(copiedPath),
              ),
            );
          });
        }
      }
    }
  }

  Future<void> _removeAttachment(int index) async {
    await FileService.deleteFile(attachments[index].filePath);
    setState(() {
      attachments.removeAt(index);
    });
  }

  bool _isImage(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.png') ||
        ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.bmp') ||
        ext.endsWith('.webp');
  }

  Future<void> _openAttachment(_AddTransactionAttachment att) async {
    await OpenFile.open(att.filePath);
  }

  Future<void> _saveAttachmentTo(_AddTransactionAttachment att) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      final destPath = '$result/${att.fileName}';
      await FileService.saveFileTo(att.filePath, destPath);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Файл сохранён: $destPath')));
    }
  }

  Future<void> _saveTransaction() async {
    if (formKey.currentState?.validate() ?? false) {
      final transaction = {
        'title': titleController.text,
        'amount':
            double.tryParse(amountController.text.replaceAll(',', '.')) ??
            0.0 * (selectedType == 'расход' ? -1 : 1),
        'type': selectedType,
        'category_id': selectedCategoryId,
        'date': selectedDateTime?.toIso8601String(),
        'description': commentController.text,
        'account_id': selectedAccountId,
      };

      try {
        final id = await DatabaseService.insertTransaction(transaction);
        // Сохраняем вложения
        for (final att in attachments) {
          await DatabaseService.insertAttachment({
            'transaction_id': id,
            'file_name': att.fileName,
            'file_path': att.filePath,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
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

  Widget _buildCategoryIcon(Map<String, dynamic> category) {
    if (category['customIconPath'] != null &&
        File(category['customIconPath']).existsSync()) {
      return Image.file(
        File(category['customIconPath']),
        width: 32,
        height: 32,
        fit: BoxFit.cover,
      );
    }
    return Icon(
      category['icon'] != null
          ? IconData(category['icon'], fontFamily: 'MaterialIcons')
          : Icons.label,
      size: 32,
    );
  }

  Widget _buildAmountInput() {
    return TextFormField(
      controller: amountController,
      decoration: InputDecoration(
        labelText: 'Сумма *',
        suffixText: '₽',
        prefixIcon: const Icon(Icons.attach_money),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calculate),
          onPressed: () async {
            final result = await showDialog<String>(
              context: context,
              builder:
                  (context) => CalculatorDialog(
                    initialValue: amountController.text,
                    onResult: (value) {
                      amountController.text = value;
                    },
                  ),
            );
            if (result != null) {
              setState(() {
                amountController.text = result;
              });
            }
          },
        ),
        errorStyle: const TextStyle(color: Colors.red),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Введите сумму';
        }
        final regex = RegExp(r'^\d+([.,]\d{0,2})?$');
        if (!regex.hasMatch(value)) {
          return 'Используйте формат: число с запятой и максимум 2 знаками после запятой (например: 1000,50)';
        }
        final amount = double.tryParse(value.replaceAll(',', '.'));
        if (amount == null || amount <= 0) {
          return 'Сумма должна быть больше нуля';
        }
        if (amount > 1000000000) {
          return 'Сумма не должна превышать 1 000 000 000 ₽';
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (value) {
        // Форматируем ввод с фиксированным форматом
        final formatted = _formatAmountWithFixedDecimals(value);
        if (formatted != value) {
          final cursorPos = amountController.selection.baseOffset;
          amountController.text = formatted;
          if (cursorPos != -1) {
            amountController.selection = TextSelection.fromPosition(
              TextPosition(offset: cursorPos),
            );
          }
        }
      },
    );
  }

  String _formatAmountWithFixedDecimals(String value) {
    if (value.isEmpty) return '0,00';
    value = value.replaceAll(RegExp(r'[^\d,]'), '');
    value = value.replaceAll(RegExp(r','), ',');
    if (!value.contains(',')) {
      value = '0,00';
    } else {
      final parts = value.split(',');
      if (parts.length > 1) {
        value = '${parts[0]},${parts[1].padRight(2, '0').substring(0, 2)}';
      }
    }
    return value;
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
            child: SingleChildScrollView(
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
                  _buildAmountInput(),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(labelText: 'Категория *'),
                    value: selectedCategoryId,
                    hint: const Text('Выберите категорию'),
                    items:
                        categories.map((category) {
                          return DropdownMenuItem<int?>(
                            value: category['id'],
                            child: Row(
                              children: [
                                _buildCategoryIcon(
                                  category,
                                ), // Отображаем иконку категории
                                const SizedBox(width: 8),
                                Text(category['name']),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId = value;
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
                        selectedAccountId =
                            value; // Сохраняем выбранный id счета
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
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Файлы',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Прикрепить файл'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (attachments.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: attachments.length,
                      itemBuilder: (context, index) {
                        final att = attachments[index];
                        return Card(
                          child: ListTile(
                            leading:
                                _isImage(att.filePath)
                                    ? Image.file(
                                      File(att.filePath),
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    )
                                    : const Icon(
                                      Icons.insert_drive_file,
                                      size: 40,
                                    ),
                            title: Text(att.fileName),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  tooltip: 'Открыть',
                                  onPressed: () => _openAttachment(att),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  tooltip: 'Скачать',
                                  onPressed: () => _saveAttachmentTo(att),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Удалить',
                                  onPressed: () => _removeAttachment(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
      ),
    );
  }
}
