import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:ecolods/api/api_service.dart';
import 'package:ecolods/screen/bottom_nav_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordHidden = true;
  bool isLoading = false;

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final url = Uri.parse("${ApiService.baseUrl}login.php");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": usernameController.text.trim(),
          "password": passwordController.text.trim()
        }),
      );

      if (response.statusCode != 200) {
        showMsg("Server error ❌");
        return;
      }

      final data = jsonDecode(response.body);

      if (data["status"] == "success" && data["vendor"] != null) {
        // ✅ SAFE PARSING
        final vendorData = data["vendor"];
        int vendorId =
            int.tryParse(vendorData["vendor_id"].toString()) ?? 0;
        String email = vendorData["email"] ?? "";
        String companyName = vendorData["company_name"] ?? "";
        String companyId = vendorData["company_id"] ?? "";

        if (vendorId == 0) {
          showMsg("Invalid vendor ID ❌");
          return;
        }

        // ✅ SAVE TO SHARED PREFERENCES
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt("vendor_id", vendorId);
        await prefs.setString("email", email);
        await prefs.setString("company_name", companyName);
        await prefs.setString("company_id", companyId);
        await prefs.setBool("isLoggedIn", true);

        print("Vendor ID Saved: $vendorId");

        if (!mounted) return;

        showMsg("Login Successful ✅");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomNavScreen()),
        );
      } else {
        showMsg(data["message"] ?? "Login failed ❌");
      }
    } catch (e) {
      print("LOGIN ERROR: $e");
      showMsg("Server connection error ❌");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset("assets/icon.png", height: 110),
                  const SizedBox(height: 20),
                  const Text(
                    "Welcome Back",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 20)
                      ],
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: usernameController,
                          decoration: input("Email", Icons.person),
                          validator: (v) =>
                              v!.trim().isEmpty ? "Enter email" : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: passwordController,
                          obscureText: isPasswordHidden,
                          decoration: input("Password", Icons.lock).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(isPasswordHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  isPasswordHidden = !isPasswordHidden;
                                });
                              },
                            ),
                          ),
                          validator: (v) =>
                              v!.trim().isEmpty ? "Enter password" : null,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3C67A0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("Login",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}