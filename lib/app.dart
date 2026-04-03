import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/splash/splash_screen.dart';

class CourtsideApp extends StatelessWidget {
  const CourtsideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Courtside',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}