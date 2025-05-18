import 'package:flutter/material.dart';
import 'add_category_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  IconData _getCategoryIcon(String name) {
    switch (name) {
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

  void _openAddCategoryScreen(BuildContext context) {
    Navigator.of(context).push(_fadeRoute(const AddCategoryScreen()));
  }

  // Добавлено: универсальный fade route
  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder:
          (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 220),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Категории')),
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CategoryTile(
              name: 'Продукты',
              isDefault: true,
              icon: _getCategoryIcon('Продукты'),
            ),
            CategoryTile(
              name: 'Транспорт',
              isDefault: true,
              icon: _getCategoryIcon('Транспорт'),
            ),
            CategoryTile(
              name: 'Развлечения',
              isDefault: true,
              icon: _getCategoryIcon('Развлечения'),
            ),
            CategoryTile(
              name: 'Зарплата',
              isDefault: true,
              icon: _getCategoryIcon('Зарплата'),
            ),
          ],
        ),
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
  final IconData icon;

  const CategoryTile({
    super.key,
    required this.name,
    this.isDefault = false,
    this.icon = Icons.label,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(name),
      trailing:
          isDefault
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
