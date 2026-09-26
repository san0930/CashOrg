import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';

class AccountService extends ChangeNotifier {
  List<AccountModel> _accounts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AccountModel> get accounts => List.unmodifiable(_accounts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AccountService() {
    _accounts = [];
  }

  /// Load accounts for user from Supabase. Zero auto-seeding.
  Future<void> fetchAccounts(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured && userId.isNotEmpty && !userId.startsWith('guest-')) {
        final data = await Supabase.instance.client
            .from('accounts')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: true);

        _accounts = (data as List)
            .map((item) => AccountModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      _errorMessage = _formatError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add new Account
  Future<AccountModel?> addAccount(AccountModel account) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured && !account.userId.startsWith('guest-')) {
        final activeUserId = account.userId.isNotEmpty
            ? account.userId
            : Supabase.instance.client.auth.currentUser?.id;

        if (activeUserId == null || activeUserId.isEmpty) {
          throw Exception('User authentication session expired.');
        }

        final map = account.toMap();
        map['user_id'] = activeUserId;

        final response = await Supabase.instance.client
            .from('accounts')
            .insert(map)
            .select()
            .single();

        final created = AccountModel.fromMap(response);
        _accounts.add(created);
        _isLoading = false;
        notifyListeners();
        return created;
      } else {
        _accounts.add(account);
        _isLoading = false;
        notifyListeners();
        return account;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatError(e);
      notifyListeners();
      return null;
    }
  }

  /// Update an existing Account
  Future<bool> updateAccount(AccountModel account) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured && account.id.length == 36 && !account.userId.startsWith('guest-')) {
        final map = account.toMap();
        map['updated_at'] = DateTime.now().toIso8601String();

        await Supabase.instance.client
            .from('accounts')
            .update(map)
            .eq('id', account.id);
      }

      final index = _accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        _accounts[index] = account;
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

  /// Delete account safely. Checks if transactions exist.
  Future<bool> deleteAccount(String accountId, List<TransactionModel> transactions) async {
    _isLoading = true;
    _errorMessage = null;

    final hasTransactions = transactions.any((t) => t.accountId == accountId);
    if (hasTransactions) {
      _isLoading = false;
      _errorMessage = 'Cannot delete account because it contains linked transactions. Please delete or reassign its transactions first.';
      notifyListeners();
      return false;
    }

    try {
      if (SupabaseConfig.isConfigured && accountId.length == 36) {
        await Supabase.instance.client
            .from('accounts')
            .delete()
            .eq('id', accountId);
      }

      _accounts.removeWhere((a) => a.id == accountId);
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

  /// Dynamic account balance calculation based on real transaction history
  double calculateAccountBalance(String accountId, List<TransactionModel> transactions) {
    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index == -1) return 0.0;
    final account = _accounts[index];

    final income = transactions
        .where((t) => t.accountId == accountId && t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    final expense = transactions
        .where((t) => t.accountId == accountId && t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return account.openingBalance + income - expense;
  }

  /// Total balance across all user-created accounts
  double calculateTotalBalance(List<TransactionModel> transactions) {
    if (_accounts.isEmpty) return 0.0;
    double total = 0.0;
    for (final acc in _accounts) {
      total += calculateAccountBalance(acc.id, transactions);
    }
    return total;
  }

  String _formatError(dynamic e) {
    final str = e.toString();
    if (str.contains('PGRST205') || str.contains('Could not find the table')) {
      return 'Table "accounts" not found in Supabase. Please run the SQL schema script in your Supabase SQL Editor.';
    }
    return str
        .replaceAll('PostgrestException(', '')
        .replaceAll('Exception:', '')
        .replaceAll('ClientException with ', '')
        .trim();
  }
}
