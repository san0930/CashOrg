import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../services/account_service.dart';
import '../../services/category_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/transaction_tile.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final TransactionService transactionService;
  final AccountService? accountService;
  final CategoryService? categoryService;
  final String? userId;
  final bool isEmbedded;

  const TransactionHistoryScreen({
    super.key,
    required this.transactionService,
    this.accountService,
    this.categoryService,
    this.userId,
    this.isEmbedded = false,
  });

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'All'; // 'All', 'Income', 'Expense'
  String _selectedAccountId = 'All';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  late final AccountService _accountService;
  late final CategoryService _categoryService;

  @override
  void initState() {
    super.initState();
    _accountService = widget.accountService ?? AccountService();
    _categoryService = widget.categoryService ?? CategoryService();

    widget.transactionService.addListener(_onUpdate);
    _accountService.addListener(_onUpdate);
    _categoryService.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.transactionService.removeListener(_onUpdate);
    if (widget.accountService == null) {
      _accountService.dispose();
    } else {
      _accountService.removeListener(_onUpdate);
    }
    if (widget.categoryService == null) {
      _categoryService.dispose();
    } else {
      _categoryService.removeListener(_onUpdate);
    }
    super.dispose();
  }

  void _confirmDelete(TransactionModel tx) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete this ${tx.category} transaction of ₹${tx.amount.toStringAsFixed(2)}?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseRose,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await widget.transactionService.deleteTransaction(tx.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editTransaction(TransactionModel tx) {
    final userId = widget.userId ?? tx.userId;
    if (tx.isExpense) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddExpenseScreen(
            transactionService: widget.transactionService,
            categoryService: _categoryService,
            accountService: _accountService,
            userId: userId,
            existingTransaction: tx,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddIncomeScreen(
            transactionService: widget.transactionService,
            categoryService: _categoryService,
            accountService: _accountService,
            userId: userId,
            existingTransaction: tx,
          ),
        ),
      );
    }
  }

  List<TransactionModel> get _filteredTransactions {
    final all = widget.transactionService.transactions;
    return all.where((tx) {
      // Type Filter
      if (_selectedFilter == 'Income' && !tx.isIncome) return false;
      if (_selectedFilter == 'Expense' && !tx.isExpense) return false;

      // Account Filter
      if (_selectedAccountId != 'All' && tx.accountId != _selectedAccountId) {
        return false;
      }

      // Category Filter
      if (_selectedCategory != 'All' && tx.category != _selectedCategory) {
        return false;
      }

      // Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesCat = tx.category.toLowerCase().contains(query);
        final matchesDesc = tx.description.toLowerCase().contains(query);
        final matchesAmount = tx.amount.toString().contains(query);
        final matchesAcc = (tx.accountName ?? '').toLowerCase().contains(query);
        return matchesCat || matchesDesc || matchesAmount || matchesAcc;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = _filteredTransactions;
    final accounts = _accountService.accounts;
    final categoryNames = [
      ..._categoryService.allExpenseCategoryNames,
      ..._categoryService.allIncomeCategoryNames,
    ];

    // Collect all distinct category names present in transactions or category service
    final categoryOptions = {
      'All',
      ...categoryNames,
      ...widget.transactionService.transactions.map((t) => t.category),
    }.toList();

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Transaction History'),
              elevation: 0,
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input Box
              TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search transactions in ₹...',
                  hintStyle: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            size: 20,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),

              // Filter Type Segment Tabs (All / Income / Expense)
              Row(
                children: [
                  _buildFilterChip('All', _selectedFilter == 'All', isDark: isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Income', _selectedFilter == 'Income', color: AppTheme.incomeGreen, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Expense', _selectedFilter == 'Expense', color: AppTheme.expenseRose, isDark: isDark),
                ],
              ),
              const SizedBox(height: 12),

              // Dropdown Filters: Account & Category Filters
              Row(
                children: [
                  // Account Filter Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppTheme.darkDividerColor : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: accounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : 'All',
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: 'All',
                              child: Text('All Accounts', overflow: TextOverflow.ellipsis),
                            ),
                            ...accounts.map(
                              (acc) => DropdownMenuItem<String>(
                                value: acc.id,
                                child: Text(acc.accountName, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedAccountId = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Category Filter Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppTheme.darkDividerColor : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: categoryOptions.contains(_selectedCategory) ? _selectedCategory : 'All',
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                          ),
                          items: categoryOptions.map(
                            (cat) => DropdownMenuItem<String>(
                              value: cat,
                              child: Text(cat == 'All' ? 'All Categories' : cat, overflow: TextOverflow.ellipsis),
                            ),
                          ).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Active Filters indicator if any applied
              if (_selectedAccountId != 'All' || _selectedCategory != 'All' || _searchQuery.isNotEmpty || _selectedFilter != 'All')
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${transactions.length} results',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = 'All';
                            _selectedAccountId = 'All';
                            _selectedCategory = 'All';
                            _searchQuery = '';
                          });
                        },
                        child: const Text(
                          'Reset Filters',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Transactions List
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _searchQuery.isNotEmpty || _selectedAccountId != 'All' || _selectedCategory != 'All'
                                  ? 'Try changing your filter settings'
                                  : 'Start by adding an income or expense in ₹',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: transactions.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return TransactionTile(
                            transaction: tx,
                            onEdit: () => _editTransaction(tx),
                            onDelete: () => _confirmDelete(tx),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, {Color? color, required bool isDark}) {
    final activeColor = color ?? AppTheme.primary;
    final unselectedBg = isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9);
    final unselectedText = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : unselectedBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? AppTheme.darkDividerColor : Colors.transparent),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : unselectedText,
            ),
          ),
        ),
      ),
    );
  }
}
