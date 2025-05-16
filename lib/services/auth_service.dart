import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email sign in
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Authentication error: $e');
    }
  }

  // Email sign up with proper timestamp and DateTime handling
  Future<UserCredential> signUpWithEmail(String email, String password, Map<String, dynamic> userData) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Process any DateTime objects to Timestamps for Firestore
      Map<String, dynamic> processedData = _processDateTime(userData);
      
      // Store user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        ...processedData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Authentication error: $e');
    }
  }

  // Google sign in - refactored to handle the PigeonUserDetails error
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Interactive sign in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Sign in canceled by user');
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Safety check to avoid null user
      if (userCredential.user == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Check if this is a new user and add to Firestore if needed
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'displayName': userCredential.user!.displayName,
          'photoURL': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google Sign In error: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (!doc.exists) {
        return null;
      }
      return doc.data();
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    if (currentUser == null) throw Exception('No authenticated user found');
    
    try {
      // Process any DateTime objects to Timestamps for Firestore
      Map<String, dynamic> processedData = _processDateTime(userData);
      
      await _firestore.collection('users').doc(currentUser!.uid).update(processedData);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset error: $e');
    }
  }

  // Helper method to process DateTime to Timestamp
  Map<String, dynamic> _processDateTime(Map<String, dynamic> data) {
    Map<String, dynamic> processedData = {...data};
    
    processedData.forEach((key, value) {
      if (value is DateTime) {
        processedData[key] = Timestamp.fromDate(value);
      }
    });
    
    return processedData;
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email');
      case 'wrong-password':
        return Exception('Incorrect password');
      case 'email-already-in-use':
        return Exception('Email already in use');
      case 'invalid-email':
        return Exception('Invalid email format');
      case 'weak-password':
        return Exception('Password is too weak');
      case 'requires-recent-login':
        return Exception('This operation requires recent authentication. Please log in again.');
      case 'user-disabled':
        return Exception('This user account has been disabled');
      case 'operation-not-allowed':
        return Exception('This operation is not allowed');
      case 'too-many-requests':
        return Exception('Too many requests. Please try again later.');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection.');
      case 'account-exists-with-different-credential':
        return Exception('An account already exists with the same email address but different sign-in credentials.');
      default:
        return Exception('Authentication error: ${e.message}');
    }
  }
}