import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculatorDialog extends StatefulWidget {
  final String initialValue;
  final Function(String) onResult;

  const CalculatorDialog({
    super.key,
    this.initialValue = '0,00',
    required this.onResult,
  });

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _displayController = TextEditingController();
  String _currentExpression = '';
  String _lastResult = '';

  @override
  void initState() {
    super.initState();
    _displayController.text = widget.initialValue;
    _lastResult = widget.initialValue;
    // Фокусируем для захвата клавиш
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _displayController.dispose();
    super.dispose();
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey;
      final char = event.character;
      if (key == LogicalKeyboardKey.enter) {
        _onCalculate();
      } else if (key == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
      } else if (key == LogicalKeyboardKey.backspace) {
        _onDelete();
      } else if (key == LogicalKeyboardKey.delete) {
        _onClear();
      } else if (char != null) {
        if (RegExp(r'[0-9]').hasMatch(char)) {
          _onDigitPress(char);
        } else if (char == ',' || char == '.') {
          _onDecimalPress();
        } else if ('+-*/'.contains(char)) {
          _onOperatorPress(
            char == '*'
                ? '*'
                : char == '/'
                ? '/'
                : char,
          );
        }
      }
    }
  }

  void _onDigitPress(String digit) {
    setState(() {
      if (_currentExpression == '0' || _currentExpression == _lastResult) {
        _currentExpression = digit;
      } else {
        _currentExpression += digit;
      }
      _displayController.text = _formatNumber(_currentExpression);
    });
  }

  void _onOperatorPress(String operator) {
    setState(() {
      if (_currentExpression.isNotEmpty) {
        if (_currentExpression == _lastResult) {
          _currentExpression = _lastResult;
        }
        _currentExpression += operator;
        _displayController.text = _formatNumber(_currentExpression);
      }
    });
  }

  void _onDecimalPress() {
    setState(() {
      if (_currentExpression.isEmpty || _currentExpression == _lastResult) {
        _currentExpression = '0,';
      } else if (!_currentExpression.contains(',')) {
        _currentExpression += ',';
      }
      _displayController.text = _formatNumber(_currentExpression);
    });
  }

  void _onClear() {
    setState(() {
      _currentExpression = '';
      _displayController.text = '0,00';
    });
  }

  void _onDelete() {
    setState(() {
      if (_currentExpression.isNotEmpty && _currentExpression != _lastResult) {
        _currentExpression = _currentExpression.substring(
          0,
          _currentExpression.length - 1,
        );
        if (_currentExpression.isEmpty) {
          _currentExpression = '0';
        }
        _displayController.text = _formatNumber(_currentExpression);
      }
    });
  }

  void _onCalculate() {
    try {
      final expression = _currentExpression.replaceAll(',', '.');
      final result = _evaluateExpression(expression);
      setState(() {
        _lastResult = result.toStringAsFixed(2).replaceAll('.', ',');
        _currentExpression = _lastResult;
        _displayController.text = _lastResult;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка вычисления: $e')));
    }
  }

  String _formatNumber(String value) {
    if (value.isEmpty) return '0,00';
    if (value == _lastResult) return value;

    // Удаляем все нецифровые символы, кроме запятой и операторов
    value = value.replaceAll(RegExp(r'[^\d,+\-*/]'), '');

    // Если это выражение, не форматируем
    if (value.contains(RegExp(r'[+\-*/]'))) {
      return value;
    }

    // Форматируем число
    if (!value.contains(',')) {
      return '$value,00';
    }

    final parts = value.split(',');
    if (parts.length > 1) {
      return '${parts[0]},${parts[1].padRight(2, '0').substring(0, 2)}';
    }

    return value;
  }

  double _evaluateExpression(String expression) {
    expression = expression.replaceAll(' ', '');
    if (!RegExp(r'^[\d+\-*/().]+$').hasMatch(expression)) {
      throw Exception('Недопустимые символы в выражении');
    }

    final result = _evaluate(expression);
    if (result.isInfinite || result.isNaN) {
      throw Exception('Некорректное выражение');
    }
    return result;
  }

  double _evaluate(String expression) {
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

  @override
  Widget build(BuildContext context) {
    final buttonRows = [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', ',', '=', ''],
    ];
    final buttonActions = <String, VoidCallback>{
      'C': _onClear,
      '⌫': _onDelete,
      '%': () => _onOperatorPress('%'),
      '÷': () => _onOperatorPress('/'),
      '×': () => _onOperatorPress('*'),
      '-': () => _onOperatorPress('-'),
      '+': () => _onOperatorPress('+'),
      '=': _onCalculate,
      ',': _onDecimalPress,
    };
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: RawKeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKey: _handleKey,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _displayController,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 24),
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Table(
                      defaultColumnWidth: const FixedColumnWidth(56),
                      children:
                          buttonRows.map((row) {
                            return TableRow(
                              children:
                                  row.map((label) {
                                    if (label.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    if (RegExp(r'^[0-9]$').hasMatch(label)) {
                                      return _buildNumPadButton(
                                        label,
                                        onPressed: () => _onDigitPress(label),
                                      );
                                    } else if (buttonActions.containsKey(
                                      label,
                                    )) {
                                      return _buildNumPadButton(
                                        label,
                                        onPressed: buttonActions[label],
                                      );
                                    } else {
                                      return const SizedBox.shrink();
                                    }
                                  }).toList(),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          widget.onResult(_displayController.text);
                          Navigator.pop(context);
                        },
                        child: const Text('Использовать'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumPadButton(
    String text, {
    VoidCallback? onPressed,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: SizedBox(
        width: 48,
        height: 48,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.all(0),
            shape: const CircleBorder(),
          ),
          child: Text(text, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}
