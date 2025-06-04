import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для TextInputFormatter
import 'package:intl/intl.dart';
import '../services/database_service.dart';

// Класс DateInputFormatter вынесен за пределы ReportsScreen
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Удаляем все символы, кроме цифр
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 4) {
        buffer.write('.'); // Добавляем разделитель
      }
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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
  int? touchedIndex;
  int _touchedIncomeIndex = -1;
  int _touchedExpenseIndex = -1;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Каждый раз при возврате на экран отчётов обновляем данные
    _loadAll();
  }

  Future<void> _loadAll() async {
    final fetchedTransactions = await DatabaseService.getAllTransactions();
    final fetchedCategories = await DatabaseService.getAllCategories();
    final fetchedAccounts = await DatabaseService.getAllAccounts();
    // Диагностика структуры транзакции
    print('Пример транзакции:');
    print(
      fetchedTransactions.isNotEmpty ? fetchedTransactions.first : 'нет данных',
    );
    setState(() {
      transactions = fetchedTransactions;
      categories = fetchedCategories;
      accounts = fetchedAccounts;
      generatePressed = false;
    });
  }

  List<PieChartSectionData> buildSections(Map<String, int> data) {
    final total = data.values.fold(0, (a, b) => a + b);
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

    return data.entries.map((e) {
      final color = colors[colorIndex++ % colors.length];
      final percent =
          total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
      return PieChartSectionData(
        color: color,
        value: e.value.toDouble(),
        title: '$percent%',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        radius: 100,
      );
    }).toList();
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
    if (selectedPeriod == 'Произвольный период' && customDateRange == null) {
      return const Center(
        child: Text('Выберите произвольный период для отображения данных'),
      );
    }

    // Проверка наличия данных для выбранного периода
    final hasData = transactions.any((tx) {
      final date = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
      return _isInSelectedPeriod(date);
    });

    if (!hasData) {
      return const Center(
        child: Text('Нет данных для отображения за выбранный период'),
      );
    }

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
      final amount = tx['amount'] as num;
      return _isInSelectedPeriod(date) &&
          ((isIncome && amount > 0) || (!isIncome && amount < 0));
    });

    if (filtered.isEmpty) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    final Map<String, double> categoryTotals = {};
    for (var tx in filtered) {
      final dynamic rawCategoryId =
          tx['category_id'] ?? tx['categoryId'] ?? tx['category'];
      final int? categoryId =
          rawCategoryId is String ? int.tryParse(rawCategoryId) : rawCategoryId;
      final category = categories.firstWhere(
        (cat) => cat['id'] == categoryId,
        orElse: () => {'name': 'Неизвестно'},
      );
      final name = category['name'];
      categoryTotals[name] =
          (categoryTotals[name] ?? 0) + (tx['amount'] as num).abs().toDouble();
    }

    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
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
            value: e.value,
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
                    sections:
                        sections.asMap().entries.map((entry) {
                          final index = entry.key;
                          final data = entry.value;
                          final isTouched = touchedIndex == index;
                          return data.copyWith(
                            radius: isTouched ? 110 : 100,
                            title:
                                isTouched
                                    ? '${data.value.toStringAsFixed(2)} ₽'
                                    : data.title,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                        }).toList(),
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            touchedIndex = null;
                          } else {
                            touchedIndex =
                                response.touchedSection!.touchedSectionIndex;
                          }
                        });
                      },
                    ),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children:
                    categoryColors.entries.map((e) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 12, color: e.value),
                          const SizedBox(width: 6),
                          Text(e.key),
                        ],
                      );
                    }).toList(),
              ),
            ],
          ),
    );
  }

  Widget _buildAccountsPieChart() {
    final Map<String, double> incomeMap = {}, expenseMap = {};
    final Map<String, Color> accountColors = {};

    for (var tx in transactions) {
      final date = DateTime.tryParse(tx['date'] ?? '');
      if (date == null || !_isInSelectedPeriod(date)) continue;

      final accId = tx['account_id'];
      final account = accounts.firstWhere(
        (a) => a['id'] == accId,
        orElse: () => {'name': 'Неизвестно'},
      );
      final name = account['name'] ?? 'Неизвестно';

      final amount = tx['amount'] as num;
      if (amount >= 0) {
        incomeMap[name] = (incomeMap[name] ?? 0) + amount.toDouble();
      } else {
        expenseMap[name] = (expenseMap[name] ?? 0) + amount.abs().toDouble();
      }
    }

    if (incomeMap.isEmpty && expenseMap.isEmpty) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
    ];

    Widget buildPie(Map<String, double> data, bool isIncome) {
      final total = data.values.fold(0.0, (a, b) => a + b);
      final touchedIndex =
          isIncome ? _touchedIncomeIndex : _touchedExpenseIndex;

      int index = 0;
      accountColors.clear();
      final sections =
          data.entries.map((e) {
            final i = index++;
            final color = colors[i % colors.length];
            accountColors[e.key] = color;
            final isTouched = i == touchedIndex;
            return PieChartSectionData(
              color: color,
              value: e.value,
              title:
                  isTouched
                      ? ''
                      : '${(e.value / total * 100).toStringAsFixed(1)}%',
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              radius: isTouched ? 100 : 85,
              badgeWidget:
                  isTouched
                      ? Text(
                        '${e.value.toStringAsFixed(2)} ₽',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            );
          }).toList();

      return Column(
        children: [
          SizedBox(
            width: 300,
            height: 250,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        if (isIncome) {
                          _touchedIncomeIndex = -1;
                        } else {
                          _touchedExpenseIndex = -1;
                        }
                      } else {
                        if (isIncome) {
                          _touchedIncomeIndex =
                              response.touchedSection!.touchedSectionIndex;
                        } else {
                          _touchedExpenseIndex =
                              response.touchedSection!.touchedSectionIndex;
                        }
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children:
                accountColors.entries.map((e) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 12, color: e.value),
                      const SizedBox(width: 6),
                      Text(e.key),
                    ],
                  );
                }).toList(),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Column(
            children: [
              const Text(
                'Доходы',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              buildPie(incomeMap, true),
            ],
          ),
          const SizedBox(width: 36),
          Column(
            children: [
              const Text(
                'Расходы',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              buildPie(expenseMap, false),
            ],
          ),
        ],
      ), //Если ты будешь менять эту строку, не меняй запятую на точку с запятой!!! И не стирай этот комментарий!!!
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

    if (income.isEmpty && expense.isEmpty) {
      return const Center(child: Text('Нет данных для отображения'));
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

    // Если дат много, делаем горизонтальный скролл
    final chartWidth = allDates.length > 7 ? allDates.length * 60.0 : null;

    // Найти максимум для maxY
    double maxY = 0;
    for (final bar in bars) {
      for (final rod in bar.barRods) {
        if (rod.toY > maxY) maxY = rod.toY;
      }
    }
    if (maxY < 100) {
      maxY += 10;
    } else {
      maxY += maxY * 0.1;
    }

    // Рассчитываем шаг для подписей оси Y
    double interval =
        maxY <= 10
            ? 2
            : maxY <= 50
            ? 5
            : maxY <= 100
            ? 10
            : (maxY / 6).roundToDouble();

    final chart = SizedBox(
      width: chartWidth,
      child: BarChart(
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
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      allDates[index],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: false,
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
                      formatShortNumber(value.toDouble()),
                      style: const TextStyle(fontSize: 14),
                    ),
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barTouchData: BarTouchData(
            enabled: generatePressed,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (rod.toY == 0 || rod.toY.isNaN) {
                  return null;
                }
                final isIncome = rod.color == Colors.green;
                final sign = isIncome ? '+' : '-';
                return BarTooltipItem(
                  '$sign${rod.toY.abs().toStringAsFixed(2)} ₽',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          maxY: maxY,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child:
          allDates.length > 7
              ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: chart,
              )
              : chart,
    );
  }

  Widget _buildAccountComparisonChart() {
    final Map<String, double> balances = {};
    for (var tx in transactions) {
      final date = DateTime.tryParse(tx['date'] ?? '');
      if (date == null || !_isInSelectedPeriod(date)) continue;
      final accId = tx['account_id'];
      final account = accounts.firstWhere(
        (a) => a['id'] == accId,
        orElse: () => {'name': 'Неизвестно'},
      );
      final name = account['name'];
      balances[name] = (balances[name] ?? 0) + (tx['amount'] as num).toDouble();
    }

    if (balances.isEmpty) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    final labels = balances.keys.toList();
    final bars =
        labels.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: balances[e.value]!,
                color: balances[e.value]! >= 0 ? Colors.green : Colors.red,
                width: 12,
              ),
            ],
          );
        }).toList();

    final minValue = balances.values.reduce((a, b) => a < b ? a : b);
    final maxValue = balances.values.reduce((a, b) => a > b ? a : b);
    final hasNegative = minValue < 0;
    final minY = hasNegative ? (minValue * 1.1).floorToDouble() : 0.0;
    final maxY = (maxValue * 1.1).ceilToDouble();
    final range = (maxY - minY).abs();
    double interval;
    if (range <= 10)
      interval = 2;
    else if (range <= 50)
      interval = 5;
    else if (range <= 100)
      interval = 10;
    else
      interval = (range / 6).ceilToDouble();

    return BarChart(
      BarChartData(
        barGroups: bars,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) {
            if (value == 0) {
              return FlLine(color: Colors.black, strokeWidth: 2);
            }
            return FlLine(color: Colors.grey, strokeWidth: 0.5);
          },
        ),
        barTouchData: BarTouchData(
          enabled: generatePressed,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (rod.toY == 0 || rod.toY.isNaN) {
                return null;
              }
              if (rod.toY < 0) {
                return BarTooltipItem(
                  '-${rod.toY.abs().toStringAsFixed(2)} ₽',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              } else {
                return BarTooltipItem(
                  '${rod.toY.abs().toStringAsFixed(2)} ₽',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    labels[index],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              },
              reservedSize: 60,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: interval,
              getTitlesWidget: (value, _) {
                // Убираем дублирующиеся подписи
                if ((value - minY) % interval != 0 &&
                    value != maxY &&
                    value != minY) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    formatShortNumber(value, digits: 1),
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: Colors.black, width: 1),
            bottom: BorderSide(color: Colors.black, width: 1),
          ),
        ),
        baselineY: 0,
        minY: minY,
        maxY: maxY,
      ),
    );
  }

  Widget _buildCategoryComparisonChart() {
    final Map<String, double> totals = {};
    for (var tx in transactions) {
      final date = DateTime.tryParse(tx['date'] ?? '');
      if (date == null || !_isInSelectedPeriod(date)) continue;
      final dynamic rawCategoryId =
          tx['category_id'] ?? tx['categoryId'] ?? tx['category'];
      final int? categoryId =
          rawCategoryId is String ? int.tryParse(rawCategoryId) : rawCategoryId;
      final category = categories.firstWhere(
        (cat) => cat['id'] == categoryId,
        orElse: () => {'name': 'Неизвестно'},
      );
      final name = category['name'];
      totals[name] = (totals[name] ?? 0) + (tx['amount'] as num).toDouble();
    }

    if (totals.isEmpty) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    final labels = totals.keys.toList();
    final bars =
        labels.asMap().entries.map((e) {
          final value = totals[e.value]!;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: value.abs(), // Всегда вверх
                color:
                    value >= 0
                        ? Colors.deepPurple
                        : Colors.red, // Цвет зависит от значения
                width: 12,
              ),
            ],
          );
        }).toList();

    // Найти максимум для maxY
    double maxY = 0;
    for (final bar in bars) {
      for (final rod in bar.barRods) {
        if (rod.toY > maxY) maxY = rod.toY;
      }
    }
    if (maxY < 100) {
      maxY += 10;
    } else {
      maxY += maxY * 0.1;
    }

    // Рассчитываем шаг для подписей оси Y
    double interval =
        maxY <= 10
            ? 2
            : maxY <= 50
            ? 5
            : maxY <= 100
            ? 10
            : (maxY / 6).roundToDouble();

    return BarChart(
      BarChartData(
        barGroups: bars,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(show: true, drawHorizontalLine: true),
        barTouchData: BarTouchData(
          enabled: generatePressed,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (rod.toY == 0 || rod.toY.isNaN) {
                return null; // Не показываем tooltip
              }
              final originalValue = totals[labels[group.x.toInt()]]!;
              final isIncome = originalValue >= 0;
              final sign = isIncome ? '+' : '-';
              return BarTooltipItem(
                '$sign${originalValue.abs().toStringAsFixed(2)} ₽',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              interval: interval,
              getTitlesWidget: (value, _) {
                // Не выводим дублирующееся maxY
                if ((maxY - value).abs() < interval / 2 && value != maxY) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: Colors.black, width: 1),
            bottom: BorderSide(color: Colors.black, width: 1),
          ),
        ),
        minY: 0, // Минимальное значение Y всегда 0
        maxY: maxY,
      ),
    );
  }

  Future<void> _selectCustomDateRange() async {
    final startController = TextEditingController();
    final endController = TextEditingController();

    if (customDateRange != null) {
      startController.text = DateFormat(
        'dd.MM.yyyy',
      ).format(customDateRange!.start);
      endController.text = DateFormat(
        'dd.MM.yyyy',
      ).format(customDateRange!.end);
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выберите произвольный период'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startController,
                decoration: const InputDecoration(labelText: 'Начальная дата'),
                inputFormatters: [DateInputFormatter()],
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: endController,
                decoration: const InputDecoration(labelText: 'Конечная дата'),
                inputFormatters: [DateInputFormatter()],
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                try {
                  final startDate = DateFormat(
                    'dd.MM.yyyy',
                  ).parse(startController.text);
                  final endDate = DateFormat(
                    'dd.MM.yyyy',
                  ).parse(endController.text);

                  if (startDate.isAfter(endDate)) {
                    throw Exception(
                      'Начальная дата не может быть позже конечной',
                    );
                  }

                  setState(() {
                    customDateRange = DateTimeRange(
                      start: startDate,
                      end: endDate,
                    );
                  });

                  Navigator.of(context).pop();
                } catch (e) {
                  debugPrint('Ошибка при вводе дат: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите корректные даты')),
                  );
                }
              },
              child: const Text('Применить'),
            ),
          ],
        );
      },
    );
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
                              setState(() {
                                selectedPeriod = value!;
                                generatePressed =
                                    false; // Сбрасываем флаг при изменении периода
                              });
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
                          generatePressed =
                              false; // Сбрасываем флаг при изменении типа отчета
                        }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  await _loadAll();
                  setState(() => generatePressed = true);
                },
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

// Функция для сокращения больших чисел (например, 3000000 -> 3kk)
String formatShortNumber(num value, {int digits = 1}) {
  if (value.abs() >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(digits)}kk';
  } else if (value.abs() >= 1000) {
    return '${(value / 1000).toStringAsFixed(digits)}k';
  } else {
    return value.toStringAsFixed(0);
  }
}
