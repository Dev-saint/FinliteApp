import 'package:flutter/material.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  CategoriesScreenState createState() => CategoriesScreenState();
}

class CategoriesScreenState extends State<CategoriesScreen> {
  final List<CategoryTile> categories = [];

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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CategoryTile(
                    name: 'Продукты',
                    isDefault: true,
                    icon: _getCategoryIcon('Продукты'),
                    type: 'расход',
                    onEdit: null,
                  ),
                  CategoryTile(
                    name: 'Транспорт',
                    isDefault: true,
                    icon: _getCategoryIcon('Транспорт'),
                    type: 'расход',
                    onEdit: null,
                  ),
                  CategoryTile(
                    name: 'Развлечения',
                    isDefault: true,
                    icon: _getCategoryIcon('Развлечения'),
                    type: 'расход',
                    onEdit: null,
                  ),
                  CategoryTile(
                    name: 'Зарплата',
                    isDefault: true,
                    icon: _getCategoryIcon('Зарплата'),
                    type: 'доход',
                    onEdit: null,
                  ),
                  // Пример пользовательской категории (можно удалить)
                  CategoryTile(
                    name: 'Моя категория',
                    isDefault: false,
                    icon: Icons.cake,
                    type: 'доход',
                    customIconPath: null,
                    onEdit: (context, tile) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => EditCategoryScreen(
                                initialName: tile.name,
                                initialIcon: tile.icon,
                                initialType: tile.type,
                                initialCustomIconPath: tile.customIconPath,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // --- Кнопка добавления категории под списком ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Добавить категорию'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _openAddCategoryScreen(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  final String name;
  final bool isDefault;
  final IconData icon;
  final String type;
  final String? customIconPath;
  final void Function(BuildContext, CategoryTile)? onEdit;

  const CategoryTile({
    super.key,
    required this.name,
    this.isDefault = false,
    this.icon = Icons.label,
    this.type = 'расход',
    this.customIconPath,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          customIconPath != null
              ? (customIconPath!.startsWith('assets/')
                  ? Image.asset(customIconPath!, width: 32, height: 32)
                  : Icon(Icons.image, size: 32))
              : Icon(icon),
      title: Text(name),
      subtitle: Text('Тип: $type'),
      trailing:
          isDefault
              ? null
              : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey, size: 24),
                    onPressed:
                        onEdit != null ? () => onEdit!(context, this) : null,
                    tooltip: 'Редактировать',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.delete, color: Colors.redAccent, size: 24),
                ],
              ),
    );
  }
}
