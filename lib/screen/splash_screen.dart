import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ecolods/screen/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white, // ✅ Background color white
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: ScaleTransition(
              scale: _animation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Image.asset(
                    "assets/icon.png",
                    height: 110,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Ecommerce Seller",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Optional: text color dark for white bg
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const CircularProgressIndicator(
                    color: Colors.blue, // ✅ Loader color blue
                    strokeWidth: 3,
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}