import 'dart:convert';
import 'dart:io';

import 'package:ecolods/screen/kyc_document.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

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
  String vendorCode = "";

  bool isLoading = true;

  File? profileImage;
  final ImagePicker picker = ImagePicker();

  double companyProgress = 0.0;
  double gstProgress = 0.0;
  double kycProgress = 0.0;
  double overallProgress = 0.0;

  @override
  void initState() {
    super.initState();
    getProfile();
    loadProfileImage();
  }

  /* ================= LOAD IMAGE ================= */
  Future<void> loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? path = prefs.getString("profile_image");

    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      setState(() => profileImage = File(path));
    }
  }

  /* ================= PICK IMAGE ================= */
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      File image = File(pickedFile.path);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("profile_image", image.path);

      setState(() => profileImage = image);
    }
  }

  void showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Remove Image"),
                onTap: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.remove("profile_image");

                  setState(() => profileImage = null);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /* ================= PROFILE API ================= */
  Future getProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      vendorId = prefs.get("vendor_id")?.toString() ?? "";

      if (vendorId.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      var response = await http.post(
        Uri.parse("${api.ApiService.baseUrl}profile.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "get", "vendor_id": vendorId}),
      );

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {
        var d = data["data"] ?? {};

        final updatedPrefs = await SharedPreferences.getInstance();

        setState(() {
          vendorName = d["vendor_name"] ?? "";
          vendorCode = d["vendor_code"] ?? "";
          email = d["email_id"] ?? "";
          phone = d["phone"] ?? "";

          companyProgress = calculateProgress([
            d["vendor_name"],
            d["business_type"],
            d["pancard_no"],
            d["contactable_person"],
            d["designation"],
            d["phone"],
            d["email_id"],
            d["street"],
            d["city"],
            d["state"],
            d["country"],
            d["pincode"],
          ]);

          gstProgress = calculateProgress([
            d["gst_no"] ?? "",
            d["company_name"] ?? "",
            d["address"] ?? "",
          ]);

          kycProgress = calculateKycProgress(updatedPrefs);

          overallProgress =
              (companyProgress + gstProgress + kycProgress) / 3;

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  double calculateProgress(List<dynamic> fields) {
    int total = fields.length;
    int filled = fields
        .where((f) => f != null && f.toString().trim().isNotEmpty)
        .length;

    return total == 0 ? 0 : filled / total;
  }

  double calculateKycProgress(SharedPreferences prefs) {
    List<String> keys = [
      "pan",
      "bank",
      "selfie",
      "general",
      "commission",
      "rights",
      "delivery"
    ];

    int filled = keys.where((key) {
      String? value = prefs.getString(key);
      return value == "done";
    }).length;

    return filled / keys.length;
  }

  Color getProgressColor(double value) {
    if (value == 1) return Colors.green;
    if (value > 0.5) return Colors.orange;
    return Colors.red;
  }

  Widget profileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget navigateTo,
    double? progress,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF3C67A0),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: progress == null
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 45,
                    height: 45,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          getProgressColor(progress)),
                    ),
                  ),
                  Text("${(progress * 100).toInt()}%",
                      style: const TextStyle(fontSize: 10)),
                ],
              ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => navigateTo),
          ).then((_) => getProfile());
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

                      // 🔥 NEW PROFILE CIRCLE WITH PROGRESS
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [

                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CircularProgressIndicator(
                                value: overallProgress,
                                strokeWidth: 6,
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  getProgressColor(overallProgress),
                                ),
                              ),
                            ),

                            GestureDetector(
                              onTap: showImagePicker,
                              child: ClipOval(
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  color: Colors.white,
                                  child: profileImage != null
                                      ? Image.file(profileImage!,
                                          fit: BoxFit.contain)
                                      : const Icon(
                                          Icons.camera_alt,
                                          size: 35,
                                          color: Color(0xFF3B3F6B),
                                        ),
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${(overallProgress * 100).toInt()}%",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(vendorName,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text("Code: $vendorCode",
                          style: const TextStyle(color: Colors.white70)),
                      Text(email,
                          style: const TextStyle(color: Colors.white70)),
                      Text(phone,
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                profileTile(
                  context,
                  icon: Icons.person,
                  title: "Company Details",
                  navigateTo: PersonalDetailsScreen(vendorId: vendorId),
                  progress: companyProgress,
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
                  progress: gstProgress,
                ),

                profileTile(
                  context,
                  icon: Icons.badge,
                  title: "KYC Document",
                  navigateTo: const KycUploadScreen(),
                  progress: kycProgress,
                ),

                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text("Logout",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B3F6B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();

                      String? imagePath =
                          prefs.getString("profile_image");

                      await prefs.clear();

                      if (imagePath != null) {
                        await prefs.setString("profile_image", imagePath);
                      }

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
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