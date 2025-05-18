import 'package:flutter/material.dart';
import 'add_category_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  void _openAddCategoryScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Категории')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          CategoryTile(name: 'Продукты', isDefault: true),
          CategoryTile(name: 'Транспорт', isDefault: true),
          CategoryTile(name: 'Развлечения', isDefault: true),
          CategoryTile(name: 'Зарплата', isDefault: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddCategoryScreen(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  final String name;
  final bool isDefault;

  const CategoryTile({
    super.key,
    required this.name,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.label),
      title: Text(name),
      trailing: isDefault
          ? null
          : Wrap(
              spacing: 8,
              children: const [
                Icon(Icons.edit, color: Colors.grey),
                Icon(Icons.delete, color: Colors.redAccent),
              ],
            ),
    );
  }
}
