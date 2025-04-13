import 'package:flutter/foundation.dart';
import 'main_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/mock_backend.dart';
import 'profile_creation_screen.dart';
import 'package:flutter/services.dart';

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

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.white,
    Color backgroundColor = Colors.transparent,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor, size: 22),
        label: Text(
          label,
          style: GoogleFonts.lato(
            color: iconColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white24, width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.lato(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(15),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
        borderRadius: BorderRadius.circular(15),
      ),
      errorStyle: GoogleFonts.lato(color: Colors.redAccent, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  Future<void> _submit() async {
    // Masquer le clavier
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

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

        // Animation de succès avant navigation
        setState(() {
          _isLoading = false;
        });

        // Vibration légère pour retour haptique
        HapticFeedback.mediumImpact();

        if (_formType == AuthFormType.signup) {
          // Navigate to profile creation with the newly created user record.
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => ProfileCreationScreen(user: response['user']),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        } else {
          // Handle login: navigate to your main screen.
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => const MainPage(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      } else {
        if (kDebugMode) {
          print(response['message']);
        }
        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(child: Text(response['message'])),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    }
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                            // Logo animé
                            Center(
                              child: Hero(
                                tag: 'logo',
                                child: Image.asset(
                                  'assets/logo.png',
                                  height: 90,
                                  width: 90,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Large Heading
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.25),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                isLogin ? 'Welcome Back!' : 'Create Your Account',
                                key: ValueKey<bool>(isLogin),
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                isLogin ? 'Sign in to continue to UberChef' : 'Join us and explore the best chefs near you',
                                key: ValueKey<bool>(isLogin),
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Email field avec animation
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 600),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - value) * 20),
                                    child: child,
                                  ),
                                );
                              },
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: _buildInputDecoration('Email', Icons.email_outlined),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter your email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password field avec animation
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 600),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - value) * 20),
                                    child: child,
                                  ),
                                );
                              },
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: _buildInputDecoration(
                                  'Password',
                                  Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter your password';
                                  }
                                  if (_formType == AuthFormType.signup && value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            if (!isLogin) ...[
                              const SizedBox(height: 16),
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 600),
                                tween: Tween(begin: 0.0, end: 1.0),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, (1 - value) * 20),
                                      child: child,
                                    ),
                                  );
                                },
                                child: TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _buildInputDecoration(
                                    'Confirm Password',
                                    Icons.lock,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Confirm your password';
                                    } else if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                            if (isLogin)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.8,
                                      child: Switch(
                                        value: _rememberMe,
                                        activeColor: Colors.orangeAccent,
                                        onChanged: (bool? val) {
                                          setState(() {
                                            _rememberMe = val ?? false;
                                          });
                                          HapticFeedback.lightImpact();
                                        },
                                      ),
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
                                        // Animation et retour haptique
                                        HapticFeedback.lightImpact();
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.orangeAccent,
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style: GoogleFonts.lato(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),

                            // Submit button avec animation et état de chargement
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 55,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  backgroundColor: Colors.orangeAccent,
                                  disabledBackgroundColor: Colors.orangeAccent.withOpacity(0.6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 25,
                                  width: 25,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                )
                                    : Text(
                                  isLogin ? 'Sign In' : 'Sign Up',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Social login separator
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white24, thickness: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'Or continue with',
                                    style: GoogleFonts.lato(color: Colors.white70),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white24, thickness: 1)),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Social Buttons avec animations
                            Row(
                              children: [
                                _buildSocialButton(
                                  label: 'Google',
                                  icon: Icons.g_mobiledata,
                                  onPressed: () {
                                    if (kDebugMode) {
                                      print('Google Sign In');
                                    }
                                    HapticFeedback.lightImpact();
                                  },
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                ),
                                const SizedBox(width: 16),
                                _buildSocialButton(
                                  label: 'Apple',
                                  icon: Icons.apple,
                                  onPressed: () {
                                    if (kDebugMode) {
                                      print('Apple Sign In');
                                    }
                                    HapticFeedback.lightImpact();
                                  },
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Toggle form type avec animation
                            Center(
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 300),
                                tween: Tween(begin: 0.8, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: child,
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isLogin ? "Don't have an account? " : "Already have an account? ",
                                      style: GoogleFonts.lato(color: Colors.white70, fontSize: 16),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        _switchFormType();
                                      },
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