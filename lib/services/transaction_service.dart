import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/transaction_model.dart';

class TransactionService extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Balance Calculations
  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses => _transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get currentBalance => totalIncome - totalExpenses;

  List<TransactionModel> get recentTransactions {
    final sorted = List<TransactionModel>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  TransactionService() {
    _transactions = [];
  }

  /// Load transactions from Supabase or Local
  Future<void> fetchTransactions(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured && !userId.startsWith('guest-')) {
        final data = await Supabase.instance.client
            .from('transactions')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        _transactions = (data as List)
            .map(
              (item) => TransactionModel.fromMap(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (e) {
      _errorMessage = _formatError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new transaction (Income or Expense)
  Future<bool> addTransaction(TransactionModel transaction) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isGuest = transaction.userId.startsWith('guest-');
      if (SupabaseConfig.isConfigured && !isGuest) {
        final activeUserId = transaction.userId.isNotEmpty
            ? transaction.userId
            : Supabase.instance.client.auth.currentUser?.id;

        if (activeUserId == null || activeUserId.trim().isEmpty) {
          throw Exception('User authentication session expired. Please log out and sign in again.');
        }

        final txMap = transaction.toMap();
        txMap['user_id'] = activeUserId;

        final response = await Supabase.instance.client
            .from('transactions')
            .insert(txMap)
            .select()
            .single();

        final createdTx = TransactionModel.fromMap(response);
        _transactions.insert(0, createdTx);
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
        _transactions.insert(0, transaction);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  /// Delete a transaction by ID
  Future<bool> deleteTransaction(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured) {
        await Supabase.instance.client
            .from('transactions')
            .delete()
            .eq('id', id);
      } else {
        await Future.delayed(const Duration(milliseconds: 150));
      }

      _transactions.removeWhere((t) => t.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  String _formatError(dynamic e) {
    final str = e.toString();
    if (str.contains('22P02') || str.contains('invalid input syntax for type uuid')) {
      return 'User authentication session expired. Please log out and sign in again.';
    }
    if (str.contains('Failed host lookup') || str.contains('SocketException') || str.contains('errno = 7')) {
      return 'Network Connection Error: Please check your phone internet/Wi-Fi connection and try again.';
    }
    if (str.contains('PGRST205') || str.contains('Could not find the table')) {
      return 'Table "transactions" not found in Supabase. Please run the SQL schema script in your Supabase SQL Editor.';
    }
    return str.replaceAll('PostgrestException(', '').replaceAll('Exception:', '').replaceAll('ClientException with ', '').trim();
  }
}
