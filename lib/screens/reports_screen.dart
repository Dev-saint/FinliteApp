import 'dart:math';

import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  // Используем те же транзакции, что и на главной
  List<_Transaction> get _transactions => [
    _Transaction(
      title: 'Продукты',
      category: 'Продукты',
      date: '12 мая 2025, 14:30',
      amount: -650,
    ),
    _Transaction(
      title: 'Зарплата',
      category: 'Зарплата',
      date: '10 мая 2025, 09:00',
      amount: 15000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Группируем по категориям и считаем суммы
    final Map<String, _PieData> categoryData = {};
    for (final t in _transactions) {
      final key = t.category;
      final color = _getCategoryColor(key);
      if (!categoryData.containsKey(key)) {
        categoryData[key] = _PieData(key, 0, color);
      }
      categoryData[key] = categoryData[key]!.copyWith(
        value: categoryData[key]!.value + t.amount.abs(),
      );
    }
    final data = categoryData.values.toList();
    final total = data.fold<double>(0, (sum, d) => sum + d.value.abs());

    return Scaffold(
      appBar: AppBar(title: const Text('Отчёты')),
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Период'),
                      items: const [
                        DropdownMenuItem(value: 'месяц', child: Text('Месяц')),
                        DropdownMenuItem(
                          value: 'неделя',
                          child: Text('Неделя'),
                        ),
                        DropdownMenuItem(value: 'год', child: Text('Год')),
                      ],
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Тип'),
                      items: const [
                        DropdownMenuItem(
                          value: 'категории',
                          child: Text('По категориям'),
                        ),
                        DropdownMenuItem(
                          value: 'типам',
                          child: Text('По типам операций'),
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: _PieChartWidget(data: data, total: total),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Цвета для категорий (можно расширить)
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
}

class _Transaction {
  final String title;
  final String category;
  final String date;
  final int amount;

  _Transaction({
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
  });
}

class _PieData {
  final String label;
  final double value;
  final Color color;
  _PieData(this.label, this.value, this.color);

  _PieData copyWith({double? value}) =>
      _PieData(label, value ?? this.value, color);
}

class _PieChartWidget extends StatelessWidget {
  final List<_PieData> data;
  final double total;
  const _PieChartWidget({required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide * 0.7;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _PieChartPainter(data, total),
                child: Stack(children: _buildLabels(size, data, total)),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children:
                  data.map((d) {
                    final percent = total > 0 ? (d.value / total * 100) : 0;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 16, height: 16, color: d.color),
                        const SizedBox(width: 6),
                        Text(
                          '${d.label} (${d.value.abs().toInt()} ₽, ${percent.toStringAsFixed(1)}%)',
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ],
        );
      },
    );
  }

  // Генерация подписей процентов на диаграмме
  List<Widget> _buildLabels(double size, List<_PieData> data, double total) {
    final List<Widget> labels = [];
    double startRadian = -3.14 / 2;
    final radius = size / 2;
    for (final d in data) {
      final sweep = total > 0 ? (d.value.abs() / total) * 3.1415926535 * 2 : 0;
      final percent = total > 0 ? (d.value / total * 100) : 0;
      if (percent > 5) {
        // Показываем только если больше 5%
        final angle = startRadian + sweep / 2;
        final x = radius + (radius * 0.6) * (cos(angle));
        final y = radius + (radius * 0.6) * (sin(angle));
        labels.add(
          Positioned(
            left: x - 18,
            top: y - 10,
            child: Text(
              '${percent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.white.withAlpha((0.7 * 255).toInt()),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      }
      startRadian += sweep;
    }
    return labels;
  }
}

class _PieChartPainter extends CustomPainter {
  final List<_PieData> data;
  final double total;
  _PieChartPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;
    double startRadian = -3.14 / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final d in data) {
      final sweep = total > 0 ? (d.value.abs() / total) * 3.1415926535 * 2 : 0;
      paint.color = d.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startRadian,
        sweep.toDouble(),
        true,
        paint,
      );
      startRadian += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
