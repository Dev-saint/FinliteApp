import 'package:flutter/material.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';
import '../../services/database_service.dart';
import 'dart:io';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  CategoriesScreenState createState() => CategoriesScreenState();
}

class CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> categories = [];

  void _openAddCategoryScreen(BuildContext context) async {
    final result = await Navigator.of(
      context,
    ).push(_fadeRoute(const AddCategoryScreen()));
    if (result == true) {
      await _initializeCategories(); // Обновляем список категорий после добавления
    }
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
  void initState() {
    super.initState();
    _initializeCategories();
  }

  Future<void> _initializeCategories() async {
    await DatabaseService.ensureDefaultCategories(); // Убедиться, что предопределенные категории добавлены
    final fetchedCategories =
        await DatabaseService.getAllCategories(); // Получаем категории из базы
    setState(() {
      categories =
          fetchedCategories.map((category) {
            return {
              ...category,
              'isDefault':
                  category['isDefault'] == 1, // Преобразуем 1/0 в true/false
              'icon':
                  category['icon'] != null
                      ? IconData(category['icon'], fontFamily: 'MaterialIcons')
                      : Icons.label, // Устанавливаем иконку по умолчанию
            };
          }).toList();

      // Сортируем категории: сначала предопределенные, затем пользовательские, внутри групп по алфавиту
      categories.sort((a, b) {
        if (a['isDefault'] != b['isDefault']) {
          return b['isDefault']
              ? 1
              : -1; // Предопределенные категории идут первыми
        }
        return a['name'].toString().compareTo(
          b['name'].toString(),
        ); // Сортировка по алфавиту
      });
    });
  }

  Future<void> _deleteCategory(int categoryId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Удалить категорию'),
            content: const Text(
              'Вы уверены, что хотите удалить эту категорию?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Удалить'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await DatabaseService.deleteCategory(
        categoryId,
      ); // Удаляем категорию из базы
      await _initializeCategories(); // Обновляем список категорий
    }
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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryTile(
                    name: category['name'],
                    isDefault:
                        category['isDefault'], // Поле теперь корректно обрабатывается
                    icon: category['icon'],
                    type: category['type'],
                    customIconPath: category['customIconPath'],
                    onEdit:
                        category['isDefault']
                            ? null // Убираем кнопку редактирования для предопределенных категорий
                            : (context, tile) async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => EditCategoryScreen(
                                        categoryId: category['id'],
                                        initialName: category['name'],
                                        initialIcon: category['icon'],
                                        initialType: category['type'],
                                        initialCustomIconPath:
                                            category['customIconPath'],
                                      ),
                                ),
                              );
                              if (result == true) {
                                await _initializeCategories(); // Обновляем список категорий после редактирования
                              }
                            },
                    onDelete:
                        category['isDefault']
                            ? null // Убираем кнопку удаления для предопределенных категорий
                            : () => _deleteCategory(category['id']),
                  );
                },
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
  final VoidCallback? onDelete;

  const CategoryTile({
    super.key,
    required this.name,
    this.isDefault = false,
    this.icon = Icons.label,
    this.type = 'расход',
    this.customIconPath,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          customIconPath != null && File(customIconPath!).existsSync()
              ? Image.file(
                File(customIconPath!),
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              )
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
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.grey,
                        size: 24,
                      ),
                      onPressed: () => onEdit!(context, this),
                      tooltip: 'Редактировать',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.redAccent,
                        size: 24,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Удалить',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
    );
  }
}
