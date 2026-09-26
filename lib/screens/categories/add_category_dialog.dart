import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/icon_picker.dart';

class AddCategoryDialog extends StatefulWidget {
  final CategoryService categoryService;
  final String userId;
  final bool isIncome;

  const AddCategoryDialog({
    super.key,
    required this.categoryService,
    required this.userId,
    required this.isIncome,
  });

  static Future<CategoryModel?> show(
    BuildContext context, {
    required CategoryService categoryService,
    required String userId,
    required bool isIncome,
  }) {
    return showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCategoryDialog(
        categoryService: categoryService,
        userId: userId,
        isIncome: isIncome,
      ),
    );
  }

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  CategoryIconItem? _selectedIcon;
  Color? _selectedColor;
  bool _isSaving = false;
  String? _validationError;

  final List<Color> _presetColors = const [
    Color(0xFFF59E0B), // Amber
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEF4444), // Red
    Color(0xFF14B8A6), // Teal
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Emerald Green
    Color(0xFF6366F1), // Indigo
    Color(0xFFF97316), // Orange
    Color(0xFF64748B), // Slate
  ];

  @override
  void initState() {
    super.initState();
    // Default select first icon in collection
    final icons = widget.isIncome
        ? CategoryHelper.incomeIconCollection
        : CategoryHelper.expenseIconCollection;
    if (icons.isNotEmpty) {
      _selectedIcon = icons.first;
    }
    _selectedColor = widget.isIncome ? AppTheme.incomeGreen : AppTheme.expenseRose;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveCategory() async {
    setState(() {
      _validationError = null;
    });

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _validationError = 'Category name cannot be empty.';
      });
      return;
    }

    if (_selectedIcon == null) {
      setState(() {
        _validationError = 'Please choose an icon from the collection.';
      });
      return;
    }

    // Check duplicate
    final existingNames = widget.isIncome
        ? widget.categoryService.allIncomeCategoryNames
        : widget.categoryService.allExpenseCategoryNames;
    if (existingNames.any((n) => n.toLowerCase() == name.toLowerCase())) {
      setState(() {
        _validationError =
            'A ${widget.isIncome ? "income" : "expense"} category named "$name" already exists.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final colorHex = _selectedColor != null
        ? '0x${_selectedColor!.toARGB32().toRadixString(16).toUpperCase()}'
        : null;

    final newCategory = CategoryModel(
      id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.userId,
      name: name,
      icon: _selectedIcon!.key,
      color: colorHex,
      type: widget.isIncome ? 'income' : 'expense',
      createdAt: DateTime.now(),
    );

    final success = await widget.categoryService.addCategory(newCategory);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newCategory.name} added to ${widget.isIncome ? "Income" : "Expense"} categories!'),
            backgroundColor: widget.isIncome ? AppTheme.incomeGreen : AppTheme.expenseRose,
          ),
        );
        Navigator.pop(context, newCategory);
      } else {
        setState(() {
          _validationError = widget.categoryService.errorMessage ?? 'Failed to add category.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isIncome ? AppTheme.incomeGreen : AppTheme.expenseRose;
    final iconCollection = widget.isIncome
        ? CategoryHelper.incomeIconCollection
        : CategoryHelper.expenseIconCollection;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isIncome ? Icons.add_card_rounded : Icons.category_rounded,
                      color: themeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isIncome ? 'Add Income Category' : 'Add Expense Category',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Validation Message if any
              if (_validationError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.expenseRose, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: const TextStyle(
                            color: AppTheme.expenseRose,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Category Name Field
              CustomTextField(
                controller: _nameController,
                label: 'Category Name',
                hintText: widget.isIncome ? 'e.g., Scholarship, Commission' : 'e.g., Groceries, Fuel',
                prefixIcon: Icons.label_outline_rounded,
                onChanged: (_) {
                  if (_validationError != null) {
                    setState(() {
                      _validationError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // 2. Choose Icon Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Choose Icon',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (_selectedIcon != null)
                    Text(
                      'Selected: ${_selectedIcon!.label}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Reusable Icon Picker Component
              IconPickerGrid(
                icons: iconCollection,
                selectedIconKey: _selectedIcon?.key,
                accentColor: themeColor,
                onIconSelected: (item) {
                  setState(() {
                    _selectedIcon = item;
                    _validationError = null;
                  });
                },
              ),
              const SizedBox(height: 20),

              // 3. Optional Color Picker
              const Text(
                'Theme Color (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetColors.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final color = _presetColors[index];
                    final isSelected = _selectedColor?.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppTheme.textPrimary : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // 4. Save Category Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                ),
                onPressed: _isSaving ? null : _saveCategory,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(widget.isIncome ? 'Save Income Category' : 'Save Expense Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
