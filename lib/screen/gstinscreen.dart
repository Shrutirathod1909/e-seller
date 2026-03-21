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

  final gstinController = TextEditingController();
  final businessNameController = TextEditingController();
  final businessAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadVendorId();
  }

  Future<void> loadVendorId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int id = prefs.getInt("vendor_id") ?? 0;
    vendorId = id.toString();

    if (vendorId != "0") {
      await getGstinDetails();
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vendor ID not found")),
      );
    }
  }

  Future<void> getGstinDetails() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}gst_deatil.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "get", "vendor_id": vendorId}),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "success" && data["data"] != null) {
        var d = data["data"];
        gstinController.text = d["gst_no"] ?? "";
        businessNameController.text = d["company_name"] ?? "";
        businessAddressController.text = d["address"] ?? "";
      }
    } catch (e) {
      debugPrint("$e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateGstin() async {
    setState(() => isUpdating = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}gst_details.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "update",
          "vendor_id": vendorId,
          "gst_no": gstinController.text,
          "company_name": businessNameController.text,
          "address": businessAddressController.text,
        }),
      );

      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update failed")),
      );
    } finally {
      setState(() => isUpdating = false);
    }
  }

  /// 🔥 MODERN TEXTFIELD
  Widget buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(14),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.edit),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      /// 🔥 SAME GRADIENT APPBAR
      appBar: AppBar(
         foregroundColor: Colors.white,
        title: const Text("GSTIN Details",style: TextStyle(color: Colors.white),),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [   Color(0xFF3B3F6B), // Dark Blue
              Color(0xFF3C67A0), ],
            ),
          ),
        ),
      ),

      backgroundColor: const Color(0xfff4f6f9),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  /// 🔥 HEADER CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color.fromARGB(255, 54, 93, 127), Color.fromARGB(255, 81, 105, 222)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.receipt_long,
                              color: Colors.blue, size: 28),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "GST Information",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔥 FORM CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Column(
                      children: [

                        buildTextField(gstinController, "GSTIN Number"),
                        buildTextField(businessNameController, "Business Name"),
                        buildTextField(
                            businessAddressController, "Business Address",
                            maxLines: 3),

                        const SizedBox(height: 20),

                        /// 🔥 BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isUpdating ? null : updateGstin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isUpdating
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    "SAVE DETAILS",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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