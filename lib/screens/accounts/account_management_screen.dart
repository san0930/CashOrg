import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/transaction_tile.dart';
import 'add_account_dialog.dart';

class AccountManagementScreen extends StatefulWidget {
  final AccountService accountService;
  final TransactionService transactionService;
  final String userId;
  final bool isEmbedded;

  const AccountManagementScreen({
    super.key,
    required this.accountService,
    required this.transactionService,
    required this.userId,
    this.isEmbedded = false,
  });

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  String? _expandedAccountId;

  @override
  void initState() {
    super.initState();
    widget.accountService.addListener(_onServiceUpdate);
    widget.transactionService.addListener(_onServiceUpdate);
    _refresh();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.accountService.removeListener(_onServiceUpdate);
    widget.transactionService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  Future<void> _refresh() async {
    await widget.accountService.fetchAccounts(widget.userId);
  }

  Future<void> _addAccount() async {
    await AddAccountDialog.show(
      context,
      accountService: widget.accountService,
      userId: widget.userId,
    );
  }

  Future<void> _editAccount(AccountModel account) async {
    await AddAccountDialog.show(
      context,
      accountService: widget.accountService,
      userId: widget.userId,
      existingAccount: account,
    );
  }

  Future<void> _deleteAccount(AccountModel account) async {
    final transactions = widget.transactionService.transactions;
    final hasTx = transactions.any((t) => t.accountId == account.id);

    if (hasTx) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppTheme.expenseRose),
              SizedBox(width: 8),
              Text('Cannot Delete Account'),
            ],
          ),
          content: Text(
            'Account "${account.accountName}" has linked transaction history.\n\nTo protect your financial records, accounts with transactions cannot be deleted directly.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirm deletion for empty accounts
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${account.accountName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseRose),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await widget.accountService.deleteAccount(
                account.id,
                widget.transactionService.transactions,
              );
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted "${account.accountName}"')),
                  );
                } else if (widget.accountService.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(widget.accountService.errorMessage!),
                      backgroundColor: AppTheme.expenseRose,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppTheme.primary;
    try {
      final cleanHex = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.payments_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'other':
        return Icons.credit_card_rounded;
      case 'bank':
      default:
        return Icons.account_balance_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accounts = widget.accountService.accounts;
    final transactions = widget.transactionService.transactions;
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text(
                'Financial Accounts',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Add Account',
                  onPressed: _addAccount,
                ),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: accounts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Accounts Found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap + to create your first bank or cash account'),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      onPressed: _addAccount,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Account'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  final balance = widget.accountService.calculateAccountBalance(
                    account.id,
                    transactions,
                  );
                  final accentColor = _parseColor(account.color);
                  final iconData = _getIcon(account.accountType);
                  final accountTxs = transactions.where((t) => t.accountId == account.id).toList();
                  final isExpanded = _expandedAccountId == account.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppTheme.darkDividerColor : const Color(0xFFF1F5F9),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.2)
                              : const Color(0x08000000),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _expandedAccountId = isExpanded ? null : account.id;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Account Color Badge & Icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(iconData, color: accentColor, size: 24),
                                ),
                                const SizedBox(width: 14),

                                // Account Name & Type
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        account.accountName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${account.accountType.toUpperCase()} • Opening: ${currencyFormat.format(account.openingBalance)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Current Balance & Action Menu
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      currencyFormat.format(balance),
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: balance >= 0
                                            ? (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)
                                            : AppTheme.expenseRose,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          color: AppTheme.primary,
                                          onPressed: () => _editAccount(account),
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          color: AppTheme.expenseRose,
                                          onPressed: () => _deleteAccount(account),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Account-wise Transactions Expanded View
                        if (isExpanded) ...[
                          const Divider(height: 1),
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: isDark ? AppTheme.darkBackground.withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${account.accountName} Transactions',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '${accountTxs.length} records',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (accountTxs.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: Text(
                                        'No transactions recorded for this account',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...accountTxs.take(5).map(
                                    (tx) => TransactionTile(
                                      transaction: tx,
                                      onDelete: () => widget.transactionService.deleteTransaction(tx.id),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: _addAccount,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Account', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
