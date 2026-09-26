import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String accountId;
  final String? accountName;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category; // Expense category or Income source
  final String description;
  final DateTime date;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.accountId,
    this.accountName,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.createdAt,
  });

  bool get isIncome => type.toLowerCase() == 'income';
  bool get isExpense => type.toLowerCase() == 'expense';

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final dateStr = map['transaction_date'] ?? map['date'];
    String accName = map['account_name']?.toString() ?? '';
    if (accName.isEmpty && map['accounts'] != null && map['accounts'] is Map) {
      accName = map['accounts']['account_name']?.toString() ?? '';
    }

    return TransactionModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      accountId: map['account_id']?.toString() ?? '',
      accountName: accName.isNotEmpty ? accName : null,
      type: map['type']?.toString() ?? 'expense',
      amount: (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : double.parse(map['amount']?.toString() ?? '0.0'),
      category: map['category']?.toString() ?? 'Other',
      description: map['description']?.toString() ?? '',
      date: dateStr != null
          ? DateTime.parse(dateStr.toString())
          : DateTime.now(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    String activeUserId = userId;
    if (activeUserId.isEmpty && SupabaseConfig.isConfigured) {
      activeUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    }

    final map = <String, dynamic>{
      'user_id': activeUserId,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'transaction_date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
    if (accountId.isNotEmpty) {
      map['account_id'] = accountId;
    }
    if (id.length == 36 && !id.startsWith('tx-')) {
      map['id'] = id;
    }
    return map;
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? accountName,
    String? type,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
