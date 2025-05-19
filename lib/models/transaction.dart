class TransactionModel {
  final int? id;
  final int amount;
  final String type; // 'доход' или 'расход'
  final int categoryId;
  final DateTime date;
  final String description;

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      amount: map['amount'] as int,
      type: map['type'] as String,
      categoryId: map['category_id'] as int,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String? ?? '',
    );
  }
}
