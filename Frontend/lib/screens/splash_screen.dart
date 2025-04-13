// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _bounceController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Animation principale
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Animation de rebond continue
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Animation de fondu
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Animation d'échelle avec rebond plus prononcé
    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Animation de rebond vertical
    _bounceAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );

    // Légère rotation
    _rotateAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );

    // Démarrer les animations
    _animController.forward();
    _bounceController.repeat(reverse: true);

    // Naviguer vers l'écran d'authentification après l'animation
    Timer(const Duration(seconds: 2), () {
      // Commencer à diminuer l'opacité avant la transition
      AnimationController fadeOutController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );

      fadeOutController.forward().then((_) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const AuthScreen(),
            transitionsBuilder: (_, animation, __, child) {
              const curve = Curves.fastOutSlowIn;
              var curveTween = CurveTween(curve: curve);

              // Combinaison de fondu, échelle et glissement
              var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(curveTween);
              var scaleTween = Tween<double>(begin: 0.92, end: 1.0).chain(curveTween);
              var slideTween = Tween<Offset>(
                  begin: const Offset(0.0, 0.15),
                  end: Offset.zero
              ).chain(curveTween);

              return FadeTransition(
                opacity: animation.drive(fadeTween),
                child: SlideTransition(
                  position: animation.drive(slideTween),
                  child: ScaleTransition(
                    scale: animation.drive(scaleTween),
                    child: child,
                  ),
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 900),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF121212)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_animController, _bounceController]),
          builder: (context, _) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo avec animation combinée
                  Transform.translate(
                    offset: Offset(0, _bounceAnimation.value),
                    child: Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: FadeTransition(
                        opacity: _opacityAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Image.asset(
                            'assets/logo.png',
                            width: 220,
                            height: 220,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Indicateur de chargement avec animation de taille
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Cercle externe qui pulse
                          AnimatedBuilder(
                            animation: _bounceController,
                            builder: (context, child) {
                              return Container(
                                width: 40 + 10 * _bounceController.value,
                                height: 40 + 10 * _bounceController.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.orangeAccent.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Indicateur standard
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                            strokeWidth: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}