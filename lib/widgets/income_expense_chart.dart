import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/transaction_model.dart';

class IncomeExpensePieChart extends StatefulWidget {
  final double totalIncome;
  final double totalExpenses;

  const IncomeExpensePieChart({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
  });

  @override
  State<IncomeExpensePieChart> createState() => _IncomeExpensePieChartState();
}

class _IncomeExpensePieChartState extends State<IncomeExpensePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSum = widget.totalIncome + widget.totalExpenses;
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    if (totalSum <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppTheme.darkDividerColor : const Color(0xFFF1F5F9),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 40,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Income vs Expense Breakdown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add transactions to view financial distribution chart',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final incomePercent = ((widget.totalIncome / totalSum) * 100).toStringAsFixed(1);
    final expensePercent = ((widget.totalExpenses / totalSum) * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppTheme.darkDividerColor : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0x06000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Income vs Expense',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: AppTheme.incomeGreen,
                          value: widget.totalIncome,
                          title: '$incomePercent%',
                          radius: touchedIndex == 0 ? 52 : 46,
                          titleStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: AppTheme.expenseRose,
                          value: widget.totalExpenses,
                          title: '$expensePercent%',
                          radius: touchedIndex == 1 ? 52 : 46,
                          titleStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendTile(
                      title: 'Total Income',
                      amount: currencyFormat.format(widget.totalIncome),
                      percentage: '$incomePercent%',
                      color: AppTheme.incomeGreen,
                      icon: Icons.arrow_downward_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildLegendTile(
                      title: 'Total Expenses',
                      amount: currencyFormat.format(widget.totalExpenses),
                      percentage: '$expensePercent%',
                      color: AppTheme.expenseRose,
                      icon: Icons.arrow_upward_rounded,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendTile({
    required String title,
    required String amount,
    required String percentage,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '($percentage)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Category Expense Breakdown Pie Chart for account filtering
class AccountCategoryPieChart extends StatefulWidget {
  final List<TransactionModel> transactions;
  final String title;

  const AccountCategoryPieChart({
    super.key,
    required this.transactions,
    required this.title,
  });

  @override
  State<AccountCategoryPieChart> createState() => _AccountCategoryPieChartState();
}

class _AccountCategoryPieChartState extends State<AccountCategoryPieChart> {
  int touchedIndex = -1;

  final List<Color> chartColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFEC4899), // Pink
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFEF4444), // Red
    const Color(0xFF06B6D4), // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenses = widget.transactions.where((t) => t.isExpense).toList();

    final Map<String, double> categoryMap = {};
    double totalExpenseSum = 0;

    for (final tx in expenses) {
      categoryMap[tx.category] = (categoryMap[tx.category] ?? 0.0) + tx.amount;
      totalExpenseSum += tx.amount;
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    if (expenses.isEmpty || totalExpenseSum <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppTheme.darkDividerColor : const Color(0xFFF1F5F9),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 40,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.title} Breakdown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No expenses recorded for this account',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final entries = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppTheme.darkDividerColor : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0x06000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.title} Expenses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ),
              Text(
                currencyFormat.format(totalExpenseSum),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.expenseRose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // Pie Chart Graphic
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                    sections: List.generate(entries.length, (i) {
                      final isTouched = i == touchedIndex;
                      final pct = (entries[i].value / totalExpenseSum) * 100;
                      final color = chartColors[i % chartColors.length];

                      return PieChartSectionData(
                        color: color,
                        value: entries[i].value,
                        title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                        radius: isTouched ? 44 : 38,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Breakdown Legend List
              Expanded(
                child: Column(
                  children: List.generate(entries.length, (i) {
                    final pct = ((entries[i].value / totalExpenseSum) * 100).toStringAsFixed(0);
                    final color = chartColors[i % chartColors.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entries[i].key,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
