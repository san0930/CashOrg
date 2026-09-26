import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class CategoryIconItem {
  final String key;
  final String label;
  final IconData iconData;

  const CategoryIconItem({
    required this.key,
    required this.label,
    required this.iconData,
  });
}

class CategoryHelper {
  static const List<String> expenseCategories = [
    'Food',
    'Travel',
    'Shopping',
    'Bills',
    'Education',
    'Entertainment',
    'Groceries',
    'Other',
  ];

  static const List<String> incomeSources = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Bonus',
    'Gift',
    'Interest',
    'Other',
  ];

  // Predefined Expense Icons Collection
  static const List<CategoryIconItem> expenseIconCollection = [
    CategoryIconItem(key: 'food', label: 'Food', iconData: Icons.restaurant_rounded),
    CategoryIconItem(key: 'travel', label: 'Travel', iconData: Icons.directions_bus_rounded),
    CategoryIconItem(key: 'shopping', label: 'Shopping', iconData: Icons.shopping_bag_rounded),
    CategoryIconItem(key: 'bills', label: 'Bills', iconData: Icons.receipt_long_rounded),
    CategoryIconItem(key: 'education', label: 'Education', iconData: Icons.school_rounded),
    CategoryIconItem(key: 'entertainment', label: 'Entertainment', iconData: Icons.sports_esports_rounded),
    CategoryIconItem(key: 'health', label: 'Health', iconData: Icons.medical_services_rounded),
    CategoryIconItem(key: 'home', label: 'Home', iconData: Icons.home_rounded),
    CategoryIconItem(key: 'car', label: 'Car', iconData: Icons.directions_car_rounded),
    CategoryIconItem(key: 'sports', label: 'Sports', iconData: Icons.fitness_center_rounded),
    CategoryIconItem(key: 'gift', label: 'Gift', iconData: Icons.card_giftcard_rounded),
    CategoryIconItem(key: 'pet', label: 'Pet', iconData: Icons.pets_rounded),
    CategoryIconItem(key: 'coffee', label: 'Coffee', iconData: Icons.local_cafe_rounded),
    CategoryIconItem(key: 'phone', label: 'Phone', iconData: Icons.phone_iphone_rounded),
    CategoryIconItem(key: 'clothing', label: 'Clothing', iconData: Icons.checkroom_rounded),
    CategoryIconItem(key: 'beauty', label: 'Beauty', iconData: Icons.face_rounded),
    CategoryIconItem(key: 'books', label: 'Books', iconData: Icons.menu_book_rounded),
    CategoryIconItem(key: 'flight', label: 'Flight', iconData: Icons.flight_rounded),
    CategoryIconItem(key: 'groceries', label: 'Groceries', iconData: Icons.local_grocery_store_rounded),
    CategoryIconItem(key: 'fuel', label: 'Fuel', iconData: Icons.local_gas_station_rounded),
    CategoryIconItem(key: 'more', label: 'More', iconData: Icons.more_horiz_rounded),
  ];

  // Predefined Income Icons Collection
  static const List<CategoryIconItem> incomeIconCollection = [
    CategoryIconItem(key: 'salary', label: 'Salary', iconData: Icons.work_rounded),
    CategoryIconItem(key: 'business', label: 'Business', iconData: Icons.storefront_rounded),
    CategoryIconItem(key: 'freelance', label: 'Freelance', iconData: Icons.laptop_mac_rounded),
    CategoryIconItem(key: 'investment', label: 'Investment', iconData: Icons.trending_up_rounded),
    CategoryIconItem(key: 'bonus', label: 'Bonus', iconData: Icons.emoji_events_rounded),
    CategoryIconItem(key: 'gift', label: 'Gift', iconData: Icons.card_giftcard_rounded),
    CategoryIconItem(key: 'interest', label: 'Interest', iconData: Icons.percent_rounded),
    CategoryIconItem(key: 'bank', label: 'Bank', iconData: Icons.account_balance_rounded),
    CategoryIconItem(key: 'wallet', label: 'Wallet', iconData: Icons.account_balance_wallet_rounded),
    CategoryIconItem(key: 'money', label: 'Money', iconData: Icons.attach_money_rounded),
    CategoryIconItem(key: 'cash', label: 'Cash', iconData: Icons.payments_rounded),
    CategoryIconItem(key: 'home', label: 'Home', iconData: Icons.house_rounded),
    CategoryIconItem(key: 'scholarship', label: 'Scholarship', iconData: Icons.school_rounded),
    CategoryIconItem(key: 'commission', label: 'Commission', iconData: Icons.handshake_rounded),
    CategoryIconItem(key: 'more', label: 'More', iconData: Icons.more_horiz_rounded),
  ];

  static IconData getIconDataFromKey(String iconKey, {bool isIncome = false}) {
    final collection = isIncome ? incomeIconCollection : expenseIconCollection;
    for (final item in collection) {
      if (item.key.toLowerCase() == iconKey.toLowerCase() ||
          item.label.toLowerCase() == iconKey.toLowerCase()) {
        return item.iconData;
      }
    }
    // Also check cross collection fallback
    final crossCollection = isIncome ? expenseIconCollection : incomeIconCollection;
    for (final item in crossCollection) {
      if (item.key.toLowerCase() == iconKey.toLowerCase() ||
          item.label.toLowerCase() == iconKey.toLowerCase()) {
        return item.iconData;
      }
    }
    return isIncome ? Icons.account_balance_wallet_rounded : Icons.category_rounded;
  }

  static IconData getIcon(String category, bool isIncome, {String? customIconKey}) {
    if (customIconKey != null && customIconKey.isNotEmpty) {
      return getIconDataFromKey(customIconKey, isIncome: isIncome);
    }

    final keyToFind = category.toLowerCase().trim();

    if (isIncome) {
      switch (keyToFind) {
        case 'salary':
          return Icons.work_rounded;
        case 'freelance':
          return Icons.laptop_mac_rounded;
        case 'business':
          return Icons.storefront_rounded;
        case 'investment':
          return Icons.show_chart_rounded;
        case 'bonus':
          return Icons.emoji_events_rounded;
        case 'gift':
          return Icons.card_giftcard_rounded;
        case 'interest':
          return Icons.percent_rounded;
        case 'scholarship':
          return Icons.school_rounded;
        case 'commission':
          return Icons.handshake_rounded;
        case 'bank':
          return Icons.account_balance_rounded;
        case 'wallet':
          return Icons.account_balance_wallet_rounded;
        case 'money':
          return Icons.attach_money_rounded;
        case 'cash':
          return Icons.payments_rounded;
        default:
          return getIconDataFromKey(keyToFind, isIncome: true);
      }
    }

    switch (keyToFind) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'travel':
        return Icons.directions_bus_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'entertainment':
        return Icons.sports_esports_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'sports':
        return Icons.fitness_center_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'pet':
        return Icons.pets_rounded;
      case 'coffee':
        return Icons.local_cafe_rounded;
      case 'phone':
        return Icons.phone_iphone_rounded;
      case 'clothing':
        return Icons.checkroom_rounded;
      case 'beauty':
        return Icons.face_rounded;
      case 'books':
      case 'book':
        return Icons.menu_book_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'groceries':
        return Icons.local_grocery_store_rounded;
      case 'fuel':
        return Icons.local_gas_station_rounded;
      default:
        return getIconDataFromKey(keyToFind, isIncome: false);
    }
  }

  static Color getColor(String category, bool isIncome, {String? customColorHex}) {
    if (customColorHex != null && customColorHex.isNotEmpty) {
      final hex = customColorHex.replaceAll('#', '');
      final val = int.tryParse(hex.startsWith('0x') ? hex : '0xFF$hex');
      if (val != null) {
        return Color(val);
      }
    }

    if (isIncome) {
      return AppTheme.incomeGreen;
    }

    switch (category.toLowerCase().trim()) {
      case 'food':
        return const Color(0xFFF59E0B); // Amber
      case 'travel':
        return const Color(0xFF3B82F6); // Blue
      case 'shopping':
        return const Color(0xFF8B5CF6); // Purple
      case 'bills':
        return const Color(0xFFEF4444); // Red
      case 'education':
        return const Color(0xFF14B8A6); // Teal
      case 'entertainment':
        return const Color(0xFFEC4899); // Pink
      case 'groceries':
        return const Color(0xFF10B981); // Emerald
      case 'health':
        return const Color(0xFF06B6D4); // Cyan
      case 'home':
        return const Color(0xFF6366F1); // Indigo
      case 'car':
      case 'fuel':
        return const Color(0xFFF97316); // Orange
      default:
        return const Color(0xFF64748B); // Slate
    }
  }
}
