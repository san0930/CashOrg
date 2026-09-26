import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/category_model.dart';
import '../widgets/category_icon.dart';

class CategoryService extends ChangeNotifier {
  List<CategoryModel> _customExpenseCategories = [];
  List<CategoryModel> _customIncomeCategories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> get customExpenseCategories =>
      List.unmodifiable(_customExpenseCategories);
  List<CategoryModel> get customIncomeCategories =>
      List.unmodifiable(_customIncomeCategories);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final Set<String> _hiddenExpenseCategoryNames = {};
  final Set<String> _hiddenIncomeCategoryNames = {};

  /// Returns full list of expense category names (default + custom)
  List<String> get allExpenseCategoryNames {
    final names = <String>[...CategoryHelper.expenseCategories];
    for (final cat in _customExpenseCategories) {
      if (!names.any((n) => n.toLowerCase() == cat.name.toLowerCase())) {
        names.insert(names.length - 1, cat.name); // Insert before 'Other'
      }
    }
    return names
        .where((n) => !_hiddenExpenseCategoryNames.contains(n.toLowerCase()))
        .toList();
  }

  /// Returns full list of income category names (default + custom)
  List<String> get allIncomeCategoryNames {
    final names = <String>[...CategoryHelper.incomeSources];
    for (final cat in _customIncomeCategories) {
      if (!names.any((n) => n.toLowerCase() == cat.name.toLowerCase())) {
        names.insert(names.length - 1, cat.name); // Insert before 'Other'
      }
    }
    return names
        .where((n) => !_hiddenIncomeCategoryNames.contains(n.toLowerCase()))
        .toList();
  }

  /// Returns full list of expense category models (default + custom)
  List<CategoryModel> get allExpenseCategories {
    final list = <CategoryModel>[];
    for (final name in CategoryHelper.expenseCategories) {
      if (_hiddenExpenseCategoryNames.contains(name.toLowerCase())) continue;
      final customMatch = _customExpenseCategories.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
        orElse: () => CategoryModel(
          id: 'def-exp-${name.toLowerCase()}',
          userId: 'default',
          name: name,
          icon: name.toLowerCase(),
          type: 'expense',
          createdAt: DateTime(2020),
        ),
      );
      list.add(customMatch);
    }
    for (final custom in _customExpenseCategories) {
      if (_hiddenExpenseCategoryNames.contains(custom.name.toLowerCase())) continue;
      if (!list.any((c) => c.name.toLowerCase() == custom.name.toLowerCase())) {
        list.insert(list.isNotEmpty ? list.length - 1 : 0, custom);
      }
    }
    return list;
  }

  /// Returns full list of income category models (default + custom)
  List<CategoryModel> get allIncomeCategories {
    final list = <CategoryModel>[];
    for (final name in CategoryHelper.incomeSources) {
      if (_hiddenIncomeCategoryNames.contains(name.toLowerCase())) continue;
      final customMatch = _customIncomeCategories.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
        orElse: () => CategoryModel(
          id: 'def-inc-${name.toLowerCase()}',
          userId: 'default',
          name: name,
          icon: name.toLowerCase(),
          type: 'income',
          createdAt: DateTime(2020),
        ),
      );
      list.add(customMatch);
    }
    for (final custom in _customIncomeCategories) {
      if (_hiddenIncomeCategoryNames.contains(custom.name.toLowerCase())) continue;
      if (!list.any((c) => c.name.toLowerCase() == custom.name.toLowerCase())) {
        list.insert(list.isNotEmpty ? list.length - 1 : 0, custom);
      }
    }
    return list;
  }

  CategoryService() {
    _initSampleCustomCategories();
    _loadHiddenCategories();
  }

  void _initSampleCustomCategories() {
    _customExpenseCategories = [];
    _customIncomeCategories = [];
  }

  Future<void> _loadHiddenCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedExpense = prefs.getStringList('hidden_expense_categories');
      if (savedExpense != null) {
        _hiddenExpenseCategoryNames.addAll(savedExpense.map((e) => e.toLowerCase()));
      }
      final savedIncome = prefs.getStringList('hidden_income_categories');
      if (savedIncome != null) {
        _hiddenIncomeCategoryNames.addAll(savedIncome.map((e) => e.toLowerCase()));
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveHiddenCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'hidden_expense_categories',
        _hiddenExpenseCategoryNames.toList(),
      );
      await prefs.setStringList(
        'hidden_income_categories',
        _hiddenIncomeCategoryNames.toList(),
      );
    } catch (_) {}
  }

  /// Fetch custom categories for a user from Supabase or Local
  Future<void> fetchCategories(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured) {
        final expResponse = await Supabase.instance.client
            .from('expense_categories')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: true);

        final incResponse = await Supabase.instance.client
            .from('income_categories')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: true);

        _customExpenseCategories = (expResponse as List)
            .map(
              (item) => CategoryModel.fromMap(
                item as Map<String, dynamic>,
                'expense',
              ),
            )
            .toList();

        _customIncomeCategories = (incResponse as List)
            .map(
              (item) =>
                  CategoryModel.fromMap(item as Map<String, dynamic>, 'income'),
            )
            .toList();
      } else {
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validates a category before saving
  String? validateCategory({
    required String name,
    required String icon,
    required bool isIncome,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Category name cannot be empty.';
    }

    if (icon.trim().isEmpty) {
      return 'Please select an icon for the category.';
    }

    final existingNames = isIncome
        ? allIncomeCategoryNames
        : allExpenseCategoryNames;
    if (existingNames.any(
      (n) => n.toLowerCase() == trimmedName.toLowerCase(),
    )) {
      return 'A ${isIncome ? "income" : "expense"} category with the name "$trimmedName" already exists.';
    }

    return null;
  }

  /// Add a custom category (Expense or Income)
  Future<bool> addCategory(CategoryModel category) async {
    final validationError = validateCategory(
      name: category.name,
      icon: category.icon,
      isIncome: category.isIncome,
    );

    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tableName = category.isIncome
          ? 'income_categories'
          : 'expense_categories';

      if (SupabaseConfig.isConfigured) {
        final response = await Supabase.instance.client
            .from(tableName)
            .insert(category.toMap())
            .select()
            .single();

        final createdCategory = CategoryModel.fromMap(response, category.type);

        if (category.isIncome) {
          _customIncomeCategories.add(createdCategory);
        } else {
          _customExpenseCategories.add(createdCategory);
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 200));
        if (category.isIncome) {
          _customIncomeCategories.add(category);
        } else {
          _customExpenseCategories.add(category);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a category (Expense or Income)
  Future<bool> deleteCategory(CategoryModel category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isIncome = category.isIncome;
      final tableName = isIncome ? 'income_categories' : 'expense_categories';

      if (SupabaseConfig.isConfigured && !category.id.startsWith('def-')) {
        await Supabase.instance.client
            .from(tableName)
            .delete()
            .eq('id', category.id);
      }

      if (isIncome) {
        _customIncomeCategories.removeWhere(
          (c) => c.id == category.id || c.name.toLowerCase() == category.name.toLowerCase(),
        );
        _hiddenIncomeCategoryNames.add(category.name.toLowerCase());
      } else {
        _customExpenseCategories.removeWhere(
          (c) => c.id == category.id || c.name.toLowerCase() == category.name.toLowerCase(),
        );
        _hiddenExpenseCategoryNames.add(category.name.toLowerCase());
      }

      await _saveHiddenCategories();

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
    if (str.contains('Failed host lookup') || str.contains('SocketException') || str.contains('errno = 7')) {
      return 'Network Connection Error: Please check your phone internet/Wi-Fi connection and try again.';
    }
    if (str.contains('PGRST205') || str.contains('Could not find the table')) {
      return 'Category tables missing in Supabase. Please run the SQL setup script in your Supabase SQL Editor.';
    }
    return str.replaceAll('PostgrestException(', '').replaceAll('Exception:', '').replaceAll('ClientException with ', '').trim();
  }
}
