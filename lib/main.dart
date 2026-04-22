import 'package:ecolods/screen/login.dart';
import 'package:flutter/material.dart';
import 'package:ecolods/screen/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ekodex());
}

class ekodex extends StatelessWidget {
  const ekodex({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:SplashScreen(),
      title: "EcoLods",
      initialRoute: '/',
      routes: {
        '/LoginScreen': (context) => const LoginScreen(),
      },
    );
  }
}