import 'dart:convert';
import 'package:ecolods/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GstinScreen extends StatefulWidget {
  const GstinScreen({super.key});

  @override
  State<GstinScreen> createState() => _GstinScreenState();
}

class _GstinScreenState extends State<GstinScreen> {
  String vendorId = "";
  bool isLoading = true;
  bool isUpdating = false;
  bool isEditMode = false;

  final gstinController = TextEditingController();
  final businessNameController = TextEditingController();
  final businessAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadVendorId();
  }

  /* ================= LOAD VENDOR ================= */
  Future<void> loadVendorId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int id = prefs.getInt("vendor_id") ?? 0;
    vendorId = id.toString();

    if (vendorId != "0") {
      await getGstinDetails();
    } else {
      setState(() => isLoading = false);
    }
  }

  /* ================= GET GST ================= */
  Future<void> getGstinDetails() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}gst_deatil.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get",
          "vendor_id": vendorId
        }),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "success" && data["data"] != null) {
        var d = data["data"];

        gstinController.text = d["gst_no"] ?? "";
        businessNameController.text = d["company_name"] ?? "";
        businessAddressController.text = d["address"] ?? "";
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /* ================= UPDATE GST ================= */
  Future<void> updateGstin() async {
    setState(() => isUpdating = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}gst_deatil.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "update",
          "vendor_id": vendorId,
          "gst_no": gstinController.text.trim(),
          "company_name": businessNameController.text.trim(),
          "address": businessAddressController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Updated")),
      );

      Navigator.pop(context, true); // 🔥 refresh profile

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update failed")),
      );
    } finally {
      setState(() => isUpdating = false);
    }
  }

  /* ================= TEXT FIELD ================= */
  Widget buildField(
    TextEditingController controller,
    String title, {
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly ? true : !isEditMode,
        decoration: InputDecoration(
          labelText: title,
          border: InputBorder.none,
        ),
      ),
    );
  }

  /* ================= UI ================= */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GST Details"),
        centerTitle: true,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isEditMode ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                isEditMode = !isEditMode;
              });
            },
          )
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B3F6B), Color(0xFF3C67A0)],
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xfff4f6fb),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [

                  buildField(
                    gstinController,
                    "GSTIN Number",
                    readOnly: true,
                  ),

                  buildField(
                    businessNameController,
                    "Business Name",
                  ),

                  buildField(
                    businessAddressController,
                    "Business Address",
                    maxLines: 3,
                  ),

                  const SizedBox(height: 20),

                  if (isEditMode)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isUpdating ? null : updateGstin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B3F6B),
                          padding: const EdgeInsets.all(15),
                        ),
                        child: isUpdating
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "Save Details",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    gstinController.dispose();
    businessNameController.dispose();
    businessAddressController.dispose();
    super.dispose();
  }
}