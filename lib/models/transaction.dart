class Transaction {
  final int? id;
  final String amount;
  final String sender;
  final String messageBody;
  final String transactionType; // 'income' or 'expense'
  final DateTime date;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.amount,
    required this.sender,
    required this.messageBody,
    required this.transactionType,
    required this.date,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'sender': sender,
      'messageBody': messageBody,
      'transactionType': transactionType,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON (database retrieval)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int?,
      amount: json['amount'] as String,
      sender: json['sender'] as String,
      messageBody: json['messageBody'] as String,
      transactionType: json['transactionType'] as String,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Copy with method for updates
  Transaction copyWith({
    int? id,
    String? amount,
    String? sender,
    String? messageBody,
    String? transactionType,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      sender: sender ?? this.sender,
      messageBody: messageBody ?? this.messageBody,
      transactionType: transactionType ?? this.transactionType,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
