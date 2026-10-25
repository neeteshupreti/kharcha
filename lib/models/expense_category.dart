import 'package:flutter/material.dart';

enum ExpenseCategory {
  food('Food & drink', Icons.restaurant_outlined),
  transport('Transport', Icons.directions_bus_outlined),
  housing('Housing', Icons.home_outlined),
  utilities('Utilities', Icons.bolt_outlined),
  health('Health', Icons.medical_services_outlined),
  shopping('Shopping', Icons.shopping_bag_outlined),
  entertainment('Entertainment', Icons.movie_outlined),
  other('Other', Icons.more_horiz);

  const ExpenseCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  static ExpenseCategory fromName(String? name) {
    return ExpenseCategory.values.firstWhere(
      (category) => category.name == name,
      orElse: () => ExpenseCategory.other,
    );
  }
}
