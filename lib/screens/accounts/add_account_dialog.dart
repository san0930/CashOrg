import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../widgets/custom_textfield.dart';

class AddAccountDialog extends StatefulWidget {
  final AccountService accountService;
  final String userId;
  final AccountModel? existingAccount;

  const AddAccountDialog({
    super.key,
    required this.accountService,
    required this.userId,
    this.existingAccount,
  });

  static Future<AccountModel?> show(
    BuildContext context, {
    required AccountService accountService,
    required String userId,
    AccountModel? existingAccount,
  }) {
    return showDialog<AccountModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddAccountDialog(
        accountService: accountService,
        userId: userId,
        existingAccount: existingAccount,
      ),
    );
  }

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  String _selectedType = 'bank';
  String _selectedColor = '#1E3A8A';
  bool _isSaving = false;

  final List<Map<String, String>> _types = [
    {'key': 'bank', 'label': 'Bank Account', 'icon': 'account_balance'},
    {'key': 'cash', 'label': 'Cash', 'icon': 'payments'},
    {'key': 'wallet', 'label': 'Wallet / UPI', 'icon': 'account_balance_wallet'},
    {'key': 'other', 'label': 'Other', 'icon': 'credit_card'},
  ];

  final List<String> _colors = [
    '#1E3A8A', // Deep Blue
    '#0284C7', // Light Blue
    '#16A34A', // Green
    '#D97706', // Amber/Orange
    '#DC2626', // Red
    '#7C3AED', // Purple
    '#DB2777', // Pink
    '#4B5563', // Slate
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingAccount != null) {
      _nameController.text = widget.existingAccount!.accountName;
      _balanceController.text = widget.existingAccount!.openingBalance.toStringAsFixed(0);
      _selectedType = widget.existingAccount!.accountType;
      if (widget.existingAccount!.color != null) {
        _selectedColor = widget.existingAccount!.color!;
      }
    } else {
      _balanceController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final now = DateTime.now();

    final isEdit = widget.existingAccount != null;
    final account = AccountModel(
      id: isEdit ? widget.existingAccount!.id : 'acc-${now.millisecondsSinceEpoch}',
      userId: widget.userId,
      accountName: name,
      accountType: _selectedType,
      openingBalance: balance,
      color: _selectedColor,
      icon: _selectedType == 'bank'
          ? 'account_balance'
          : (_selectedType == 'cash'
              ? 'payments'
              : (_selectedType == 'wallet' ? 'account_balance_wallet' : 'credit_card')),
      createdAt: isEdit ? widget.existingAccount!.createdAt : now,
      updatedAt: now,
    );

    AccountModel? result;
    if (isEdit) {
      final success = await widget.accountService.updateAccount(account);
      if (success) result = account;
    } else {
      result = await widget.accountService.addAccount(account);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (widget.accountService.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.accountService.errorMessage!),
            backgroundColor: AppTheme.expenseRose,
          ),
        );
      } else {
        Navigator.pop(context, result ?? account);
      }
    }
  }

  Color _parseColor(String hex) {
    try {
      final cleanHex = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.existingAccount != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Account' : 'Add Financial Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Account Name
                CustomTextField(
                  label: 'Account Name',
                  hintText: 'e.g. HDFC Bank, SBI, Cash, PayTM',
                  controller: _nameController,
                  prefixIcon: Icons.account_balance_wallet_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter account name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Opening Balance
                CustomTextField(
                  label: 'Opening Balance (₹)',
                  hintText: 'e.g. 25000',
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.currency_rupee_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter opening balance';
                    }
                    if (double.tryParse(val.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Account Type Selector
                Text(
                  'Account Type',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types.map((type) {
                    final selected = _selectedType == type['key'];
                    return ChoiceChip(
                      label: Text(type['label']!),
                      selected: selected,
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedType = type['key']!;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Color Selector
                Text(
                  'Account Color Accent',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _colors.map((hex) {
                    final color = _parseColor(hex);
                    final selected = _selectedColor == hex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = hex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveAccount,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEdit ? 'Update Account' : 'Save Account',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
