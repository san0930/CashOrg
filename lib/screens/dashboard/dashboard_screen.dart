import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';
import '../../services/account_service.dart';
import '../../services/auth_service.dart';
import '../../services/category_service.dart';
import '../../services/profile_service.dart';
import '../../services/theme_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/income_expense_chart.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_tile.dart';
import '../accounts/account_management_screen.dart';
import '../accounts/add_account_dialog.dart';
import '../auth/login_screen.dart';
import '../categories/category_management_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';
import '../transactions/add_expense_screen.dart';
import '../transactions/add_income_screen.dart';
import '../transactions/transaction_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AuthService authService;
  final ThemeService? themeService;

  const DashboardScreen({
    super.key,
    required this.authService,
    this.themeService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final TransactionService _transactionService;
  late final CategoryService _categoryService;
  late final AccountService _accountService;
  late final ProfileService _profileService;
  late final ThemeService _themeService;

  String _selectedAccountId = 'all';

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService();
    _categoryService = CategoryService();
    _accountService = AccountService();
    _profileService = ProfileService();
    _themeService = widget.themeService ?? ThemeService();

    _transactionService.addListener(_onServiceUpdate);
    _categoryService.addListener(_onServiceUpdate);
    _accountService.addListener(_onServiceUpdate);
    _profileService.addListener(_onServiceUpdate);

    _initUserData();
  }

  Future<void> _initUserData() async {
    final user = widget.authService.currentUser;
    if (user != null) {
      await Future.wait([
        _transactionService.fetchTransactions(user.id),
        _categoryService.fetchCategories(user.id),
        _accountService.fetchAccounts(user.id),
        _profileService.fetchProfile(
          userId: user.id,
          email: user.email,
          defaultName: user.name,
          defaultAvatarUrl: user.avatarUrl,
        ),
      ]);
    }
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _transactionService.removeListener(_onServiceUpdate);
    _categoryService.removeListener(_onServiceUpdate);
    _accountService.removeListener(_onServiceUpdate);
    _profileService.removeListener(_onServiceUpdate);

    _transactionService.dispose();
    _categoryService.dispose();
    _accountService.dispose();
    _profileService.dispose();
    super.dispose();
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of your account?'),
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
              await widget.authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(authService: widget.authService),
                  ),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          profileService: _profileService,
          authService: widget.authService,
        ),
      ),
    );
  }

  void _navigateToCategoryManagement() {
    final userId = widget.authService.currentUser?.id ?? '';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryManagementScreen(
          categoryService: _categoryService,
          userId: userId,
        ),
      ),
    );
  }

  void _navigateToAccountManagement() {
    final userId = widget.authService.currentUser?.id ?? '';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccountManagementScreen(
          accountService: _accountService,
          transactionService: _transactionService,
          userId: userId,
        ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.authService.currentUser;
    final userId = user?.id ?? '';

    final profile = _profileService.currentProfile;
    final displayName = (profile?.name != null &&
            profile!.name.isNotEmpty &&
            profile.name != 'User' &&
            profile.name != 'My Profile')
        ? profile.name
        : ((user?.name != null && user!.name.isNotEmpty && user.name != 'User')
            ? user.name
            : 'User');
    final avatarUrl = (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
        ? profile.avatarUrl
        : user?.avatarUrl;

    final accounts = _accountService.accounts;
    final allTransactions = _transactionService.transactions;

    // Filter transactions if specific account is selected
    List<TransactionModel> displayTransactions = allTransactions;
    if (_selectedAccountId != 'all') {
      displayTransactions = allTransactions
          .where((t) => t.accountId == _selectedAccountId)
          .toList();
    }

    // Dynamic Calculations
    double computedBalance = 0;
    double computedIncome = 0;
    double computedExpense = 0;

    if (_selectedAccountId == 'all') {
      computedBalance = _accountService.calculateTotalBalance(allTransactions);
      computedIncome = _transactionService.totalIncome;
      computedExpense = _transactionService.totalExpenses;
    } else {
      computedBalance = _accountService.calculateAccountBalance(
        _selectedAccountId,
        allTransactions,
      );
      computedIncome = displayTransactions
          .where((t) => t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);
      computedExpense = displayTransactions
          .where((t) => t.isExpense)
          .fold(0.0, (sum, t) => sum + t.amount);
    }

    final recent = List<TransactionModel>.from(displayTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentDisplay = recent.take(5).toList();

    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    // Selected Account Name for chart title
    String selectedAccountName = 'All Accounts';
    if (_selectedAccountId != 'all') {
      final acc = accounts.firstWhere(
        (a) => a.id == _selectedAccountId,
        orElse: () => AccountModel(
          id: '',
          userId: '',
          accountName: 'Account',
          accountType: 'bank',
          openingBalance: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      selectedAccountName = acc.accountName;
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (user != null) {
              await Future.wait([
                _transactionService.fetchTransactions(user.id),
                _categoryService.fetchCategories(user.id),
                _accountService.fetchAccounts(user.id),
                _profileService.fetchProfile(
                  userId: user.id,
                  email: user.email,
                  defaultName: user.name,
                  defaultAvatarUrl: user.avatarUrl,
                ),
              ]);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Header: Profile (Left) & Actions (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _navigateToProfile,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: (avatarUrl == null || avatarUrl.isEmpty)
                                  ? Text(
                                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                        fontSize: 18,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$displayName 👋',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        PopupMenuButton<String>(
                          tooltip: 'Menu',
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurface
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.darkDividerColor
                                    : Colors.transparent,
                              ),
                            ),
                            child: Icon(
                              Icons.more_vert_rounded,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                              size: 20,
                            ),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'accounts':
                                _navigateToAccountManagement();
                                break;
                              case 'reports':
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ReportsScreen(
                                      transactionService: _transactionService,
                                      accountService: _accountService,
                                    ),
                                  ),
                                );
                                break;
                              case 'categories':
                                _navigateToCategoryManagement();
                                break;
                              case 'theme':
                                _themeService.toggleTheme();
                                break;
                              case 'profile':
                                _navigateToProfile();
                                break;
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'accounts',
                              child: Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_rounded, size: 20, color: AppTheme.primary),
                                  SizedBox(width: 12),
                                  Text('Manage Accounts'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'reports',
                              child: Row(
                                children: [
                                  Icon(Icons.bar_chart_rounded, size: 20, color: AppTheme.primary),
                                  SizedBox(width: 12),
                                  Text('Reports'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'categories',
                              child: Row(
                                children: [
                                  Icon(Icons.category_rounded, size: 20, color: AppTheme.primary),
                                  SizedBox(width: 12),
                                  Text('Manage Categories'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'theme',
                              child: Row(
                                children: [
                                  Icon(
                                    _themeService.isDarkMode
                                        ? Icons.light_mode_rounded
                                        : Icons.dark_mode_rounded,
                                    size: 20,
                                    color: _themeService.isDarkMode
                                        ? Colors.amber
                                        : Colors.indigo,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(_themeService.isDarkMode ? 'Light Theme' : 'Dark Theme'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 20, color: AppTheme.primary),
                                  SizedBox(width: 12),
                                  Text('My Profile'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Logout',
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.expenseRose.withValues(alpha: 0.15)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: AppTheme.expenseRose,
                              size: 20,
                            ),
                          ),
                          onPressed: _confirmLogout,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Financial Accounts Cards (Horizontal Scroll)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Financial Accounts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                      ),
                    ),
                    if (accounts.isNotEmpty)
                      TextButton.icon(
                        onPressed: _navigateToAccountManagement,
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('Manage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (accounts.isEmpty)
                  GestureDetector(
                    onTap: () => AddAccountDialog.show(
                      context,
                      accountService: _accountService,
                      userId: userId,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black26 : const Color(0x06000000),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'No accounts yet — Tap + Add Account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 94,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                      // "All Accounts" Pill Card
                      GestureDetector(
                        onTap: () => setState(() => _selectedAccountId = 'all'),
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedAccountId == 'all'
                                ? AppTheme.primary
                                : (isDark ? AppTheme.darkSurface : Colors.white),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _selectedAccountId == 'all'
                                  ? AppTheme.primary
                                  : (isDark ? AppTheme.darkDividerColor : const Color(0xFFE2E8F0)),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _selectedAccountId == 'all'
                                    ? AppTheme.primary.withValues(alpha: 0.3)
                                    : (isDark ? Colors.black26 : const Color(0x06000000)),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 16,
                                    color: _selectedAccountId == 'all'
                                        ? Colors.white
                                        : AppTheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'All Accounts',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedAccountId == 'all'
                                            ? Colors.white
                                            : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currencyFormat.format(
                                  _accountService.calculateTotalBalance(allTransactions),
                                ),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedAccountId == 'all'
                                      ? Colors.white
                                      : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Individual Account Cards
                      ...accounts.map((acc) {
                        final isSelected = _selectedAccountId == acc.id;
                        final accBalance = _accountService.calculateAccountBalance(
                          acc.id,
                          allTransactions,
                        );
                        final accentColor = _parseColor(acc.color);

                        return GestureDetector(
                          onTap: () => setState(() => _selectedAccountId = acc.id),
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor
                                  : (isDark ? AppTheme.darkSurface : Colors.white),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? accentColor
                                    : (isDark ? AppTheme.darkDividerColor : const Color(0xFFE2E8F0)),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? accentColor.withValues(alpha: 0.3)
                                      : (isDark ? Colors.black26 : const Color(0x06000000)),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      acc.accountType == 'cash'
                                          ? Icons.payments_rounded
                                          : Icons.account_balance_rounded,
                                      size: 16,
                                      color: isSelected ? Colors.white : accentColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        acc.accountName,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currencyFormat.format(accBalance),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      // "+ Add Account" Quick Button
                      GestureDetector(
                        onTap: () => AddAccountDialog.show(
                          context,
                          accountService: _accountService,
                          userId: userId,
                        ),
                        child: Container(
                          width: 110,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurface
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_circle_outline_rounded,
                                  color: AppTheme.primary, size: 24),
                              SizedBox(height: 4),
                              Text(
                                '+ Add Account',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 3. Current Balance Hero Card (₹) for selected account/all
                SummaryCard(
                  title: _selectedAccountId == 'all'
                      ? 'Total Balance (All Accounts)'
                      : '$selectedAccountName Balance',
                  amount: computedBalance,
                  icon: Icons.account_balance_wallet_rounded,
                  gradient: isDark ? AppTheme.darkBalanceGradient : AppTheme.balanceGradient,
                  isHeroBalance: true,
                ),
                const SizedBox(height: 14),

                // 4. Total Income & Total Expenses Cards (₹)
                Row(
                  children: [
                    SummaryCard(
                      title: 'Total Income',
                      amount: computedIncome,
                      icon: Icons.arrow_downward_rounded,
                      gradient: AppTheme.incomeCardGradient,
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      title: 'Total Expenses',
                      amount: computedExpense,
                      icon: Icons.arrow_upward_rounded,
                      gradient: AppTheme.expenseCardGradient,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Action Buttons (Add Expense & Add Income)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.expenseRose,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shadowColor: AppTheme.expenseRose.withValues(alpha: 0.3),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddExpenseScreen(
                                transactionService: _transactionService,
                                categoryService: _categoryService,
                                accountService: _accountService,
                                userId: userId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                        label: const Text('Add Expense'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.incomeGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shadowColor: AppTheme.incomeGreen.withValues(alpha: 0.3),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddIncomeScreen(
                                transactionService: _transactionService,
                                categoryService: _categoryService,
                                accountService: _accountService,
                                userId: userId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                        label: const Text('Add Income'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // 6. Pie Chart Section (Account-specific breakdown or overall)
                if (_selectedAccountId == 'all')
                  IncomeExpensePieChart(
                    totalIncome: computedIncome,
                    totalExpenses: computedExpense,
                  )
                else
                  AccountCategoryPieChart(
                    transactions: displayTransactions,
                    title: selectedAccountName,
                  ),
                const SizedBox(height: 30),

                // 7. Recent Transactions Header & List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedAccountId == 'all'
                          ? 'Recent Transactions'
                          : '$selectedAccountName Transactions',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TransactionHistoryScreen(
                              transactionService: _transactionService,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (recentDisplay.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.darkDividerColor : const Color(0xFFF1F5F9),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedAccountId == 'all'
                              ? 'Tap Add Expense or Add Income to start tracking in ₹'
                              : 'No transactions found for $selectedAccountName',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...recentDisplay.map(
                    (tx) => TransactionTile(
                      transaction: tx,
                      onDelete: () => _transactionService.deleteTransaction(tx.id),
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
