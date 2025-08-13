import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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

  // Simple test function to debug connectivity
  Future<Map<String, dynamic>> testFirebaseConnection() async {
    try {
      print('DEBUG: Testing connection with test_function');
      final callable = _functions.httpsCallable('test_function');
      final result = await callable.call({});
      
      print('DEBUG: test_function response: ${result.data}');
      return {
        'success': true,
        'message': 'Connection test successful',
        'data': result.data,
      };
    } catch (e) {
      print('ERROR: test_function failed with: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Connection test failed',
      };
    }
  }

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

  /// New Chat Agent Functions
  /// Conversational chat with session persistence
  
  Future<Map<String, dynamic>> sendChatAgentMessage(String message) async {
    try {
      final callable = _functions.httpsCallable('send_chat_message');
      final result = await callable.call({
        'message': message,
      });
      
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'response': 'Errore di connessione. Riprova.',
      };
    }
  }
  
  Future<Map<String, dynamic>> getChatHistory() async {
    try {
      final callable = _functions.httpsCallable('get_chat_history');
      final result = await callable.call({});
      
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'messages': [],
      };
    }
  }
  
  Future<Map<String, dynamic>> clearChatSession() async {
    try {
      final callable = _functions.httpsCallable('clear_chat_session');
      final result = await callable.call({});
      
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// New Client-Side Chat Function
  /// Sends conversation history with each message for context
  Future<Map<String, dynamic>> chatWithContext({
    required String message,
    required List<Map<String, dynamic>> conversationHistory,
  }) async {
    try {
      final callable = _functions.httpsCallable('chat_with_context');
      final result = await callable.call({
        'message': message,
        'conversation_history': conversationHistory,
      });
      
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'response': 'Errore di connessione. Riprova.',
      };
    }
  }

  /// Cards Functions
  /// Generate swipeable cards with AI insights
  
  Future<List<Map<String, dynamic>>> generateCards({
    String cardType = 'mixed', // 'mixed', 'gifts', 'dates', 'insights'
    int count = 8,
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
      // Wait for authentication to be ready
      if (_auth.currentUser == null) {
        print('ERROR: No authenticated user for generateRecommendations');
        return {
          'success': false,
          'error': 'Authentication required',
          'suggestions': [],
        };
      }
      
      print('DEBUG: Calling generate_recommendations with tags: $tags, count: $count, user: ${_auth.currentUser?.uid}');
      final callable = _functions.httpsCallable('generate_recommendations');
      final result = await callable.call({
        'tags': tags,
        'count': count,
      });
      
      print('DEBUG: generate_recommendations response: ${result.data}');
      // Handle response format consistently like process_chat_message
      // Normalize response to Map<String, dynamic> safely across platforms
      final raw = result.data is Map ? result.data as Map : <String, dynamic>{};
      final backendResponse = raw.containsKey('result') ? raw['result'] : raw;

      // Coerce to Map<String, dynamic>
      final Map<String, dynamic> normalized = {};
      (backendResponse as Map).forEach((key, value) {
        normalized[key.toString()] = value;
      });

      // Normalize suggestions list items to Map<String, dynamic>
      if (normalized['suggestions'] is List) {
        final list = normalized['suggestions'] as List;
        normalized['suggestions'] = list.map((item) {
          if (item is Map) {
            final m = <String, dynamic>{};
            item.forEach((k, v) => m[k.toString()] = v);
            return m;
          }
          // Fallback: if item is a string, wrap it
          return { 'sentence': item?.toString() ?? '' };
        }).toList();
      }

      return normalized;
    } catch (e) {
      print('ERROR: generateRecommendations failed with: $e');
      print('ERROR: Exception type: ${e.runtimeType}');
      if (e.toString().contains('UNAUTHENTICATED')) {
        print('ERROR: Authentication issue detected');
      } else if (e.toString().contains('NOT_FOUND')) {
        print('ERROR: Function not found - check deployment');
      } else if (e.toString().contains('CORS')) {
        print('ERROR: CORS issue detected');
      }
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
      // Wait for authentication to be ready
      if (_auth.currentUser == null) {
        print('ERROR: No authenticated user for getUserFacts');
        return {
          'success': false,
          'error': 'Authentication required',
          'facts': [],
        };
      }
      
      print('DEBUG: Calling get_user_facts with tag: $tag, limit: $limit, user: ${_auth.currentUser?.uid}');
      final callable = _functions.httpsCallable('get_user_facts');
      final result = await callable.call({
        'tag': tag,
        'limit': limit,
      });
      
      print('DEBUG: get_user_facts response: ${result.data}');
      // Handle response format consistently like process_chat_message
      final backendResponse = result.data['result'] ?? result.data;
      // Fix type casting issue for mobile
      return Map<String, dynamic>.from(backendResponse as Map);
    } catch (e) {
      print('ERROR: getUserFacts failed with: $e');
      print('ERROR: Exception type: ${e.runtimeType}');
      if (e.toString().contains('UNAUTHENTICATED')) {
        print('ERROR: Authentication issue detected');
      } else if (e.toString().contains('NOT_FOUND')) {
        print('ERROR: Function not found - check deployment');
      } else if (e.toString().contains('CORS')) {
        print('ERROR: CORS issue detected');
      }
      return {
        'success': false,
        'error': e.toString(),
        'facts': [],
      };
    }
  }
  
  Future<Map<String, dynamic>> updateFact(String factId, String newFactText, {List<String>? tags}) async {
    try {
      final callable = _functions.httpsCallable('update_fact');
      final Map<String, dynamic> params = {
        'fact_id': factId,
        'fact_text': newFactText,
      };
      
      // Add tags if provided
      if (tags != null) {
        params['tags'] = tags;
      }
      
      final result = await callable.call(params);
      
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
      print('DEBUG: Starting Google Sign-In process...');
      
      if (kIsWeb) {
        // Use Firebase Auth directly for web to avoid People API dependency
        print('DEBUG: Using Firebase Auth for web platform');
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        
        // Add scopes if needed
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        print('DEBUG: Triggering Firebase Auth popup...');
        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        
        print('DEBUG: Firebase web sign-in successful: ${userCredential.user?.email}');
        
        // Always ensure user profile exists
        if (userCredential.user != null) {
          await _ensureUserProfile(userCredential.user!);
        }
        
        return userCredential.user;
      } else {
        // Use GoogleSignIn package for mobile platforms
        print('DEBUG: Using GoogleSignIn package for mobile platform');
        final GoogleSignIn googleSignIn = GoogleSignIn();
        print('DEBUG: GoogleSignIn initialized');
        
        // Trigger the authentication flow
        print('DEBUG: Triggering Google Sign-In flow...');
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        // If the user cancels the sign-in process
        if (googleUser == null) {
          print('DEBUG: User cancelled Google Sign-In');
          return null;
        }
        
        print('DEBUG: Google user obtained: ${googleUser.email}');
        
        // Obtain the auth details from the request
        print('DEBUG: Getting authentication details...');
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        print('DEBUG: Access token present: ${googleAuth.accessToken != null}');
        print('DEBUG: ID token present: ${googleAuth.idToken != null}');
        
        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        print('DEBUG: Firebase credential created, signing in...');
        
        // Sign in to Firebase with the Google credential
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        
        print('DEBUG: Firebase sign-in successful: ${userCredential.user?.email}');
        
        // Always ensure user profile exists (for both new and existing users)
        if (userCredential.user != null) {
          await _ensureUserProfile(userCredential.user!);
        }
        
        return userCredential.user;
      }
    } catch (e) {
      print('ERROR: Google sign in failed: $e');
      print('ERROR: Exception type: ${e.runtimeType}');
      print('ERROR: Stack trace: ${StackTrace.current}');
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
