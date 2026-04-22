import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecolods/api/api_service.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final String vendorId;

  const PersonalDetailsScreen({super.key, required this.vendorId});
  @override
  State<PersonalDetailsScreen> createState() =>
      _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState
    extends State<PersonalDetailsScreen> {
List<Map<String, dynamic>> pincodeList = [];
bool showPincodeDropdown = false;
  bool isLoading = true;
  bool isUpdating = false;
  bool isEditMode = false;

  final vendorNameController = TextEditingController();
  final businessTypeController = TextEditingController();
  final panController = TextEditingController();
  final contactPersonController = TextEditingController();
  final designationController = TextEditingController();
  final contactNumberController = TextEditingController();
  final alternatePhoneController = TextEditingController();
  final emailController = TextEditingController();
  final alternateEmailController = TextEditingController();
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
    alternatePhoneController.dispose();
    emailController.dispose();
    alternateEmailController.dispose();
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    pinController.dispose();
    super.dispose();
  }

  /* ================= VALIDATION ================= */

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  bool isValidPhone(String phone) {
    final regex = RegExp(r'^[6-9]\d{9}$');
    return regex.hasMatch(phone);
  }


  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }

  /* ================= GET DETAILS ================= */

Future<void> searchPincode(String query) async {
  if (query.trim().isEmpty) {
    setState(() {
      pincodeList = [];
      showPincodeDropdown = false;
    });
    return;
  }

  try {
    final url =
        "${ApiService.baseUrl}categories_api.php?action=pincode_search&query=$query";

    debugPrint("PIN API: $url");

    final res = await http.get(Uri.parse(url));

    debugPrint("PIN STATUS: ${res.statusCode}");
    debugPrint("PIN RESPONSE: ${res.body}");

    if (res.statusCode != 200) return;

    final data = jsonDecode(res.body);

    if (!mounted) return;

    if (data["status"] == "success" &&
        data["data"] != null &&
        data["data"] is List) {
      setState(() {
        pincodeList =
            List<Map<String, dynamic>>.from(data["data"]);

       showPincodeDropdown = pincodeList.isNotEmpty;
      });
    } else {
      setState(() {
        pincodeList = [];
        showPincodeDropdown = false;
      });
    }
  } catch (e) {
    debugPrint("PIN search error: $e");
  }
} 

 Future getDetails() async {
    try {
      var response = await http.post(
        Uri.parse("${ApiService.baseUrl}profile.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get",
          "vendor_id": widget.vendorId
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
        alternatePhoneController.text = d["alternate_phone"] ?? "";
        emailController.text = d["email_id"] ?? "";
        alternateEmailController.text = d["alternate_email"] ?? "";
        streetController.text = d["street"] ?? "";
        cityController.text = d["city"] ?? "";
        stateController.text = d["state"] ?? "";
        countryController.text = d["country"] ?? "";
        pinController.text = d["pincode"] ?? "";

        await saveProgress();
      }
    } catch (e) {
      debugPrint("$e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /* ================= PROGRESS ================= */

  double calculateCompanyProgress() {
    List<String> fields = [
      vendorNameController.text,
      businessTypeController.text,
      panController.text,
      contactPersonController.text,
      designationController.text,
      contactNumberController.text,
      alternatePhoneController.text,
      emailController.text,
      alternateEmailController.text,
      streetController.text,
      cityController.text,
      stateController.text,
      countryController.text,
      pinController.text,
    ];

    int total = fields.length;
    int filled =
        fields.where((f) => f.trim().isNotEmpty).length;

    return total == 0 ? 0 : filled / total;
  }

  Future<void> saveProgress() async {
    double progress = calculateCompanyProgress();
    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    await prefs.setDouble("company_progress", progress);
  }

  /* ================= UPDATE ================= */

  Future updateDetails() async {
    String phone = contactNumberController.text.trim();
    String altPhone = alternatePhoneController.text.trim();
    String email = emailController.text.trim();
    String altEmail = alternateEmailController.text.trim();

    // ✅ VALIDATIONS
    if (vendorNameController.text.trim().isEmpty) {
      showError("Vendor Name required");
      return;
    }

    if (!isValidPhone(phone)) {
      showError("Enter valid 10-digit phone number");
      return;
    }

    if (altPhone.isNotEmpty && !isValidPhone(altPhone)) {
      showError("Invalid Alternate Phone");
      return;
    }

    if (!isValidEmail(email)) {
      showError("Invalid Email");
      return;
    }

    if (altEmail.isNotEmpty && !isValidEmail(altEmail)) {
      showError("Invalid Alternate Email");
      return;
    }

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
        "phone": phone,
        "alternate_phone": altPhone,
        "email_id": email,
        "alternate_email": altEmail,
        "street": streetController.text,
        "city": cityController.text,
        "state": stateController.text,
        "country": countryController.text,
        "pincode": pinController.text,
      }),
    );

    var data = jsonDecode(response.body);

    await saveProgress();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(data["message"] ?? "Updated Successfully"),
      ),
    );
  }

  /* ================= INPUT ================= */

  Widget inputField(
    String label,
    TextEditingController controller, [
    TextInputType type = TextInputType.text,
    bool alwaysReadOnly = false,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(14),
        child: TextFormField(
          controller: controller,
          keyboardType: type,
          readOnly:
              alwaysReadOnly ? true : !isEditMode,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: alwaysReadOnly
                ? Colors.grey.shade200
                : (isEditMode
                    ? Colors.white
                    : Colors.grey.shade100),
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Company Details"),
        centerTitle: true,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF3B3F6B),
                Color(0xFF3C67A0)
              ],
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xfff4f6f9),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator())
          : SingleChildScrollView(
  clipBehavior: Clip.none,
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                children: [
                  // SAME HEADER UI
                  Container(
                    padding:
                        const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(
                        colors: [
                          Color.fromARGB(
                              255, 54, 93, 127),
                          Color.fromARGB(
                              255, 81, 105, 222),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(
                              20),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
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
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isEditMode = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SAME FORM UI
          Container(
  clipBehavior: Clip.none, // ✅ ADD THIS
  padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        inputField("Vendor Name", vendorNameController),
                        inputField("Business Type", businessTypeController, TextInputType.text, true),
                        inputField("PAN", panController, TextInputType.text, true),
                        inputField("Contact Person", contactPersonController),
                        inputField("Designation", designationController),
                        inputField("Phone", contactNumberController, TextInputType.number),
                        inputField("Alternate Phone", alternatePhoneController, TextInputType.number),
                        inputField("Email", emailController, TextInputType.emailAddress),
                        inputField("Alternate Email", alternateEmailController, TextInputType.emailAddress),
                        inputField("Street", streetController),
                        inputField("City", cityController),
                        inputField("State", stateController),
          Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: TextFormField(
        controller: pinController,
        keyboardType: TextInputType.number,
        readOnly: !isEditMode,
        onChanged: (value) async {
          await searchPincode(value);
        },
        decoration: InputDecoration(
          labelText: "PIN Code",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    ),

    // ✅ SIMPLE DROPDOWN BELOW FIELD (BEST FIX)
    if (showPincodeDropdown && pincodeList.isNotEmpty)
      Container(
        margin: const EdgeInsets.only(top: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
            )
          ],
        ),
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: pincodeList.length,
          itemBuilder: (context, index) {
            final item = pincodeList[index];

            return ListTile(
              dense: true,
              title: Text("${item['pincode']} - ${item['area']}"),
              subtitle:
                  Text("${item['city']} , ${item['state']}"),
              onTap: () {
                setState(() {
                  pinController.text = item['pincode'];
                  cityController.text = item['city'];
                  stateController.text = item['state'];

                  showPincodeDropdown = false;
                  pincodeList.clear();
                });
              },
            );
          },
        ),
      ),
  ],
),

const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: (!isEditMode || isUpdating)
                                ? null
                                : () async {
                                    setState(() => isUpdating = true);

                                    await updateDetails();

                                    setState(() {
                                      isUpdating = false;
                                      isEditMode = false;
                                    });

                                    Navigator.pop(context);
                                  },
                            child: isUpdating
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    "UPDATE PROFILE",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 200),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}