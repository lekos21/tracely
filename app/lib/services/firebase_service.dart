import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Configure for production by default - no emulators
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Using Firebase Auth directly (like React) - no need for google_sign_in package

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Chat and AI Functions
  /// Equivalent to your FastAPI endpoints for chat
  
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    required String type, // 'fact' or 'query'
  }) async {
    try {
      final callable = _functions.httpsCallable('process_chat_message');
      final result = await callable.call({
        'message': message,
        'type': type,
      });
      
      // Extract the actual result from the Firebase response
      final backendResponse = result.data['result'] ?? result.data;
      
      return Map<String, dynamic>.from(backendResponse);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Errore di connessione',
      };
    }
  }

  Future<Map<String, dynamic>> saveFact(String factText) async {
    return await sendChatMessage(
      message: factText,
      type: 'fact',
    );
  }

  Future<Map<String, dynamic>> askAI(String query) async {
    return await sendChatMessage(
      message: query,
      type: 'query',
    );
  }

  /// Cards Functions
  /// Generate swipeable cards with AI insights
  
  Future<List<Map<String, dynamic>>> generateCards({
    String cardType = 'mixed', // 'mixed', 'gifts', 'dates', 'insights'
    int count = 5,
  }) async {
    try {
      final callable = _functions.httpsCallable('generate_random_cards');
      final result = await callable.call({
        'type': cardType,
        'count': count,
      });
      
      if (result.data['success']) {
        return List<Map<String, dynamic>>.from(result.data['cards']);
      } else {
        throw Exception(result.data['error'] ?? 'Failed to generate cards');
      }
    } catch (e) {
      print('Error generating cards: $e');
      return [];
    }
  }

  // Alternative method that returns the raw response (for CardsScreen compatibility)
  Future<Map<String, dynamic>> generateRandomCards({
    String type = 'mixed',
    int count = 3,
  }) async {
    try {
      final callable = _functions.httpsCallable('generate_random_cards');
      final result = await callable.call({
        'type': type,
        'count': count,
      });
      
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      print('Error generating random cards: $e');
      return {
        'success': false,
        'error': e.toString(),
        'cards': [],
      };
    }
  }

  /// Recommendation Functions
  /// Generate AI-powered recommendations based on user facts
  
  Future<Map<String, dynamic>> generateRecommendations({
    List<String>? tags, // Optional list of tags to focus on
    int count = 5,
  }) async {
    try {
      final callable = _functions.httpsCallable('generate_recommendations');
      final result = await callable.call({
        'tags': tags,
        'count': count,
      });
      
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      print('Error generating recommendations: $e');
      return {
        'success': false,
        'error': e.toString(),
        'suggestions': [],
      };
    }
  }
  
  Future<Map<String, dynamic>> getRecommendationTags() async {
    try {
      final callable = _functions.httpsCallable('get_recommendation_tags');
      final result = await callable.call({});
      
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      print('Error getting recommendation tags: $e');
      return {
        'success': false,
        'error': e.toString(),
        'available_tags': [],
        'user_tag_stats': {},
      };
    }
  }

  /// Fact Management Functions
  /// Get, update, and delete user facts
  
  Future<Map<String, dynamic>> getUserFacts({
    String? tag,
    int limit = 50,
  }) async {
    try {
      final callable = _functions.httpsCallable('get_user_facts');
      final result = await callable.call({
        'tag': tag,
        'limit': limit,
      });
      
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      print('Error getting user facts: $e');
      return {
        'success': false,
        'error': e.toString(),
        'facts': [],
      };
    }
  }
  
  Future<Map<String, dynamic>> updateFact(String factId, String newFactText) async {
    try {
      final callable = _functions.httpsCallable('update_fact');
      final result = await callable.call({
        'fact_id': factId,
        'fact_text': newFactText,
      });
      
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      print('Error updating fact: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  Future<Map<String, dynamic>> deleteFact(String factId) async {
    try {
      final callable = _functions.httpsCallable('delete_fact');
      final result = await callable.call({
        'fact_id': factId,
      });
      
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      print('Error deleting fact: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Onboarding Functions
  /// Save partner profile from onboarding quiz
  
  Future<bool> savePartnerProfile(Map<String, dynamic> profileData) async {
    try {
      final callable = _functions.httpsCallable('save_onboarding_data');
      final result = await callable.call(profileData);
      
      return result.data['success'] ?? false;
    } catch (e) {
      print('Error saving partner profile: $e');
      return false;
    }
  }

  /// Direct Firestore Operations
  /// For real-time data and local caching
  
  // Get user's facts stream (real-time updates)
  Stream<List<Map<String, dynamic>>> getFactsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('facts')
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get partner profile
  Future<Map<String, dynamic>?> getPartnerProfile() async {
    if (currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        return doc.data()?['partner_profile'];
      }
      return null;
    } catch (e) {
      print('Error getting partner profile: $e');
      return null;
    }
  }

  // Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    if (currentUserId == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      return doc.data()?['onboarding_completed'] ?? false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }

  /// Authentication Functions
  /// Simplified auth management
  
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Always ensure user profile exists
      if (credential.user != null) {
        await _ensureUserProfile(credential.user!);
      }
      
      return credential.user;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Always ensure user profile exists (especially important for new signups)
      if (credential.user != null) {
        await _ensureUserProfile(credential.user!);
      }
      
      return credential.user;
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  // Google Sign-In using Firebase Auth directly (like React)
  Future<User?> signInWithGoogle() async {
    try {
      // Create a GoogleAuthProvider instance
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Add scopes if needed
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      // Sign in with popup (web) or redirect
      final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
      
      // Always ensure user profile exists (for both new and existing users)
      if (userCredential.user != null) {
        await _ensureUserProfile(userCredential.user!);
      }
      
      return userCredential.user;
    } catch (e) {
      print('Google sign in error: $e');
      return null;
    }
  }

  // Ensure user profile exists (create if doesn't exist, update if needed)
  Future<void> _ensureUserProfile(User user) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) {
        // Create new user profile
        await _createUserProfile(user);
      } else {
        // Update existing user profile with latest info from auth provider
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set({
          'email': user.email,
          'name': user.displayName,
          'photo_url': user.photoURL,
          'last_login': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error ensuring user profile: $e');
    }
  }

  // Create user profile for any auth provider
  Future<void> _createUserProfile(User user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
        'email': user.email,
        'name': user.displayName,
        'photo_url': user.photoURL,
        'created_at': DateTime.now().toIso8601String(),
        'last_login': DateTime.now().toIso8601String(),
        'onboarding_completed': false,
        'settings': {
          'notifications': true,
          'theme': 'light',
        },
      });
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }

  // Create user profile in Firestore
  Future<void> createUserProfile(Map<String, dynamic> userData) async {
    if (currentUserId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set(userData);
    } catch (e) {
      print('Error creating user profile: $e');
      throw e;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Utility Functions
  
  // Test connection to backend
  Future<bool> testConnection() async {
    try {
      // Try to call a simple function to test connectivity
      final result = await generateCards(count: 1);
      return result.isNotEmpty;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
