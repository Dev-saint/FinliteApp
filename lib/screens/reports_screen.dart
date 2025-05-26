import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedPeriod = 'Месяц';
  String selectedReportType = '📊 Расходы по категориям';
  DateTimeRange? customDateRange;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> accounts = [];
  Map<String, Color> categoryColors = {};
  bool generatePressed = false;

  final List<String> reportTypes = [
    '📊 Расходы по категориям',
    '📊 Доходы по категориям',
    '📊 Распределение по счетам',
    '📉 Сравнение доходов/расходов по датам',
    '📉 Сравнение по счетам',
    '📉 Сравнение категорий',
  ];

  final List<String> periodOptions = [
    'Сегодня',
    'Неделя',
    'Месяц',
    'Год',
    'Произвольный период',
    'Все',
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final fetchedTransactions = await DatabaseService.getAllTransactions();
    final fetchedCategories = await DatabaseService.getAllCategories();
    final fetchedAccounts = await DatabaseService.getAllAccounts();
    setState(() {
      transactions = fetchedTransactions;
      categories = fetchedCategories;
      accounts = fetchedAccounts;
      generatePressed = false;
    });
  }

  bool _isInSelectedPeriod(DateTime date) {
    final now = DateTime.now();
    switch (selectedPeriod) {
      case 'Сегодня':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case 'Неделя':
        return date.isAfter(now.subtract(const Duration(days: 7)));
      case 'Месяц':
        return date.year == now.year && date.month == now.month;
      case 'Год':
        return date.year == now.year;
      case 'Произвольный период':
        if (customDateRange == null) return true;
        return date.isAfter(
              customDateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            date.isBefore(customDateRange!.end.add(const Duration(days: 1)));
      default:
        return true;
    }
  }

  Widget _buildReportChart() {
    switch (selectedReportType) {
      case '📊 Расходы по категориям':
        return _buildPieChart(false);
      case '📊 Доходы по категориям':
        return _buildPieChart(true);
      case '📊 Распределение по счетам':
        return _buildAccountsPieChart();
      case '📉 Сравнение доходов/расходов по датам':
        return _buildBarChart();
      case '📉 Сравнение по счетам':
        return _buildAccountComparisonChart();
      case '📉 Сравнение категорий':
        return _buildCategoryComparisonChart();
      default:
        return const Center(child: Text('Тип отчета в разработке'));
    }
  }

  Widget _buildPieChart(bool isIncome) {
    final filtered = transactions.where((tx) {
      final date = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
      final amount = tx['amount'];
      return _isInSelectedPeriod(date) &&
          ((isIncome && amount > 0) || (!isIncome && amount < 0));
    });

    final Map<String, int> categoryTotals = {};
    for (var tx in filtered) {
      final dynamic rawCategoryId = tx['category'] ?? tx['categoryId'];
      final int? categoryId =
          rawCategoryId is String ? int.tryParse(rawCategoryId) : rawCategoryId;
      final category = categories.firstWhere(
        (cat) => cat['id'] == categoryId,
        orElse: () => {'name': 'Неизвестно'},
      );
      final name = category['name'];
      categoryTotals[name] =
          (categoryTotals[name] ?? 0) + (tx['amount'] as num).abs().toInt();
    }

    final total = categoryTotals.values.fold(0, (a, b) => a + b);
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
    ];
    int colorIndex = 0;
    categoryColors.clear();

    final sections =
        categoryTotals.entries.map((e) {
          final color = colors[colorIndex++ % colors.length];
          categoryColors[e.key] = color;
          final percentage = (e.value / total * 100).toStringAsFixed(1);
          return PieChartSectionData(
            color: color,
            value: e.value.toDouble(),
            title: '$percentage%',
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            radius: 100,
          );
        }).toList();

    return LayoutBuilder(
      builder:
          (context, constraints) => Column(
            children: [
              SizedBox(
                height: constraints.maxHeight * 0.7,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(enabled: true),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children:
                    categoryColors.entries
                        .map(
                          (e) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 12, height: 12, color: e.value),
                              const SizedBox(width: 6),
                              Text(e.key),
                            ],
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
    );
  }

  Widget _buildAccountsPieChart() {
    final Map<String, int> accountTotals = {};
    for (var tx in transactions) {
      final date = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
      if (!_isInSelectedPeriod(date)) continue;
      final accId = tx['accountId'];
      final account = accounts.firstWhere(
        (a) => a['id'] == accId,
        orElse: () => {'name': 'Неизвестно'},
      );
      final name = account['name'];
      accountTotals[name] =
          (accountTotals[name] ?? 0) + (tx['amount'] as num).abs().toInt();
    }

    final total = accountTotals.values.fold(0, (a, b) => a + b);
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
    ];
    int colorIndex = 0;

    final sections =
        accountTotals.entries.map((e) {
          final color = colors[colorIndex++ % colors.length];
          return PieChartSectionData(
            color: color,
            value: e.value.toDouble(),
            title: '${(e.value / total * 100).toStringAsFixed(1)}%',
            radius: 100,
          );
        }).toList();

    return PieChart(
      PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 2),
    );
  }

  Widget _buildBarChart() {
    final Map<String, double> income = {}, expense = {};
    for (var tx in transactions) {
      final date = DateTime.tryParse(tx['date'] ?? '');
      if (date == null || !_isInSelectedPeriod(date)) continue;
      final key = DateFormat('dd.MM').format(date);
      final amount = tx['amount']?.toDouble() ?? 0;
      if (amount >= 0) {
        income[key] = (income[key] ?? 0) + amount;
      } else {
        expense[key] = (expense[key] ?? 0) + amount.abs();
      }
    }

    final allDates = {...income.keys, ...expense.keys}.toList()..sort();
    final bars = <BarChartGroupData>[];
    for (int i = 0; i < allDates.length; i++) {
      final key = allDates[i];
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            if (income.containsKey(key))
              BarChartRodData(
                toY: income[key]!,
                color: Colors.green,
                width: 12,
              ),
            if (expense.containsKey(key))
              BarChartRodData(toY: expense[key]!, color: Colors.red, width: 12),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: bars,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= allDates.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    allDates[index],
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget:
                  (value, _) => Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  Widget _buildAccountComparisonChart() {
    final Map<String, double> balances = {};
    for (var tx in transactions) {
      final date = DateTime.tryParse(tx['date'] ?? '');
      if (date == null || !_isInSelectedPeriod(date)) continue;
      final accId = tx['accountId'];
      final account = accounts.firstWhere(
        (a) => a['id'] == accId,
        orElse: () => {'name': 'Неизвестно'},
      );
      final name = account['name'];
      balances[name] = (balances[name] ?? 0) + (tx['amount'] as num).toDouble();
    }

    final labels = balances.keys.toList();
    final bars =
        labels.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: balances[e.value]!,
                color: Colors.blue,
                width: 12,
              ),
            ],
          );
        }).toList();

    return BarChart(
      BarChartData(
        barGroups: bars,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox();
                }
                return Text(
                  labels[index],
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget:
                  (value, _) => Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryComparisonChart() {
    final Map<String, double> totals = {};
    for (var tx in transactions) {
      final date = DateTime.tryParse(tx['date'] ?? '');
      if (date == null || !_isInSelectedPeriod(date)) continue;
      final categoryId = tx['category'] ?? tx['categoryId'];
      final category = categories.firstWhere(
        (c) => c['id'].toString() == categoryId.toString(),
        orElse: () => {'name': 'Неизвестно'},
      );
      final name = category['name'];
      totals[name] =
          (totals[name] ?? 0) + (tx['amount'] as num).abs().toDouble();
    }

    final labels = totals.keys.toList();
    final bars =
        labels.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: totals[e.value]!,
                color: Colors.deepPurple,
                width: 12,
              ),
            ],
          );
        }).toList();

    return BarChart(
      BarChartData(
        barGroups: bars,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox();
                }
                return Text(
                  labels[index],
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget:
                  (value, _) => Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectCustomDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (range != null) {
      setState(() {
        customDateRange = range;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeeklyReport = selectedReportType == '📈 Баланс по дням';

    return Scaffold(
      appBar: AppBar(title: const Text('Отчёты')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedPeriod,
                    decoration: const InputDecoration(labelText: 'Период'),
                    items:
                        isWeeklyReport
                            ? [
                              const DropdownMenuItem(
                                value: 'Неделя',
                                child: Text('Неделя'),
                              ),
                            ]
                            : periodOptions
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                    onChanged:
                        isWeeklyReport
                            ? null
                            : (value) {
                              if (value == 'Произвольный период') {
                                _selectCustomDateRange();
                              }
                              setState(() => selectedPeriod = value!);
                            },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedReportType,
                    decoration: const InputDecoration(labelText: 'Тип отчета'),
                    items:
                        reportTypes
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged:
                        (value) => setState(() {
                          selectedReportType = value!;
                          generatePressed = false;
                        }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => setState(() => generatePressed = true),
                child: const Text('Построить отчет'),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  generatePressed
                      ? _buildReportChart()
                      : const Center(
                        child: Text(
                          'Выберите параметры и нажмите "Построить отчет"',
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
