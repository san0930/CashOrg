import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../widgets/transaction_tile.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final TransactionService transactionService;

  const TransactionHistoryScreen({
    super.key,
    required this.transactionService,
  });

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'All'; // 'All', 'Income', 'Expense'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    widget.transactionService.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.transactionService.removeListener(_onUpdate);
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

  List<TransactionModel> get _filteredTransactions {
    final all = widget.transactionService.transactions;
    return all.where((tx) {
      // Type Filter
      if (_selectedFilter == 'Income' && !tx.isIncome) return false;
      if (_selectedFilter == 'Expense' && !tx.isExpense) return false;

      // Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesCat = tx.category.toLowerCase().contains(query);
        final matchesDesc = tx.description.toLowerCase().contains(query);
        final matchesAmount = tx.amount.toString().contains(query);
        return matchesCat || matchesDesc || matchesAmount;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
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
                  hintText: 'Search by category or description...',
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
              const SizedBox(height: 16),

              // Filter Segment Tabs
              Row(
                children: [
                  _buildFilterChip('All', _selectedFilter == 'All', isDark: isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Income', _selectedFilter == 'Income', color: AppTheme.incomeGreen, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Expense', _selectedFilter == 'Expense', color: AppTheme.expenseRose, isDark: isDark),
                ],
              ),
              const SizedBox(height: 16),

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
                              _searchQuery.isNotEmpty
                                  ? 'Try searching with a different term'
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
