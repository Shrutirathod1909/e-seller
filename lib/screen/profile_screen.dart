import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecolods/api/api_service.dart' as api;
import 'package:ecolods/screen/appbarscreen.dart';
import 'package:ecolods/screen/login.dart';
import 'package:ecolods/screen/ChangePasswordScreen.dart';
import 'package:ecolods/screen/PersonalDetailsScreen.dart';
import 'package:ecolods/screen/gstinscreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String vendorName = "";
  String email = "";
  String phone = "";
  String vendorId = "";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  /* ================= GET PROFILE ================= */
  Future getProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Handle vendor_id whether int or string
      var storedVendor = prefs.get("vendor_id");
      vendorId = storedVendor != null ? storedVendor.toString() : "";

      print("Vendor ID: $vendorId");

      if (vendorId.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      var response = await http.post(
        Uri.parse("${api.ApiService.baseUrl}profile.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get",
          "vendor_id": vendorId,
        }),
      );

      print("PROFILE RESPONSE: ${response.body}");

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {
        var d = data["data"] ?? {};
        setState(() {
          vendorName = d["vendor_name"] ?? "";
          email = d["email_id"] ?? "";
          phone = d["phone"] ?? "";
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  /* ================= PROFILE TILE ================= */
  Widget profileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget navigateTo,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF3C67A0),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (vendorId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Vendor ID not found")),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => navigateTo),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: const Color(0xfff4f6fb),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                /* ================= HEADER ================= */
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B3F6B), Color(0xFF3C67A0)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF3B3F6B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        vendorName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        email,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        phone,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /* ================= MENU ================= */
                profileTile(
                  context,
                  icon: Icons.person,
                  title: "Personal Details",
                  navigateTo:
                      PersonalDetailsScreen(vendorId: vendorId),
                ),

                profileTile(
                  context,
                  icon: Icons.lock,
                  title: "Change Password",
                  navigateTo: const ChangePasswordScreen(),
                ),

                profileTile(
                  context,
                  icon: Icons.receipt_long,
                  title: "GSTIN Details",
                  navigateTo: const GstinScreen(),
                ),

                const SizedBox(height: 30),

                /* ================= LOGOUT ================= */
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B3F6B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();

                      await prefs.clear();

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
    );
  }
}