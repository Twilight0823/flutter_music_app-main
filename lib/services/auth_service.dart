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
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Email sign up with proper timestamp and DateTime handling
  Future<UserCredential> signUpWithEmail(String email, String password, Map<String, dynamic> userData) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Process any DateTime objects to Timestamps for Firestore
      Map<String, dynamic> processedData = {...userData};
      
      // Convert DateTime objects to Timestamps for Firestore storage
      processedData.forEach((key, value) {
        if (value is DateTime) {
          processedData[key] = Timestamp.fromDate(value);
        }
      });
      
      // Store user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        ...processedData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google sign in
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Sign in canceled by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
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
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Sign out from Google
      await _auth.signOut(); // Sign out from Firebase
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
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
      Map<String, dynamic> processedData = {...userData};
      
      processedData.forEach((key, value) {
        if (value is DateTime) {
          processedData[key] = Timestamp.fromDate(value);
        }
      });
      
      await _firestore.collection('users').doc(currentUser!.uid).update(processedData);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
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
        default:
          return Exception('Authentication error: ${e.message}');
      }
    }
    return Exception('Authentication error: $e');
  }
}