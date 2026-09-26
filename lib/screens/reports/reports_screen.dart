import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../services/account_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/category_icon.dart';

enum ReportPeriod { weekly, monthly }

class ReportsScreen extends StatefulWidget {
  final TransactionService transactionService;
  final AccountService? accountService;

  const ReportsScreen({
    super.key,
    required this.transactionService,
    this.accountService,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.weekly;
  DateTime _referenceDate = DateTime.now();
  String _selectedAccountId = 'all';

  @override
  void initState() {
    super.initState();
    widget.transactionService.addListener(_onServiceUpdate);
    widget.accountService?.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.transactionService.removeListener(_onServiceUpdate);
    widget.accountService?.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _navigatePeriod(int direction) {
    setState(() {
      if (_selectedPeriod == ReportPeriod.weekly) {
        _referenceDate = _referenceDate.add(Duration(days: 7 * direction));
      } else {
        _referenceDate = DateTime(_referenceDate.year, _referenceDate.month + direction, 1);
      }
    });
  }

  // Get start and end dates for selected period
  DateTime get _periodStartDate {
    if (_selectedPeriod == ReportPeriod.weekly) {
      final dayOfWeek = _referenceDate.weekday; // 1 = Mon, 7 = Sun
      final monday = _referenceDate.subtract(Duration(days: dayOfWeek - 1));
      return DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
    } else {
      return DateTime(_referenceDate.year, _referenceDate.month, 1, 0, 0, 0);
    }
  }

  DateTime get _periodEndDate {
    if (_selectedPeriod == ReportPeriod.weekly) {
      final start = _periodStartDate;
      final sunday = start.add(const Duration(days: 6));
      return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
    } else {
      final nextMonth = DateTime(_referenceDate.year, _referenceDate.month + 1, 1);
      final lastDay = nextMonth.subtract(const Duration(days: 1));
      return DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
    }
  }

  String get _periodTitleText {
    final start = _periodStartDate;
    final end = _periodEndDate;

    if (_selectedPeriod == ReportPeriod.weekly) {
      final now = DateTime.now();
      final currentWeekStart = _getMondayOf(now);
      if (start.year == currentWeekStart.year &&
          start.month == currentWeekStart.month &&
          start.day == currentWeekStart.day) {
        return 'This Week (${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(end)})';
      }
      return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}';
    } else {
      return DateFormat('MMMM yyyy').format(start);
    }
  }

  DateTime _getMondayOf(DateTime date) {
    final dayOfWeek = date.weekday;
    final monday = date.subtract(Duration(days: dayOfWeek - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  List<TransactionModel> get _periodTransactions {
    final start = _periodStartDate;
    final end = _periodEndDate;
    return widget.transactionService.transactions.where((tx) {
      final inRange = tx.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(end.add(const Duration(seconds: 1)));
      if (!inRange) return false;
      if (_selectedAccountId != 'all' && tx.accountId != _selectedAccountId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final secondaryTextColor = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkDividerColor : const Color(0xFFF1F5F9);

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    final txs = _periodTransactions;
    final totalIncome = txs.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = txs.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
    final netBalance = totalIncome - totalExpenses;

    // Group expenses by category
    final expenseMap = <String, double>{};
    for (final tx in txs.where((t) => t.isExpense)) {
      expenseMap[tx.category] = (expenseMap[tx.category] ?? 0.0) + tx.amount;
    }

    // Group income by category
    final incomeMap = <String, double>{};
    for (final tx in txs.where((t) => t.isIncome)) {
      incomeMap[tx.category] = (incomeMap[tx.category] ?? 0.0) + tx.amount;
    }

    final accounts = widget.accountService?.accounts ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 0. Account Filter Selector
              if (accounts.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Account Filter:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAccountId,
                            isExpanded: true,
                            dropdownColor: cardBgColor,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: primaryTextColor,
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: 'all',
                                child: Text('All Accounts'),
                              ),
                              ...accounts.map(
                                (acc) => DropdownMenuItem<String>(
                                  value: acc.id,
                                  child: Text(acc.accountName),
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Weekly / Monthly Segment Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton(
                      label: 'Weekly Report',
                      isSelected: _selectedPeriod == ReportPeriod.weekly,
                      onTap: () {
                        setState(() {
                          _selectedPeriod = ReportPeriod.weekly;
                          _referenceDate = DateTime.now();
                        });
                      },
                      isDark: isDark,
                    ),
                    _buildSegmentButton(
                      label: 'Monthly Report',
                      isSelected: _selectedPeriod == ReportPeriod.monthly,
                      onTap: () {
                        setState(() {
                          _selectedPeriod = ReportPeriod.monthly;
                          _referenceDate = DateTime.now();
                        });
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Period Date Navigator (< Period >)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left_rounded, color: primaryTextColor),
                      onPressed: () => _navigatePeriod(-1),
                    ),
                    Expanded(
                      child: Text(
                        _periodTitleText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right_rounded, color: primaryTextColor),
                      onPressed: () => _navigatePeriod(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Summary Hero Cards (Income, Expenses, Net)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildStatTile(
                          label: 'Total Income',
                          amount: currencyFormatter.format(totalIncome),
                          color: AppTheme.incomeGreen,
                          icon: Icons.arrow_downward_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 16),
                        _buildStatTile(
                          label: 'Total Expenses',
                          amount: currencyFormatter.format(totalExpenses),
                          color: AppTheme.expenseRose,
                          icon: Icons.arrow_upward_rounded,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Net Balance',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: secondaryTextColor,
                          ),
                        ),
                        Text(
                          currencyFormatter.format(netBalance),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: netBalance >= 0 ? AppTheme.incomeGreen : AppTheme.expenseRose,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Trend Bar Chart (Day-wise / Period-wise)
              Text(
                _selectedPeriod == ReportPeriod.weekly
                    ? 'Day-wise Spending Trend'
                    : 'Monthly Income vs Expense Trend',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                height: 220,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: txs.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions for this period',
                          style: TextStyle(color: secondaryTextColor, fontSize: 14),
                        ),
                      )
                    : BarChart(
                        _buildBarChartData(txs, isDark),
                      ),
              ),
              const SizedBox(height: 28),

              // 5. Expense Category Distribution Chart & List
              Text(
                'Expense Category Breakdown',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 12),

              if (expenseMap.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Text(
                      'No expense records in this period',
                      style: TextStyle(color: secondaryTextColor, fontSize: 14),
                    ),
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 160,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 36,
                            sections: expenseMap.entries.map((e) {
                              final pct = ((e.value / totalExpenses) * 100).toStringAsFixed(1);
                              final color = CategoryHelper.getColor(e.key, false);
                              return PieChartSectionData(
                                color: color,
                                value: e.value,
                                title: '$pct%',
                                radius: 42,
                                titleStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Breakdown List
                      ...expenseMap.entries.map((entry) {
                        final catName = entry.key;
                        final amount = entry.value;
                        final pct = ((amount / totalExpenses) * 100).toStringAsFixed(1);
                        final icon = CategoryHelper.getIcon(catName, false);
                        final color = CategoryHelper.getColor(catName, false);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkBackground : AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  catName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ),
                              Text(
                                '$pct%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                currencyFormatter.format(amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: primaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // 6. Income Category Breakdown List if present
              if (incomeMap.isNotEmpty) ...[
                Text(
                  'Income Sources Breakdown',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: incomeMap.entries.map((entry) {
                      final source = entry.key;
                      final amount = entry.value;
                      final pct = ((amount / totalIncome) * 100).toStringAsFixed(1);
                      final icon = CategoryHelper.getIcon(source, true);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkBackground : AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.incomeGreen.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: AppTheme.incomeGreen, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                source,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: primaryTextColor,
                                ),
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              currencyFormatter.format(amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.incomeGreen,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String amount,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BarChartData _buildBarChartData(List<TransactionModel> txs, bool isDark) {
    if (_selectedPeriod == ReportPeriod.weekly) {
      // 7 Days: Mon, Tue, Wed, Thu, Fri, Sat, Sun
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dailyExpenses = List.generate(7, (_) => 0.0);
      final dailyIncome = List.generate(7, (_) => 0.0);

      for (final tx in txs) {
        final dayIndex = tx.date.weekday - 1; // 0 = Mon
        if (dayIndex >= 0 && dayIndex < 7) {
          if (tx.isExpense) {
            dailyExpenses[dayIndex] += tx.amount;
          } else {
            dailyIncome[dayIndex] += tx.amount;
          }
        }
      }

      double maxVal = 100.0;
      for (int i = 0; i < 7; i++) {
        if (dailyExpenses[i] > maxVal) maxVal = dailyExpenses[i];
        if (dailyIncome[i] > maxVal) maxVal = dailyIncome[i];
      }

      return BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.15,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < 7) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dayNames[idx],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppTheme.darkDividerColor : const Color(0xFFE2E8F0),
            strokeWidth: 0.8,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: dailyIncome[i],
                color: AppTheme.incomeGreen,
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: dailyExpenses[i],
                color: AppTheme.expenseRose,
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      );
    } else {
      // Monthly 4 Weeks
      final weekExpenses = List.generate(4, (_) => 0.0);
      final weekIncome = List.generate(4, (_) => 0.0);

      for (final tx in txs) {
        final day = tx.date.day;
        int weekIdx = (day - 1) ~/ 7;
        if (weekIdx > 3) weekIdx = 3;
        if (tx.isExpense) {
          weekExpenses[weekIdx] += tx.amount;
        } else {
          weekIncome[weekIdx] += tx.amount;
        }
      }

      double maxVal = 100.0;
      for (int i = 0; i < 4; i++) {
        if (weekExpenses[i] > maxVal) maxVal = weekExpenses[i];
        if (weekIncome[i] > maxVal) maxVal = weekIncome[i];
      }

      return BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.15,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < 4) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Wk ${idx + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppTheme.darkDividerColor : const Color(0xFFE2E8F0),
            strokeWidth: 0.8,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(4, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: weekIncome[i],
                color: AppTheme.incomeGreen,
                width: 14,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: weekExpenses[i],
                color: AppTheme.expenseRose,
                width: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      );
    }
  }
}
