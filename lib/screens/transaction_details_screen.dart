import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../widgets/calculator_dialog.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

// Temporary Account class definition (replace with your actual Account model or import)
class Account {
  final int? id;
  final String name;

  Account({required this.id, required this.name});
}

class TransactionDetailsScreen extends StatefulWidget {
  final String id;
  final String title;
  final String subtitle;
  final String amount;
  final Color color;
  final String category;
  final String comment;

  const TransactionDetailsScreen({
    super.key,
    required this.id,
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

class _TransactionAttachment {
  final int id;
  final String fileName;
  final String filePath;
  final bool isImage;
  _TransactionAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.isImage,
  });
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
  late String _type = 'расход';
  int? selectedAccountId;
  List<Map<String, dynamic>> categories = [];
  Map<String, dynamic>? _currentCategory;

  final List<Account> accounts = []; // Добавлено: список счетов
  List<_TransactionAttachment> attachments = [];

  // Добавляем контроллер для калькулятора
  final TextEditingController _calculatorController = TextEditingController();
  String _calculatorResult = '';

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
    _selectedDateTime = _tryParseDateTime(widget.subtitle);

    _loadAccounts();
    _loadCategories();
    _loadAttachments();
  }

  Future<void> _loadAccounts() async {
    final data = await DatabaseService.getAllAccounts();
    setState(() {
      accounts.clear();
      accounts.addAll(data.map((a) => Account(id: a['id'], name: a['name'])));
    });

    // Получаем счет по account_id и тип из записи транзакции
    if (widget.id.isNotEmpty) {
      final transaction = await DatabaseService.getTransactionById(widget.id);
      if (transaction != null) {
        if (transaction['account_id'] != null) {
          final account = await DatabaseService.getAccountById(
            transaction['account_id'],
          );
          setState(() {
            selectedAccountId = account?['id'];
          });
        }
        // Всегда берём тип из базы
        setState(() {
          _type = transaction['type'];
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    final fetchedCategories = await DatabaseService.getAllCategories();
    setState(() {
      categories = List<Map<String, dynamic>>.from(fetchedCategories);
      // Находим текущую категорию
      _currentCategory = categories.firstWhere(
        (cat) => cat['name'] == _category,
        orElse:
            () => {'name': 'Неизвестно', 'icon': null, 'customIconPath': null},
      );
    });
  }

  Future<void> _loadAttachments() async {
    final attachmentsData = await DatabaseService.getAttachmentsByTransaction(
      widget.id,
    );
    setState(() {
      attachments =
          attachmentsData
              .map(
                (att) => _TransactionAttachment(
                  id: att['id'],
                  fileName: att['file_name'],
                  filePath: att['file_path'],
                  isImage: FileService.isImage(att['file_path']),
                ),
              )
              .toList();
    });
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
      Logger('TransactionDetailsScreen').warning('Ошибка парсинга даты: $e');
    }
    return null;
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMMM yyyy, HH:mm', 'ru').format(dateTime);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    _calculatorController.dispose();
    super.dispose();
  }

  Widget _getCategoryIconWidget(Map<String, dynamic>? category) {
    if (category == null) return const Icon(Icons.label, size: 32);

    if (category['customIconPath'] != null &&
        File(category['customIconPath']).existsSync()) {
      return Image.file(
        File(category['customIconPath']),
        width: 32,
        height: 32,
        fit: BoxFit.cover,
      );
    } else if (category['icon'] != null) {
      return Icon(
        IconData(category['icon'], fontFamily: 'MaterialIcons'),
        size: 32,
      );
    } else {
      return const Icon(Icons.label, size: 32);
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
      // Корректно форматируем сумму при смене типа
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      _amountController.text = amount
          .abs()
          .toStringAsFixed(2)
          .replaceAll('.', ',');
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
      locale: const Locale('ru', 'RU'), // Устанавливаем русский язык
    );
    if (!mounted) return;
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
        builder: (context, child) {
          return Localizations.override(
            context: context,
            locale: const Locale('ru', 'RU'), // Устанавливаем русский язык
            child: child,
          );
        },
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

  // Удаляем неиспользуемые методы калькулятора
  // Оставляем только форматирование суммы
  String _formatAmountWithFixedDecimals(String value) {
    if (value.isEmpty) return '0,00';
    // Удаляем все нецифровые символы, кроме запятой
    value = value.replaceAll(RegExp(r'[^\d,]'), '');
    // Заменяем все запятые на одну
    value = value.replaceAll(RegExp(r','), ',');
    // Если запятых нет, добавляем в конец
    if (!value.contains(',')) {
      value = '$value,00';
    } else {
      // Разбиваем на целую и дробную части
      final parts = value.split(',');
      // Оставляем только первые две цифры после запятой
      if (parts.length > 1) {
        value = '${parts[0]},${parts[1].padRight(2, '0').substring(0, 2)}';
      }
    }
    return value;
  }

  // Метод для вычисления результата калькулятора
  void _calculateResult() {
    try {
      final expression = _calculatorController.text.replaceAll(',', '.');
      // Используем безопасный способ вычисления выражения
      final result = _evaluateExpression(expression);
      setState(() {
        _calculatorResult = result.toStringAsFixed(2).replaceAll('.', ',');
      });
    } catch (e) {
      setState(() {
        _calculatorResult = 'Ошибка';
      });
    }
  }

  // Безопасное вычисление выражения
  double _evaluateExpression(String expression) {
    // Удаляем все пробелы
    expression = expression.replaceAll(' ', '');
    // Проверяем на допустимые символы
    if (!RegExp(r'^[\d+\-*/().]+$').hasMatch(expression)) {
      throw Exception('Недопустимые символы в выражении');
    }
    // Вычисляем выражение
    final result = _evaluate(expression);
    if (result.isInfinite || result.isNaN) {
      throw Exception('Некорректное выражение');
    }
    return result;
  }

  double _evaluate(String expression) {
    // Простая реализация для базовых операций
    // В реальном приложении лучше использовать готовую библиотеку
    final terms = expression.split(RegExp(r'[+\-]'));
    final operators =
        expression
            .split(RegExp(r'[^+\-]'))
            .where((op) => op.isNotEmpty)
            .toList();

    double result = _evaluateTerm(terms[0]);
    for (int i = 0; i < operators.length; i++) {
      if (operators[i] == '+') {
        result += _evaluateTerm(terms[i + 1]);
      } else {
        result -= _evaluateTerm(terms[i + 1]);
      }
    }
    return result;
  }

  double _evaluateTerm(String term) {
    final factors = term.split('*');
    double result = 1;
    for (final factor in factors) {
      final divisions = factor.split('/');
      double value = double.parse(divisions[0]);
      for (int i = 1; i < divisions.length; i++) {
        final divisor = double.parse(divisions[i]);
        if (divisor == 0) throw Exception('Деление на ноль');
        value /= divisor;
      }
      result *= value;
    }
    return result;
  }

  // Обновляем метод сохранения
  void _saveEdit() async {
    if (!mounted) return;
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final dateToSave =
            _selectedDateTime ??
            _tryParseDateTime(_subtitleController.text) ??
            _tryParseDateTime(widget.subtitle);

        final categoryId = _currentCategory?['id'];
        if (categoryId == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Выберите категорию')));
          return;
        }

        // Корректно парсим сумму
        final amount =
            double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
        final signedAmount = _type == 'расход' ? -amount : amount;

        final updatedTransaction = {
          'id': widget.id,
          'title': _titleController.text,
          'amount': signedAmount,
          'type': _type,
          'category_id': categoryId,
          'date': dateToSave?.toIso8601String(),
          'description': _commentController.text,
          'account_id': selectedAccountId,
        };

        await DatabaseService.updateTransaction(updatedTransaction);
        if (!mounted) return;

        // После сохранения — перезагружаем данные из базы
        final updated = await DatabaseService.getTransactionById(widget.id);
        if (updated != null) {
          setState(() {
            _type = updated['type'];
            final double newAmount =
                (updated['amount'] is String)
                    ? double.tryParse(updated['amount']) ?? 0.0
                    : (updated['amount'] as num?)?.toDouble() ?? 0.0;
            _amountController.text = newAmount
                .abs()
                .toStringAsFixed(2)
                .replaceAll('.', ',');
            _titleController.text = updated['title'] ?? '';
            _commentController.text = updated['description'] ?? '';
            selectedAccountId = updated['account_id'] as int?;
            // и другие поля при необходимости
          });
        }

        // Показываем сообщение об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Транзакция успешно сохранена'),
            backgroundColor: Colors.green,
          ),
        );

        // Возвращаемся на предыдущий экран и сигнализируем об успешном изменении
        Navigator.pop(context, true);
      } catch (e) {
        Logger(
          'TransactionDetailsScreen',
        ).severe('Ошибка при сохранении транзакции: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при сохранении: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      for (final file in result.files) {
        if (file.path != null) {
          final copiedPath = await FileService.copyToAttachments(
            File(file.path!),
          );
          // Определяем тип файла по расширению
          String fileType = '';
          final dotIndex = file.name.lastIndexOf('.');
          if (dotIndex != -1 && dotIndex < file.name.length - 1) {
            fileType = file.name.substring(dotIndex + 1).toLowerCase();
          }
          final attachmentId = await DatabaseService.insertAttachment({
            'transaction_id': int.parse(widget.id),
            'file_name': file.name,
            'file_path': copiedPath,
            'created_at': DateTime.now().toIso8601String(),
            'file_type': fileType,
            'file_size': file.size ?? 0,
          });
          setState(() {
            attachments.add(
              _TransactionAttachment(
                id: attachmentId,
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
    final attachment = attachments[index];
    await DatabaseService.deleteAttachment(attachment.id);
    await FileService.deleteFile(attachment.filePath);
    setState(() {
      attachments.removeAt(index);
    });
  }

  Future<void> _openAttachment(_TransactionAttachment att) async {
    try {
      if (Platform.isWindows) {
        // Для Windows используем Process.run для открытия файла
        final result = await Process.run('cmd', [
          '/c',
          'start',
          '',
          att.filePath,
        ]);
        if (result.exitCode != 0) {
          Logger(
            'TransactionDetailsScreen',
          ).warning('Ошибка при открытии файла через cmd: ${result.stderr}');
          // Если не удалось открыть через cmd, пробуем через url_launcher
          final uri = Uri.file(att.filePath);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Не удалось открыть файл. Проверьте, установлено ли приложение для работы с этим типом файлов.',
                ),
              ),
            );
          }
        }
      } else {
        // Для других ОС используем OpenFile
        final result = await OpenFile.open(att.filePath);
        if (result.type != ResultType.done) {
          // Если не удалось открыть через OpenFile, пробуем через url_launcher
          final uri = Uri.file(att.filePath);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Не удалось открыть файл. Проверьте, установлено ли приложение для работы с этим типом файлов.',
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      Logger(
        'TransactionDetailsScreen',
      ).warning('Ошибка при открытии файла: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка при открытии файла: $e')));
    }
  }

  Future<void> _saveAttachmentTo(_TransactionAttachment att) async {
    await FileService.saveFileWithDialog(att.filePath, att.fileName);
  }

  // Обновляем методы валидации для более информативных сообщений
  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите название операции';
    }
    if (value.length > 100) {
      return 'Название не должно превышать 100 символов (сейчас: ${value.length})';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите сумму';
    }
    // Разрешаем только числа с максимум 2 знаками после запятой
    final regex = RegExp(r'^\d+([.,]\d{0,2})?$');
    if (!regex.hasMatch(value)) {
      return 'Используйте формат: число с запятой и максимум 2 знаками после запятой (например: 1000,50)';
    }
    // Проверяем, что сумма не слишком большая
    final amount = double.tryParse(value.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      return 'Сумма должна быть больше нуля';
    }
    if (amount > 1000000000) {
      // 1 миллиард
      return 'Сумма не должна превышать 1 000 000 000 ₽';
    }
    return null;
  }

  String? _validateComment(String? value) {
    if (value == null) return null;
    if (value.length > 500) {
      return 'Комментарий не должен превышать 500 символов (сейчас: ${value.length})';
    }
    return null;
  }

  // Метод форматирования суммы с валютой
  String _formatAmount(String value) {
    if (value.isEmpty) return '';
    // Заменяем запятую на точку для корректного парсинга
    final amount = double.tryParse(value.replaceAll(',', '.'));
    if (amount == null) return value;
    // Форматируем число с двумя знаками после запятой
    return '${amount.toStringAsFixed(2)} ₽';
  }

  // --- Выделение названия сервиса из названия операции ---
  Future<String?> _extractServiceName(String title) async {
    final services = await DatabaseService.getAllServices();
    for (final service in services) {
      if (title.toLowerCase().contains(service.toLowerCase())) {
        return service;
      }
    }
    return null;
  }

  Future<List<String>> _fetchPromocodesFromBot(String service) async {
    // Примеры промокодов для популярных сервисов РФ
    final mockPromos = {
      'Яндекс.Еда': [
        'Скидка 20% — YANFOOD20',
        'Бесплатная доставка — YANDELIVERY',
        'Скидка 300₽ — EDA300',
        'Скидка 15% на первый заказ — EDAFIRST15',
        'Скидка 10% — YEDATEN',
      ],
      'Яндекс Еда': [
        'Скидка 20% — YANFOOD20',
        'Бесплатная доставка — YANDELIVERY',
        'Скидка 300₽ — EDA300',
        'Скидка 15% на первый заказ — EDAFIRST15',
        'Скидка 10% — YEDATEN',
      ],
      'Самокат': [
        'Скидка 20% — SAMOKAT20',
        'Скидка 300₽ — SAMOKAT300',
        'Бесплатная доставка — SAMOKATFREE',
      ],
      'Delivery Club': [
        'Скидка 25% — DELICLUB25',
        'Скидка 400₽ — DELI400',
        'Скидка 10% на первый заказ — DELIFIRST10',
      ],
      'ВкусВилл': ['Скидка 10% — VKUSVILL10', 'Скидка 200₽ — VKUS200'],
      'Лента': ['Скидка 5% — LENTA5', 'Скидка 300₽ — LENTA300'],
      'Перекрёсток': ['Скидка 7% — PEREK7', 'Скидка 250₽ — PEREK250'],
      'Пятёрочка': ['Скидка 5% — PYATEROCHKA5', 'Скидка 150₽ — PYAT150'],
      'Магнит': ['Скидка 5% — MAGNIT5', 'Скидка 200₽ — MAGNIT200'],
      'СберМаркет': ['Скидка 10% — SBERMARKET10', 'Скидка 300₽ — SBER300'],
      'Burger King': ['Скидка 12% — BK12', 'Скидка 180₽ — BK180'],
      'AliExpress': ['Скидка 8% — ALI8', 'Скидка 500₽ — ALI500'],
      'Ostrovok': ['Скидка 7% — OSTROVOK7', 'Скидка 1000₽ — OSTROVOK1000'],
      'Ламода': ['Скидка 10% — LAMODA10', 'Скидка 400₽ — LAMODA400'],
      'DNS': ['Скидка 5% — DNS5', 'Скидка 500₽ — DNS500'],
      'М.Видео': ['Скидка 7% — MVIDEO7', 'Скидка 1000₽ — MVIDEO1000'],
      'Эльдорадо': ['Скидка 6% — ELDORADO6', 'Скидка 800₽ — ELDORADO800'],
    };

    // Имитируем задержку сети
    await Future.delayed(const Duration(seconds: 2));

    // Возвращаем промокоды, если есть, иначе сообщение об отсутствии
    if (mockPromos.containsKey(service)) {
      return mockPromos[service]!;
    } else {
      return ['Нет актуальных промокодов.'];
    }
  }

  // TODO: Реализовать интеграцию с реальным API или Telegram-ботом для получения промокодов
  Future<List<String>> _fetchPromocodesFromRealApi(String service) async {
    // TODO: Реализовать обращение к реальному API
    return [];
  }

  void _showPromocodesDialog(List<String> promoList) {
    // Парсим строки вида "Название — ПРОМОКОД"
    final parsed =
        promoList
            .map((line) {
              final match = RegExp(r'(.+?)\s*[—-]\s*(\S+)').firstMatch(line);
              if (match != null) {
                return {
                  'title': match.group(1)!.trim(),
                  'code': match.group(2)!.trim(),
                };
              } else {
                return {'title': '', 'code': line.trim()};
              }
            })
            .where((e) => e['code'] != null && e['code']!.isNotEmpty)
            .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Промокоды'),
          content:
              promoList.isEmpty ||
                      (promoList.length == 1 &&
                          promoList[0].toLowerCase().contains(
                            'нет актуальных промокодов',
                          ))
                  ? const Text('Нет актуальных промокодов')
                  : SizedBox(
                    width: 350,
                    height: 300,
                    child: ListView.separated(
                      itemCount: parsed.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final item = parsed[i];
                        return ListTile(
                          title: Text(
                            item['title']!.isNotEmpty
                                ? item['title']!
                                : 'Промокод',
                          ),
                          subtitle: SelectableText(item['code']!),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            tooltip: 'Скопировать',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: item['code']!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Промокод скопирован!'),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование операции' : 'Детали операции'),
        leading: IconButton(
          icon: Icon(_isEditing ? Icons.close : Icons.arrow_back),
          tooltip: _isEditing ? 'Отмена' : 'Назад',
          onPressed: () {
            if (_isEditing) {
              setState(() {
                _isEditing = false;
                // Восстанавливаем исходные значения при отмене редактирования
                _category = widget.category;
                _currentCategory = categories.firstWhere(
                  (cat) => cat['name'] == _category,
                  orElse:
                      () => {
                        'name': 'Неизвестно',
                        'icon': null,
                        'customIconPath': null,
                      },
                );
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _getCategoryIconWidget(_currentCategory),
                    const SizedBox(height: 24),
                    if (_isEditing)
                      DropdownButtonFormField<int?>(
                        decoration: const InputDecoration(labelText: 'Счёт *'),
                        items:
                            accounts
                                .map(
                                  (account) => DropdownMenuItem(
                                    value: account.id,
                                    child: Text(account.name),
                                  ),
                                )
                                .toList(),
                        value: selectedAccountId,
                        onChanged: (value) {
                          setState(() {
                            selectedAccountId = value;
                          });
                        },
                        validator: (value) {
                          if (accounts.isEmpty) {
                            return 'Сначала создайте хотя бы один счёт.';
                          }
                          return value == null ? 'Выберите счёт' : null;
                        },
                      ),
                    if (!(_isEditing))
                      Text(
                        'Счёт: ${accounts.firstWhere((a) => a.id == selectedAccountId, orElse: () => Account(id: null, name: 'Неизвестно')).name}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 12),
                    _isEditing
                        ? DropdownButtonFormField<String>(
                          value: _type,
                          decoration: const InputDecoration(labelText: 'Тип'),
                          items: const [
                            DropdownMenuItem(
                              value: 'доход',
                              child: Text('Доход'),
                            ),
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
                          decoration: const InputDecoration(
                            labelText: 'Название *',
                            hintText: 'Введите название операции',
                            errorStyle: TextStyle(color: Colors.red),
                          ),
                          validator: _validateTitle,
                          maxLength: 100,
                          textCapitalization: TextCapitalization.sentences,
                          // Добавляем автофокус для подсветки ошибки при вводе
                          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        ? DropdownButtonFormField<int?>(
                          value: _currentCategory?['id'],
                          decoration: const InputDecoration(
                            labelText: 'Категория',
                          ),
                          items:
                              categories.map((category) {
                                return DropdownMenuItem<int?>(
                                  value: category['id'],
                                  child: Row(
                                    children: [
                                      _getCategoryIconWidget(category),
                                      const SizedBox(width: 8),
                                      Text(category['name']),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              final selectedCategory = categories.firstWhere(
                                (cat) => cat['id'] == value,
                                orElse:
                                    () => {
                                      'name': 'Неизвестно',
                                      'icon': null,
                                      'customIconPath': null,
                                    },
                              );
                              setState(() {
                                _currentCategory = selectedCategory;
                                _category = selectedCategory['name'];
                                _color = _getCategoryColor(_category);
                                _updateTypeFromCategory(_category);
                              });
                            }
                          },
                          validator:
                              (value) =>
                                  value == null ? 'Выберите категорию' : null,
                        )
                        : Text(
                          'Категория: $_category',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    const SizedBox(height: 8),
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
                            'Сумма',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          _isEditing
                              ? _buildAmountInput()
                              : Builder(
                                builder: (context) {
                                  final amount =
                                      double.tryParse(
                                        _amountController.text.replaceAll(
                                          ',',
                                          '.',
                                        ),
                                      ) ??
                                      0.0;
                                  final isExpense = _type == 'расход';
                                  final color =
                                      isExpense ? Colors.red : Colors.green;
                                  final formatted = NumberFormat(
                                    '##0.00',
                                    'ru_RU',
                                  ).format(amount.abs());
                                  return Text(
                                    (isExpense ? '-' : '') + formatted,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  );
                                },
                              ),
                        ],
                      ),
                    ),
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
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: 'Введите комментарий',
                                  errorStyle: TextStyle(color: Colors.red),
                                ),
                                maxLines: 3,
                                maxLength: 500,
                                validator: _validateComment,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Файлы',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (_isEditing)
                                ElevatedButton.icon(
                                  onPressed: _pickFiles,
                                  icon: const Icon(Icons.attach_file),
                                  label: const Text('Прикрепить файл'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        colorScheme.primaryContainer,
                                    foregroundColor:
                                        colorScheme.onPrimaryContainer,
                                  ),
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
                                        att.isImage
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
                                          onPressed:
                                              () => _saveAttachmentTo(att),
                                        ),
                                        if (_isEditing)
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            tooltip: 'Удалить',
                                            onPressed:
                                                () => _removeAttachment(index),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (attachments.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text(
                                'Нет прикрепленных файлов',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child:
                !_isEditing
                    ? Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _startEdit,
                            icon: const Icon(Icons.edit),
                            label: const Text('Редактировать'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _onFindPromocodesPressed,
                            icon: const Icon(Icons.local_offer),
                            label: const Text('Найти промокоды'),
                          ),
                        ),
                      ],
                    )
                    : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveEdit,
                            icon: const Icon(Icons.save),
                            label: const Text('Сохранить'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                              });
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Отмена'),
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  // Обновляем метод построения поля ввода суммы
  Widget _buildAmountInput() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Сумма',
        hintText: '0,00',
        suffixText: '₽',
        prefixIcon: const Icon(Icons.attach_money),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calculate),
          onPressed: () async {
            final result = await showDialog<String>(
              context: context,
              builder:
                  (context) => CalculatorDialog(
                    initialValue: _amountController.text,
                    onResult: (value) {
                      _amountController.text = value;
                    },
                  ),
            );
            if (result != null) {
              setState(() {
                _amountController.text = result;
              });
            }
          },
        ),
        errorStyle: const TextStyle(color: Colors.red),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: _validateAmount,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (value) {
        // Форматируем ввод с фиксированным форматом
        final formatted = _formatAmountWithFixedDecimals(value);
        if (formatted != value) {
          final cursorPos = _amountController.selection.baseOffset;
          _amountController.text = formatted;
          if (cursorPos != -1) {
            _amountController.selection = TextSelection.fromPosition(
              TextPosition(offset: cursorPos),
            );
          }
        }
      },
    );
  }

  // --- Поиск промокодов ---
  Future<void> _onFindPromocodesPressed() async {
    final service = await _extractServiceName(_titleController.text);
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось определить сервис по названию операции.'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Ищем промокоды для: $service...')));
    final promoList = await _fetchPromocodesFromBot(service);
    _showPromocodesDialog(promoList);
  }
}
