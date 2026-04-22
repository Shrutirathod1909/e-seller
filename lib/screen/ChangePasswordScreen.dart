import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecolods/api/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  bool oldVisible = false;
  bool newVisible = false;
  bool confirmVisible = false;

  double strength = 0;
  bool isLoading = false;

  /* ================= PASSWORD STRENGTH ================= */
  void checkStrength(String value) {
    if (value.length < 6) {
      strength = 0.2;
    } else if (value.length < 8) {
      strength = 0.4;
    } else if (value.contains(RegExp(r'[0-9]'))) {
      strength = 0.7;
    } else {
      strength = 1;
    }
    setState(() {});
  }

  Color strengthColor() {
    if (strength <= 0.3) return Colors.red;
    if (strength <= 0.6) return Colors.orange;
    if (strength <= 0.9) return Colors.blue;
    return Colors.green;
  }

  String strengthText() {
    if (strength <= 0.3) return "Weak";
    if (strength <= 0.6) return "Medium";
    if (strength <= 0.9) return "Strong";
    return "Very Strong";
  }

  /* ================= UPDATE PASSWORD API ================= */
  Future updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var vendorId = prefs.get("vendor_id").toString();

      var response = await http.post(
        Uri.parse("${ApiService.baseUrl}change_password.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "vendor_id": vendorId,
          "old_password": oldPassword.text,
          "new_password": newPassword.text
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200 &&
          response.body.trim().startsWith("{")) {
        var data = jsonDecode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );

        if (data["status"] == "success") {
          oldPassword.clear();
          newPassword.clear();
          confirmPassword.clear();
          setState(() {
            strength = 0;
          });
        }
      } else {
        print("INVALID RESPONSE: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Server Response Error")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /* ================= PASSWORD FIELD ================= */
  Widget passwordField({
    required String label,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback toggle,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible, // toggle to show/hide
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF3B3F6B)),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF3B3F6B),
          ),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$label is required";
        }
        if (value.length < 5) {
          return "Minimum 5 characters required";
        }
        if (label == "Confirm Password" && value != newPassword.text) {
          return "Passwords do not match";
        }
        return null;
      },
    );
  }

  /* ================= UI ================= */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      resizeToAvoidBottomInset: true, // prevent black screen on keyboard open
      appBar: AppBar(
        title: const Text(
          "Change Password",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3B3F6B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      passwordField(
                        label: "Old Password",
                        controller: oldPassword,
                        visible: oldVisible,
                        toggle: () {
                          setState(() {
                            oldVisible = !oldVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      passwordField(
                        label: "New Password",
                        controller: newPassword,
                        visible: newVisible,
                        toggle: () {
                          setState(() {
                            newVisible = !newVisible;
                          });
                        },
                        onChanged: checkStrength,
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: strength,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(strengthColor()),
                      ),
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          strengthText(),
                          style: TextStyle(
                            color: strengthColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      passwordField(
                        label: "Confirm Password",
                        controller: confirmPassword,
                        visible: confirmVisible,
                        toggle: () {
                          setState(() {
                            confirmVisible = !confirmVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : updatePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B3F6B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Update Password",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


