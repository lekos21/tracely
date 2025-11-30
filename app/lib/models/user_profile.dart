import 'package:firebase_auth/firebase_auth.dart';
import 'subscription_tier.dart';

class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final SubscriptionTier currentTier;
  final DateTime? subscriptionExpiresAt;
  final bool subscriptionActive;
  final DateTime createdAt;
  final DateTime lastLogin;
  final Map<String, dynamic> settings;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.currentTier = SubscriptionTier.standard,
    this.subscriptionExpiresAt,
    this.subscriptionActive = false,
    required this.createdAt,
    required this.lastLogin,
    this.settings = const {},
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String id) {
    return UserProfile(
      id: id,
      email: data['email'] ?? '',
      name: data['name'],
      photoUrl: data['photo_url'],
      currentTier: _parseTier(data['subscription_tier']),
      subscriptionExpiresAt: data['subscription_expires_at'] != null
          ? DateTime.parse(data['subscription_expires_at'])
          : null,
      subscriptionActive: data['subscription_active'] ?? false,
      createdAt: DateTime.parse(data['created_at']),
      lastLogin: DateTime.parse(data['last_login']),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
    );
  }

  factory UserProfile.fromFirebaseUser(User user) {
    return UserProfile(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName,
      photoUrl: user.photoURL,
      currentTier: SubscriptionTier.standard,
      subscriptionActive: false,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
  }

  static SubscriptionTier _parseTier(String? tierString) {
    switch (tierString) {
      case 'plus':
        return SubscriptionTier.plus;
      case 'premium':
        return SubscriptionTier.premium;
      default:
        return SubscriptionTier.standard;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'photo_url': photoUrl,
      'subscription_tier': currentTier.name,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'subscription_active': subscriptionActive,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin.toIso8601String(),
      'settings': settings,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    SubscriptionTier? currentTier,
    DateTime? subscriptionExpiresAt,
    bool? subscriptionActive,
    DateTime? createdAt,
    DateTime? lastLogin,
    Map<String, dynamic>? settings,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      currentTier: currentTier ?? this.currentTier,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      subscriptionActive: subscriptionActive ?? this.subscriptionActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      settings: settings ?? this.settings,
    );
  }

  String get displayName => name ?? email.split('@').first;
  
  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  bool get hasActivePaidSubscription => 
      subscriptionActive && 
      currentTier != SubscriptionTier.standard &&
      (subscriptionExpiresAt?.isAfter(DateTime.now()) ?? false);
}
