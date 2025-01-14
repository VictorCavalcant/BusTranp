import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:ubus/pages/HomePage.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
        backgroundColor: const Color(0xFF0469ff),
        splash: Image.asset(
          'assets/logo_BusTranp.png',
          fit: BoxFit.contain,
        ),
        nextScreen: const HomePage(),
        splashTransition: SplashTransition.fadeTransition,
        splashIconSize: double.infinity,
        pageTransitionType: PageTransitionType.leftToRight);
  }
}
