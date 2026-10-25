import 'package:flutter/material.dart';

@immutable
class SavingCategory {
  const SavingCategory(
      {required this.name, required this.label, required this.icon});

  final String name;
  final String label;
  final IconData icon;

  static const List<SavingCategory> values = [
    SavingCategory(name: 'cash', label: 'Cash', icon: Icons.money),
    SavingCategory(name: 'bank', label: 'Bank', icon: Icons.account_balance),
    SavingCategory(
        name: 'investment', label: 'Investment', icon: Icons.trending_up),
    SavingCategory(name: 'piggyBank', label: 'Piggy Bank', icon: Icons.savings),
    SavingCategory(name: 'other', label: 'Other', icon: Icons.category),
  ];

  static SavingCategory fromName(String? name) {
    return values.firstWhere(
      (category) => category.name == name,
      orElse: () => values.last,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SavingCategory && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
