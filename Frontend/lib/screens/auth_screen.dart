import 'package:flutter/foundation.dart';
import 'main_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/mock_backend.dart'; // Adjust the path if necessary
import 'profile_creation_screen.dart';
// Placeholder MainScreen for post-login navigation.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("UberChef Home", style: GoogleFonts.lato())),
      body: Center(child: Text("Welcome to UberChef!", style: GoogleFonts.lato(fontSize: 24))),
    );
  }
}

enum AuthFormType { login, signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthFormType _formType = AuthFormType.login;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _rememberMe = false;

  // Instance of the upgraded mock backend (using SQLite)
  final MockBackend _backend = MockBackend();

  void _switchFormType() {
    setState(() {
      _formType = _formType == AuthFormType.login ? AuthFormType.signup : AuthFormType.login;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> response;
      if (_formType == AuthFormType.login) {
        response = await _backend.signIn(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        response = await _backend.signUp(
          _emailController.text,
          _passwordController.text,
          _confirmPasswordController.text,
        );
      }
      if (response['success'] == true) {
        if (kDebugMode) {
          print(response['message']);
          print('Token: ${response['token']}');
        }
        if (!mounted) return;
        if (_formType == AuthFormType.signup) {
          // Navigate to profile creation with the newly created user record.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileCreationScreen(user: response['user']),
            ),
          );
        } else {
        // Handle login: navigate to your main screen.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainPage()),
          );
        }
      } else {
        if (kDebugMode) {
          print(response['message']);
        }
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
      }
    }
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.black87,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor, size: 24),
        label: Text(label, style: TextStyle(color: iconColor, fontSize: 16)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white70, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.white.withOpacity(0.2),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.lato(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.15),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white38, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      errorStyle: GoogleFonts.lato(color: Colors.redAccent, fontSize: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLogin = _formType == AuthFormType.login;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isLogin ? 'Sign In' : 'Sign Up',
          style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.black87],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight - MediaQuery.of(context).padding.top,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Large Heading
                            Text(
                              isLogin ? 'Welcome Back!' : 'Create Your Account',
                              style: GoogleFonts.lato(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isLogin ? 'Sign in to continue' : 'Join us and explore the best chefs near you',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 36),
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration('Email', Icons.email_outlined),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration('Password', Icons.lock_outline),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Confirm password field if signing up
                            if (!isLogin) ...[
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: _buildInputDecoration('Confirm Password', Icons.lock),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Confirm your password';
                                  } else if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Row for "Remember me" and "Forgot Password"
                            if (isLogin)
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    activeColor: Colors.white24,
                                    checkColor: Colors.white,
                                    onChanged: (bool? val) {
                                      setState(() {
                                        _rememberMe = val ?? false;
                                      });
                                    },
                                  ),
                                  Text(
                                    'Remember me',
                                    style: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      if (kDebugMode) {
                                        print('Forgot Password');
                                      }
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.lato(color: Colors.orangeAccent),
                                    ),
                                  ),
                                ],
                              ),
                            if (isLogin) const SizedBox(height: 16),
                            // Submit button
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.black,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isLogin ? 'Sign In' : 'Sign Up',
                                style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Social login separator text
                            Center(
                              child: Text(
                                'Or continue with',
                                style: GoogleFonts.lato(color: Colors.white70, fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Social Buttons
                            Row(
                              children: [
                                _buildSocialButton(
                                  label: 'Google',
                                  icon: Icons.g_mobiledata,
                                  onPressed: () {
                                    if (kDebugMode) {
                                      print('Google Sign In');
                                    }
                                  },
                                ),
                                const SizedBox(width: 16),
                                _buildSocialButton(
                                  label: 'Apple',
                                  icon: Icons.apple,
                                  onPressed: () {
                                    if (kDebugMode) {
                                      print('Apple Sign In');
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Toggle form type (login/signup)
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLogin ? "Don't have an account? " : "Already have an account? ",
                                    style: GoogleFonts.lato(color: Colors.white70, fontSize: 16),
                                  ),
                                  GestureDetector(
                                    onTap: _switchFormType,
                                    child: Text(
                                      isLogin ? 'Sign Up' : 'Sign In',
                                      style: GoogleFonts.lato(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: Container()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
