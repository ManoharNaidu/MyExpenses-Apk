import 'package:flutter/material.dart';

import '../models/transaction_model.dart';

IconData categoryIconFor(String category) {
  final value = category.trim().toLowerCase();

  if (value.contains('rent') ||
      value.contains('mortgage') ||
      value.contains('home')) {
    return Icons.home_outlined;
  }
  if (value.contains('grocer')) {
    return Icons.shopping_basket_outlined;
  }
  if (value.contains('dining') ||
      value.contains('restaurant') ||
      value.contains('food')) {
    return Icons.restaurant_outlined;
  }
  if (value.contains('transport') || value.contains('travel')) {
    return Icons.directions_car_filled_outlined;
  }
  if (value.contains('utility') ||
      value.contains('electric') ||
      value.contains('water')) {
    return Icons.bolt_outlined;
  }
  if (value.contains('health') ||
      value.contains('medical') ||
      value.contains('doctor')) {
    return Icons.medical_services_outlined;
  }
  if (value.contains('education') ||
      value.contains('school') ||
      value.contains('course')) {
    return Icons.school_outlined;
  }
  if (value.contains('insurance')) {
    return Icons.verified_user_outlined;
  }
  if (value.contains('entertain') ||
      value.contains('movie') ||
      value.contains('music')) {
    return Icons.movie_outlined;
  }
  if (value.contains('social') ||
      value.contains('friend') ||
      value.contains('party')) {
    return Icons.people_alt_outlined;
  }
  if (value.contains('shopping')) {
    return Icons.shopping_bag_outlined;
  }
  if (value.contains('subscription')) {
    return Icons.subscriptions_outlined;
  }
  if (value.contains('phone') ||
      value.contains('internet') ||
      value.contains('mobile')) {
    return Icons.smartphone_outlined;
  }
  if (value.contains('salary') ||
      value.contains('bonus') ||
      value.contains('allowance')) {
    return Icons.payments_outlined;
  }
  if (value.contains('investment')) {
    return Icons.trending_up_rounded;
  }
  if (value.contains('freelance') || value.contains('work')) {
    return Icons.work_outline_rounded;
  }
  if (value.contains('gift')) {
    return Icons.card_giftcard_outlined;
  }
  if (value.contains('transfer')) {
    return Icons.swap_horiz_rounded;
  }

  return Icons.category_outlined;
}

Color transactionTypeColor(BuildContext context, TxType type) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (type == TxType.income) {
    return isDark ? const Color(0xFF4CAF7D) : const Color(0xFF2D7A4F);
  }
  return isDark ? const Color(0xFFE05C5C) : const Color(0xFFC0392B);
}
