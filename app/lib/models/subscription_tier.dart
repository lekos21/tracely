import 'package:flutter/material.dart';

enum SubscriptionTier {
  standard('Standard', 'Basic features', 0, [
    'Unlimited AI chat',
    'Basic fact storage',
    'Simple suggestions',
  ]),
  plus('Plus', 'Enhanced experience', 4.99, [
    'Everything in Standard',
    'Advanced personalized cards',
    'Deep relationship insights',
    'Premium suggestions',
    'Data export',
  ]),
  premium('Premium', 'Complete experience', 9.99, [
    'Everything in Plus',
    'AI relationship coach',
    'Predictive insights',
    'Smart event calendar',
    'Priority support',
    'Beta features access',
  ]);

  const SubscriptionTier(this.displayName, this.description, this.monthlyPrice, this.features);

  final String displayName;
  final String description;
  final double monthlyPrice;
  final List<String> features;

  bool get isFree => monthlyPrice == 0;
  
  String get priceText => isFree ? 'Free' : '€${monthlyPrice.toStringAsFixed(2)}/month';
  
  String get badgeText {
    switch (this) {
      case SubscriptionTier.standard:
        return 'BASIC';
      case SubscriptionTier.plus:
        return 'POPULAR';
      case SubscriptionTier.premium:
        return 'PRO';
    }
  }

  // Colors for each tier
  List<Color> get gradientColors {
    switch (this) {
      case SubscriptionTier.standard:
        return [const Color(0xFF6B73FF), const Color(0xFF9F7AEA)];
      case SubscriptionTier.plus:
        return [const Color(0xFFF472B6), const Color(0xFFFB923C)];
      case SubscriptionTier.premium:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
    }
  }

  Color get primaryColor {
    switch (this) {
      case SubscriptionTier.standard:
        return const Color(0xFF6B73FF);
      case SubscriptionTier.plus:
        return const Color(0xFFF472B6);
      case SubscriptionTier.premium:
        return const Color(0xFFFFD700);
    }
  }
}
