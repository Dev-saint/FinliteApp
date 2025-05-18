import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    decoration: const InputDecoration(labelText: 'Период'),
                    items: const [
                      DropdownMenuItem(value: 'месяц', child: Text('Месяц')),
                      DropdownMenuItem(value: 'неделя', child: Text('Неделя')),
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
                      DropdownMenuItem(value: 'категории', child: Text('По категориям')),
                      DropdownMenuItem(value: 'типам', child: Text('По типам операций')),
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
                child: const Text('Здесь будет диаграмма'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
