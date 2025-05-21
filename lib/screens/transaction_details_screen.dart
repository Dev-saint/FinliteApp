import 'package:flutter/material.dart';
import '../services/database_service.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color color;
  final String category;
  final String comment;

  const TransactionDetailsScreen({
    super.key,
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    required this.category,
    required this.comment,
  });

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _amountController;
  late TextEditingController _commentController;
  late String _category;
  late Color _color;
  DateTime? _selectedDateTime;
  late String _type = 'расход'; // Установлено значение по умолчанию

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _subtitleController = TextEditingController(text: widget.subtitle);
    _amountController = TextEditingController(
      text:
          widget.amount
              .replaceAll('₽', '')
              .replaceAll('+', '')
              .replaceAll('-', '')
              .trim(),
    );
    _commentController = TextEditingController(text: widget.comment);
    _category = widget.category;
    _color = widget.color;
    _type = _getCategoryType(_category); // Автоматическое подтягивание типа
    _selectedDateTime = _tryParseDateTime(widget.subtitle);
  }

  DateTime? _tryParseDateTime(String text) {
    // Удаляем лишние пробелы
    text = text.trim();

    // Ожидается формат "12 мая 2025, 14:30"
    try {
      final parts = text.split(',');
      if (parts.length == 2) {
        final datePart = parts[0].trim().split(' ');
        final timePart = parts[1].trim().split(':');

        if (datePart.length == 3 && timePart.length == 2) {
          const months = [
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

          final day = int.tryParse(datePart[0]);
          final month = months.indexOf(datePart[1]) + 1;
          final year = int.tryParse(datePart[2]);
          final hour = int.tryParse(timePart[0]);
          final minute = int.tryParse(timePart[1]);

          if (day != null &&
              month > 0 &&
              year != null &&
              hour != null &&
              minute != null) {
            return DateTime(year, month, day, hour, minute);
          }
        }
      }
    } catch (e) {
      print('Ошибка парсинга даты: $e');
    }
    return null;
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

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Продукты':
        return Icons.shopping_cart;
      case 'Транспорт':
        return Icons.directions_car;
      case 'Развлечения':
        return Icons.movie;
      case 'Зарплата':
        return Icons.attach_money;
      default:
        return Icons.label;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Продукты':
        return Colors.redAccent;
      case 'Зарплата':
        return Colors.green;
      case 'Транспорт':
        return Colors.blue;
      case 'Развлечения':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryType(String category) {
    switch (category) {
      case 'Продукты':
      case 'Транспорт':
      case 'Развлечения':
        return 'расход';
      case 'Зарплата':
        return 'доход';
      default:
        return 'расход';
    }
  }

  void _updateTypeFromCategory(String category) {
    setState(() {
      _type = _getCategoryType(category);
    });
  }

  void _startEdit() {
    setState(() {
      _isEditing = true;
    });
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _selectedDateTime ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (date != null) {
      // Only use context after mounted check
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
      );
      if (!mounted) return;
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _subtitleController.text = _formatDateTime(_selectedDateTime!);
        });
      }
    }
  }

  void _saveEdit() async {
    if (!mounted) return;
    if (_formKey.currentState?.validate() ?? false) {
      // Если дата не была изменена через интерфейс, пытаемся распарсить текст из поля
      final dateToSave =
          _selectedDateTime ??
          _tryParseDateTime(_subtitleController.text) ??
          _tryParseDateTime(widget.subtitle);

      final updatedTransaction = {
        'id': widget.id, // Используем id транзакции
        'title': _titleController.text,
        'amount':
            int.parse(_amountController.text) * (_type == 'расход' ? -1 : 1),
        'type': _type,
        'category': _category,
        'date': dateToSave?.toIso8601String(), // Преобразуем дату в ISO 8601
        'comment': _commentController.text,
      };

      await DatabaseService.updateTransaction(updatedTransaction);

      if (!mounted) return;
      Navigator.pop(context, true); // Возвращаем true для обновления списка
    }
  }

  void _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Удалить транзакцию'),
            content: const Text(
              'Вы уверены, что хотите удалить эту транзакцию?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Удалить'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final rowsDeleted = await DatabaseService.deleteTransaction(widget.id);
      if (rowsDeleted > 0) {
        if (!mounted) return;
        Navigator.pop(context, true); // Возвращаем true для обновления списка
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при удалении транзакции')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconWidget = Icon(
      _getCategoryIcon(_category),
      color: _color,
      size: 48,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали операции'),
        leading: IconButton(
          icon: Icon(_isEditing ? Icons.close : Icons.arrow_back),
          tooltip: _isEditing ? 'Отмена' : 'Назад',
          onPressed: () {
            if (_isEditing) {
              setState(() {
                _isEditing = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Удалить',
              onPressed: _deleteTransaction,
            ),
        ],
      ),
      body: Material(
        color: colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(height: 24),
                _isEditing
                    ? DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'Тип'),
                      items: const [
                        DropdownMenuItem(value: 'доход', child: Text('Доход')),
                        DropdownMenuItem(
                          value: 'расход',
                          child: Text('Расход'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _type = value;
                          });
                        }
                      },
                    )
                    : Text(
                      'Тип: $_type',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                const SizedBox(height: 8),
                _isEditing
                    ? TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Название'),
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Введите название'
                                  : null,
                    )
                    : Text(
                      _titleController.text,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                const SizedBox(height: 8),
                _isEditing
                    ? GestureDetector(
                      onTap: () => _pickDateTime(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _subtitleController,
                          decoration: const InputDecoration(
                            labelText: 'Дата и время',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Выберите дату и время'
                                      : null,
                        ),
                      ),
                    )
                    : Text(
                      _subtitleController.text,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                const SizedBox(height: 8),
                _isEditing
                    ? DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Категория'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Продукты',
                          child: Text('Продукты'),
                        ),
                        DropdownMenuItem(
                          value: 'Транспорт',
                          child: Text('Транспорт'),
                        ),
                        DropdownMenuItem(
                          value: 'Развлечения',
                          child: Text('Развлечения'),
                        ),
                        DropdownMenuItem(
                          value: 'Зарплата',
                          child: Text('Зарплата'),
                        ),
                        DropdownMenuItem(
                          value: 'Другое',
                          child: Text('Другое'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _category = value;
                            _color = _getCategoryColor(_category);
                            _updateTypeFromCategory(_category); // Обновляем тип
                          });
                        }
                      },
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Выберите категорию'
                                  : null,
                    )
                    : Text(
                      'Категория: $_category',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                const SizedBox(height: 24),
                _isEditing
                    ? TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: 'Сумма'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите сумму';
                        }
                        final num? parsed = num.tryParse(value);
                        if (parsed == null) return 'Некорректная сумма';
                        return null;
                      },
                    )
                    : Text(
                      widget.amount,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _color,
                      ),
                    ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? colorScheme.surfaceContainerLow
                            : colorScheme.primary.withAlpha(
                              (0.05 * 255).toInt(),
                            ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isDark
                              ? colorScheme.primary.withAlpha(
                                (0.25 * 255).toInt(),
                              )
                              : Colors.blueAccent.withAlpha(
                                (0.3 * 255).toInt(),
                              ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Комментарий',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      _isEditing
                          ? TextFormField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              labelText: 'Комментарий',
                            ),
                            maxLines: 2,
                          )
                          : Text(
                            _commentController.text.isNotEmpty
                                ? _commentController.text
                                : 'Нет комментария',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                    ],
                  ),
                ),
                const Spacer(),
                if (!_isEditing)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Редактировать'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                if (_isEditing)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveEdit,
                      icon: const Icon(Icons.save),
                      label: const Text('Сохранить'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_isEditing) {
                        setState(() {
                          _isEditing = false;
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    icon: Icon(_isEditing ? Icons.close : Icons.arrow_back),
                    label: Text(_isEditing ? 'Отмена' : 'Назад'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
