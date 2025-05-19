class Category {
  final int? id;
  final String name;
  final String type; // 'доход' или 'расход'
  final int? icon; // хранить код иконки или null
  final String? customIconPath;

  Category({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.customIconPath,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'customIconPath': customIconPath,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as int?,
      customIconPath: map['customIconPath'] as String?,
    );
  }
}
