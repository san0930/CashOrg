import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/services/transaction_service.dart';

void main() {
  group('CashOrg Single-User Unit Tests', () {
    test('TransactionModel serialization and deserialization in ₹', () {
      final now = DateTime.now();
      final tx = TransactionModel(
        id: '10000000-0000-4000-8000-000000000001',
        userId: 'device-user-123',
        accountId: '10000000-0000-4000-8000-000000000002',
        type: 'expense',
        amount: 2500.50,
        category: 'Shopping',
        description: 'Diwali Shopping',
        date: now,
        createdAt: now,
      );

      final map = tx.toMap();
      expect(map['user_id'], 'device-user-123');
      expect(map['amount'], 2500.50);
      expect(map['type'], 'expense');
      expect(map['category'], 'Shopping');

      final restored = TransactionModel.fromMap(map);
      expect(restored.amount, tx.amount);
      expect(restored.category, tx.category);
      expect(restored.isExpense, isTrue);
    });

    test('TransactionService balance calculations (Total Income - Total Expenses)', () {
      final service = TransactionService();
      expect(service.currentBalance, service.totalIncome - service.totalExpenses);
    });
  });
}
