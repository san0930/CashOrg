import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../widgets/category_icon.dart';
import 'add_category_dialog.dart';

class CategoryManagementScreen extends StatefulWidget {
  final CategoryService categoryService;
  final String userId;

  const CategoryManagementScreen({
    super.key,
    required this.categoryService,
    required this.userId,
  });

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    widget.categoryService.addListener(_onServiceUpdate);
    widget.categoryService.fetchCategories(widget.userId);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.categoryService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _openAddCategory(bool isIncome) async {
    await AddCategoryDialog.show(
      context,
      categoryService: widget.categoryService,
      userId: widget.userId,
      isIncome: isIncome,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expenseCategories = widget.categoryService.allExpenseCategories;
    final incomeCategories = widget.categoryService.allIncomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. EXPENSE CATEGORIES SECTION
              _buildCategorySectionHeader(
                title: 'Expense Categories',
                subtitle: 'Manage categories used when adding expenses',
                buttonLabel: '+ Add Category',
                accentColor: AppTheme.expenseRose,
                onAddPressed: () => _openAddCategory(false),
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              _buildCategoryGrid(
                categories: expenseCategories,
                isIncome: false,
                accentColor: AppTheme.expenseRose,
                isDark: isDark,
              ),

              const SizedBox(height: 36),

              // 2. INCOME CATEGORIES SECTION
              _buildCategorySectionHeader(
                title: 'Income Categories',
                subtitle: 'Manage categories used when adding income',
                buttonLabel: '+ Add Category',
                accentColor: AppTheme.incomeGreen,
                onAddPressed: () => _openAddCategory(true),
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              _buildCategoryGrid(
                categories: incomeCategories,
                isIncome: true,
                accentColor: AppTheme.incomeGreen,
                isDark: isDark,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySectionHeader({
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color accentColor,
    required VoidCallback onAddPressed,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  void _confirmDeleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${category.name}"?'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseRose,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await widget.categoryService.deleteCategory(category);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "${category.name}" deleted.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid({
    required List<CategoryModel> categories,
    required bool isIncome,
    required Color accentColor,
    required bool isDark,
  }) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          'No categories found.',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkDividerColor : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final iconData = CategoryHelper.getIcon(
            category.name,
            isIncome,
            customIconKey: category.icon,
          );
          final color = CategoryHelper.getColor(
            category.name,
            isIncome,
            customColorHex: category.color,
          );

          final isCustom = !category.id.startsWith('def-');

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBackground : AppTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCustom
                    ? accentColor.withValues(alpha: 0.5)
                    : (isDark ? AppTheme.darkDividerColor : const Color(0xFFE2E8F0)),
                width: isCustom ? 1.5 : 1.0,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _confirmDeleteCategory(category),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
