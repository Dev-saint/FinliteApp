import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Map<String, dynamic>> categories = [];
  int? selectedCategoryId; // ID выбранной категории

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final fetchedCategories = await DatabaseService.getAllCategories();
    setState(() {
      categories =
          fetchedCategories.map((category) {
            return {
              ...category,
              'name': category['name'],
              'id': category['id'],
            };
          }).toList();
    });
  }

  Future<void> _filterTransactionsByCategory(int? categoryId) async {
    // Логика фильтрации транзакций по категории
    // Например, запрос к базе данных с использованием categoryId
    setState(() {
      selectedCategoryId = categoryId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главный экран'),
        actions: [
          DropdownButton<int?>(
            value: selectedCategoryId,
            hint: const Text('Все категории'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Все категории'),
              ),
              ...categories.map((category) {
                return DropdownMenuItem<int?>(
                  value: category['id'],
                  child: Text(category['name']),
                );
              }),
            ],
            onChanged: (value) async {
              await _filterTransactionsByCategory(value);
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          selectedCategoryId == null
              ? 'Показаны все транзакции'
              : 'Показаны транзакции для категории ID: $selectedCategoryId',
        ),
      ),
    );
  }
}
