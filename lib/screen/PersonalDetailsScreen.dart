import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ecolods/api/api_service.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final String vendorId;

  const PersonalDetailsScreen({super.key, required this.vendorId});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {

  final formKey = GlobalKey<FormState>();

  bool isLoading = true;
  bool isUpdating = false;

  final vendorNameController = TextEditingController();
  final businessTypeController = TextEditingController();
  final panController = TextEditingController();
  final contactPersonController = TextEditingController();
  final designationController = TextEditingController();
  final contactNumberController = TextEditingController();
  final emailController = TextEditingController();
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();
  final pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getDetails();
  }

  @override
  void dispose() {
    vendorNameController.dispose();
    businessTypeController.dispose();
    panController.dispose();
    contactPersonController.dispose();
    designationController.dispose();
    contactNumberController.dispose();
    emailController.dispose();
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    pinController.dispose();
    super.dispose();
  }

  /// API CALLS (same)
  Future getDetails() async {
    try {
      var response = await http.post(
        Uri.parse("${ApiService.baseUrl}profile.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get",
          "vendor_id": widget.vendorId,
        }),
      );

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {
        var d = data["data"] ?? {};

        vendorNameController.text = d["vendor_name"] ?? "";
        businessTypeController.text = d["business_type"] ?? "";
        panController.text = d["pancard_no"] ?? "";
        contactPersonController.text = d["contactable_person"] ?? "";
        designationController.text = d["designation"] ?? "";
        contactNumberController.text = d["phone"] ?? "";
        emailController.text = d["email_id"] ?? "";
        streetController.text = d["street"] ?? "";
        cityController.text = d["city"] ?? "";
        stateController.text = d["state"] ?? "";
        countryController.text = d["country"] ?? "";
        pinController.text = d["pincode"] ?? "";
      }
    } catch (e) {
      debugPrint("$e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future updateDetails() async {
    var response = await http.post(
      Uri.parse("${ApiService.baseUrl}profile.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "action": "update",
        "vendor_id": widget.vendorId,
        "vendor_name": vendorNameController.text,
        "business_type": businessTypeController.text,
        "pancard_no": panController.text,
        "contactable_person": contactPersonController.text,
        "designation": designationController.text,
        "phone": contactNumberController.text,
        "email_id": emailController.text,
        "street": streetController.text,
        "city": cityController.text,
        "state": stateController.text,
        "country": countryController.text,
        "pincode": pinController.text,
      }),
    );

    var data = jsonDecode(response.body);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data["message"] ?? "Updated Successfully")),
    );
  }

  /// 🔥 MODERN INPUT FIELD
  Widget inputField(String label, TextEditingController controller,
      [TextInputType type = TextInputType.text]) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(14),
        child: TextFormField(
          controller: controller,
          keyboardType: type,
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
          validator: (v) => v!.isEmpty ? "Enter $label" : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      /// 🔥 PREMIUM APPBAR
      appBar: AppBar(
         foregroundColor: Colors.white,
        title: const Text("Personal Details",style: TextStyle(color: Colors.white),),
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
          : Form(
              key: formKey,
              child: SingleChildScrollView(
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
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person,
                                size: 30, color: Color.fromARGB(255, 1, 139, 252)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              vendorNameController.text.isEmpty
                                  ? "Vendor Profile"
                                  : vendorNameController.text,
                              style: const TextStyle(
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

                          inputField("Vendor Name", vendorNameController),
                          inputField("Business Type", businessTypeController),
                          inputField("PAN", panController),
                          inputField("Contact Person", contactPersonController),
                          inputField("Designation", designationController),
                          inputField("Phone", contactNumberController,
                              TextInputType.phone),
                          inputField("Email", emailController,
                              TextInputType.emailAddress),
                          inputField("Street", streetController),
                          inputField("City", cityController),
                          inputField("State", stateController),
                          inputField("Country", countryController),
                          inputField("PIN", pinController,
                              TextInputType.number),

                          const SizedBox(height: 20),

                          /// 🔥 UPDATE BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isUpdating
                                  ? null
                                  : () async {
                                      if (formKey.currentState!.validate()) {
                                        setState(() => isUpdating = true);
                                        await updateDetails();
                                        setState(() => isUpdating = false);
                                      }
                                    },
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
                                      "UPDATE PROFILE",
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
            ),
    );
  }
}