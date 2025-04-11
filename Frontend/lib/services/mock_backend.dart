// lib/services/mock_backend.dart
import 'dart:async';
import 'dart:math';
import 'auth_database.dart';

class MockBackend {
  // Generates a random token (for demonstration purposes only).
  String _generateToken(String email, int id) {
    final random = Random();
    return 'token_${email}_${id}_${random.nextInt(10000)}';
  }

  // Simulate a random network delay.
  Future<void> _simulateNetworkDelay() async {
    final random = Random();
    final delay = Duration(milliseconds: 500 + random.nextInt(1000));
    await Future.delayed(delay);
  }

  /// Simulates a sign-up call, using SQLite persistence.
  Future<Map<String, dynamic>> signUp(String email, String password, String confirmPassword) async {
    await _simulateNetworkDelay();

    if (password != confirmPassword) {
      return {
        'success': false,
        'message': 'Passwords do not match.',
      };
    }

    final db = AuthDatabase.instance;
    final existingUser = await db.getUser(email);
    if (existingUser != null) {
      return {
        'success': false,
        'message': 'User already exists. Please sign in.',
      };
    }

    // Insert new user into the database.
    final userId = await db.createUser({
      'email': email,
      'name': 'User ${DateTime.now().millisecondsSinceEpoch % 10000}',
      'password': password, // Store the password for update later.
      // Initially, extra fields are left null.
    });

    return {
      'success': true,
      'token': _generateToken(email, userId),
      'user': {
        'id': userId,
        'email': email,
        'name': 'User $userId',
        'password': password, // pass along the password
      },
      'message': 'Signup successful.',
    };
  }

  /// Simulates a sign-in call using SQLite.
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    await _simulateNetworkDelay();

    final db = AuthDatabase.instance;
    final user = await db.getUser(email);
    if (user == null) {
      return {
        'success': false,
        'message': 'User not found. Please sign up.',
      };
    }

    if (user['password'] != password) {
      return {
        'success': false,
        'message': 'Incorrect password.',
      };
    }

    return {
      'success': true,
      'token': _generateToken(email, user['id']),
      'user': user,
      'message': 'Login successful.',
    };
  }

  /// Simulates a forgot password call.
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    await _simulateNetworkDelay();

    final db = AuthDatabase.instance;
    final user = await db.getUser(email);
    if (user == null) {
      return {
        'success': false,
        'message': 'Email not found.',
      };
    }

    return {
      'success': true,
      'message': 'A password reset link has been sent to $email.',
    };
  }
}
