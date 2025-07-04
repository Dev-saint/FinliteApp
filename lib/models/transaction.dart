class TransactionModel {
  final int? id;
  final double amount;
  final String type; // 'доход' или 'расход'
  final int categoryId;
  final int accountId; // Поле для привязки к счету
  final DateTime date;
  final String description;

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId, // Поле для привязки к счету
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'account_id': accountId, // Привязка к счету
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      amount:
          (map['amount'] is String)
              ? double.tryParse(map['amount']) ?? 0.0
              : (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] as String,
      categoryId: map['category_id'] as int,
      accountId: map['account_id'] as int, // Привязка к счету
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String? ?? '',
    );
  }
}
