import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(const UberChefApp());
}

class UberChefApp extends StatelessWidget {
  const UberChefApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UberChef',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}
