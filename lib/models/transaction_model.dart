import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionCategory { deposit, withdrawal }

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.description = '',
    this.receiptUrl,
    this.receiptPath,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final double amount;
  final TransactionCategory category;
  final DateTime date;
  final String description;
  final String? receiptUrl;
  final String? receiptPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDeposit => category == TransactionCategory.deposit;

  factory TransactionModel.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? <String, dynamic>{};
    return TransactionModel(
      id: document.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      category: data['category'] == 'withdrawal'
          ? TransactionCategory.withdrawal
          : TransactionCategory.deposit,
      date: _readDate(data['date']) ?? DateTime.now(),
      description: data['description'] as String? ?? '',
      receiptUrl: data['receiptUrl'] as String?,
      receiptPath: data['receiptPath'] as String?,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'description': description,
      'receiptUrl': receiptUrl,
      'receiptPath': receiptPath,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  TransactionModel copyWith({
    String? id,
    double? amount,
    TransactionCategory? category,
    DateTime? date,
    String? description,
    String? receiptUrl,
    String? receiptPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
