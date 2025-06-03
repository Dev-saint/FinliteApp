class Account {
  final int? id; // Поле id должно быть nullable
  final String name;
  final double balance;

  Account({this.id, required this.name, this.balance = 0});

  Map<String, dynamic> toMap() {
    return {if (id != null) 'id': id, 'name': name, 'balance': balance};
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      balance:
          (map['balance'] is int)
              ? (map['balance'] as int).toDouble()
              : (map['balance'] as double? ?? 0),
    );
  }
}
