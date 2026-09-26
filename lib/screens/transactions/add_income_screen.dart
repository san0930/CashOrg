import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../models/transaction_model.dart';
import '../../services/account_service.dart';
import '../../services/category_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/custom_textfield.dart';
import '../accounts/add_account_dialog.dart';
import '../categories/add_category_dialog.dart';

class AddIncomeScreen extends StatefulWidget {
  final TransactionService transactionService;
  final CategoryService? categoryService;
  final AccountService? accountService;
  final String userId;

  const AddIncomeScreen({
    super.key,
    required this.transactionService,
    this.categoryService,
    this.accountService,
    required this.userId,
  });

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final CategoryService _categoryService;
  late final AccountService _accountService;
  String _selectedSource = 'Salary';
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _categoryService = widget.categoryService ?? CategoryService();
    _accountService = widget.accountService ?? AccountService();

    _categoryService.addListener(_onServiceUpdate);
    _accountService.addListener(_onServiceUpdate);

    _categoryService.fetchCategories(widget.userId);
    _accountService.fetchAccounts(widget.userId);

    final available = _categoryService.allIncomeCategoryNames;
    if (available.isNotEmpty) {
      _selectedSource = available.first;
    }
  }

  void _onServiceUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final accounts = _accountService.accounts;
        if (_selectedAccountId == null && accounts.isNotEmpty) {
          _selectedAccountId = accounts.first.id;
        }
        final available = _categoryService.allIncomeCategoryNames;
        if (!available.contains(_selectedSource) && available.isNotEmpty) {
          _selectedSource = available.first;
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _categoryService.removeListener(_onServiceUpdate);
    _accountService.removeListener(_onServiceUpdate);
    if (widget.categoryService == null) {
      _categoryService.dispose();
    }
    if (widget.accountService == null) {
      _accountService.dispose();
    }
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addNewCategory() async {
    final newCat = await AddCategoryDialog.show(
      context,
      categoryService: _categoryService,
      userId: widget.userId,
      isIncome: true,
    );
    if (newCat != null && mounted) {
      setState(() {
        _selectedSource = newCat.name;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.incomeGreen,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addNewAccount() async {
    final newAcc = await AddAccountDialog.show(
      context,
      accountService: _accountService,
      userId: widget.userId,
    );
    if (newAcc != null && mounted) {
      setState(() {
        _selectedAccountId = newAcc.id;
      });
    }
  }

  void _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountId == null || _selectedAccountId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create an account to credit income.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than ₹0')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final activeUserId = widget.userId.isNotEmpty
        ? widget.userId
        : (SupabaseConfig.isConfigured
            ? (Supabase.instance.client.auth.currentUser?.id ?? '')
            : '');

    final newIncome = TransactionModel(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      userId: activeUserId,
      accountId: _selectedAccountId!,
      type: 'income',
      amount: amount,
      category: _selectedSource,
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      createdAt: DateTime.now(),
    );

    final success = await widget.transactionService.addTransaction(newIncome);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income saved successfully!'),
            backgroundColor: AppTheme.incomeGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.transactionService.errorMessage ?? 'Failed to save income'),
            backgroundColor: AppTheme.expenseRose,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final availableCategories = _categoryService.allIncomeCategories;
    final availableAccounts = _accountService.accounts;

    // Ensure valid selections
    if (!availableCategories.any((c) => c.name == _selectedSource) &&
        availableCategories.isNotEmpty) {
      _selectedSource = availableCategories.first.name;
    }

    if ((_selectedAccountId == null ||
            !availableAccounts.any((a) => a.id == _selectedAccountId)) &&
        availableAccounts.isNotEmpty) {
      _selectedAccountId = availableAccounts.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Income'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Category Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.incomeLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.incomeGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Income Entry',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.incomeGreen,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Record earnings into your account in Indian Rupees (₹)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Amount Field (₹)
                CustomTextField(
                  controller: _amountController,
                  label: 'Amount (₹)',
                  hintText: '0.00',
                  prefixIcon: Icons.currency_rupee_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the income amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Account / Credit To Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Account / Credit To',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _addNewAccount,
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              size: 16, color: AppTheme.incomeGreen),
                          label: const Text(
                            '+ Add Account',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.incomeGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAccountId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.account_balance_wallet_rounded,
                            color: AppTheme.textSecondary),
                      ),
                      items: availableAccounts.map((acc) {
                        return DropdownMenuItem<String>(
                          value: acc.id,
                          child: Row(
                            children: [
                              Icon(
                                acc.accountType == 'cash'
                                    ? Icons.payments_rounded
                                    : Icons.account_balance_rounded,
                                size: 18,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(acc.accountName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedAccountId = value;
                          });
                        }
                      },
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Please select an account' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Income Category Dropdown with "+ Add Category" button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Income Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _addNewCategory,
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              size: 16, color: AppTheme.incomeGreen),
                          label: const Text(
                            '+ Add Category',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.incomeGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSource,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.work_outline_rounded, color: AppTheme.textSecondary),
                      ),
                      items: availableCategories.map((catModel) {
                        final icon = CategoryHelper.getIcon(
                          catModel.name,
                          true,
                          customIconKey: catModel.icon,
                        );
                        final color = CategoryHelper.getColor(
                          catModel.name,
                          true,
                          customColorHex: catModel.color,
                        );

                        return DropdownMenuItem<String>(
                          value: catModel.name,
                          child: Row(
                            children: [
                              Icon(icon, color: color, size: 20),
                              const SizedBox(width: 10),
                              Text(catModel.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedSource = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Description Input
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Description / Note',
                  hintText: 'e.g., Monthly salary payment',
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: 20),

                // Date Picker Input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.inputBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: AppTheme.textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              dateFormat.format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down_rounded,
                                color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Save Income Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.incomeGreen,
                  ),
                  onPressed: _isSaving ? null : _saveIncome,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Save Income'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
