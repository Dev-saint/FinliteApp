class Account {
  final int? id; // Поле id должно быть nullable
  final String name;

  Account({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {if (id != null) 'id': id, 'name': name};
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(id: map['id'] as int?, name: map['name'] as String);
  }
}
