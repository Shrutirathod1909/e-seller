import 'dart:convert';
import 'package:ecolods/screen/ApprovalMessageScreen.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:ecolods/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class SellerRegisterScreen extends StatefulWidget {
  @override
  _SellerRegisterScreenState createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends State<SellerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int currentStep = 0;
  bool isLoading = false;

  final picker = ImagePicker();

  // ================= CONTROLLERS =================

  // STEP 1 - Personal
  final fullName = TextEditingController();
  final username = TextEditingController();
  final email = TextEditingController();
  final mobile = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  // STEP 2 - Business
  final businessName = TextEditingController();
  final gst = TextEditingController();
  final pan = TextEditingController();
  final brandName = TextEditingController();
  final category = TextEditingController();
  final otherCategory = TextEditingController();
  final hsnCode = TextEditingController();
  final description = TextEditingController();

  // STEP 3 - Address
  final address = TextEditingController();
  final roomNo = TextEditingController();
  final street = TextEditingController();
  final landmark = TextEditingController();
  final city = TextEditingController();
  final stateCtrl = TextEditingController();
  final pincode = TextEditingController();
  final country = TextEditingController(text: "India");

  // STEP 4 - Bank
  final accountHolder = TextEditingController();
  final bankName = TextEditingController();
  final accountNumber = TextEditingController();
  final ifsc = TextEditingController();
  final branchName = TextEditingController();
  final micrNo = TextEditingController();
  final swiftCode = TextEditingController();

  // STEP 5 - Documents
  final govId = TextEditingController();
  final govIdNumber = TextEditingController();
  final authorizedSignatory = TextEditingController();
  final signatureDate = TextEditingController();

  File? companyLogo;
  File? govIdFile, commissionFile, rightsFile, deliveryFile, agreementFile;

  String businessType = "Individual";
  bool isPasswordHidden = true;
bool isConfirmPasswordHidden = true;
  

  // ================= FILE PICK =================
  
 Future<File?> pickFile() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if(picked != null){
      final file = File(picked.path);
      if(await file.length() > 2*1024*1024){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File too large")));
        return null;
      }
      return file;
    }
    return null;
  }
  XFile? gstCertificate;


Future<String> extractTextFromImage(File file) async {
  final inputImage = InputImage.fromFile(file);

  final textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin, // ✅ important
  );

  final RecognizedText recognizedText =
      await textRecognizer.processImage(inputImage);

  await textRecognizer.close();

  return recognizedText.text;
}

Future<bool> verifyDocument(File file) async {
  String extractedText = await extractTextFromImage(file);

  print("OCR TEXT: $extractedText");

  // 🔥 Normalize OCR text
  String cleanText = extractedText
      .toUpperCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[^A-Z0-9]'), '');

  // 🔥 Fix common OCR mistakes globally
  cleanText = cleanText
      .replaceAll('O', '0')
      .replaceAll('I', '1')
      .replaceAll('B', '8');

  // 🔥 Normalize entered value
  String entered = govIdNumber.text
      .trim()
      .toUpperCase()
      .replaceAll(" ", "");

  print("CLEAN TEXT: $cleanText");
  print("ENTERED: $entered");

  // ================= Aadhaar =================
  if (govId.text == "Aadhaar") {
    final matches = RegExp(r'\d{12}').allMatches(cleanText);

    for (var m in matches) {
      if (m.group(0) == entered) return true;
    }

    // fallback (contains)
    return cleanText.contains(entered);
  }

  // ================= PAN =================
  if (govId.text == "PAN") {
    final matches = RegExp(r'[A-Z]{5}[0-9]{4}[A-Z]').allMatches(cleanText);

    for (var m in matches) {
      String found = m.group(0)!;

      // Fix reverse OCR issue
      found = found.replaceAll('0', 'O');

      if (found == entered) return true;
    }

    return cleanText.contains(entered);
  }

  // ================= Voter ID =================
  if (govId.text == "Voter ID") {
    final matches = RegExp(r'[A-Z]{3}[0-9]{7}').allMatches(cleanText);

    for (var m in matches) {
      if (m.group(0) == entered) return true;
    }

    return cleanText.contains(entered);
  }

  return false;
}

Future pickGSTCertificate() async {
  final picked = await picker.pickImage(source: ImageSource.gallery);
  setState(() {
    gstCertificate = picked;
  });
}

  Future<void> pickLogo() async {
    final file = await pickFile();
    if(file != null) setState(() => companyLogo = file);
  }

  InputDecoration input(String t, IconData i) => InputDecoration(
    labelText: t,
    prefixIcon: Icon(i),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  // ================= VALIDATION =================
String? govIdNumberVal(String? v) {
  if (v == null || v.isEmpty) return "Required";

  if (govId.text == "Aadhaar") {
    if (!RegExp(r'^\d{12}$').hasMatch(v)) return "Enter valid 12-digit Aadhaar";
  } else if (govId.text == "PAN") {
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(v)) return "Enter valid PAN";
  } else if (govId.text == "Voter ID") {
    if (!RegExp(r'^[A-Z]{3}[0-9]{7}$').hasMatch(v)) return "Enter valid Voter ID";
  }
  return null;
}

  String? swiftVal(String? v) {
  if (v == null || v.isEmpty) return "Required";
  v = v.toUpperCase();

  if (!RegExp(r'^[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$').hasMatch(v)) {
    return "Invalid SWIFT";
  }
  return null;
}
  String? micrVal(String? v) {
  if (v == null || v.isEmpty) return "Required";
  if (v.length != 9) return "MICR must be 9 digits";
  return null;
}
  String? req(String? v) => (v == null || v.trim().isEmpty) ? "Required" : null;

  String? emailVal(String? v) {
    if (v == null || v.trim().isEmpty) return "Required";
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return "Invalid Email";
    return null;
  }

String? accountVal(String? v) {
  if (v == null || v.isEmpty) return "Required";
  if (!RegExp(r'^[0-9]{9,18}$').hasMatch(v)) {
    return "Enter valid account number (9–18 digits)";
  }
  return null;
}
  String? phoneVal(String? v) => v!.length != 10 ? "Enter 10 digit number" : null;

  String? panVal(String? v) => !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(v ?? "") ? "Invalid PAN" : null;

  String? gstVal(String? v) => v!.isEmpty || RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$').hasMatch(v) ? null : "Invalid GST";

  String? ifscVal(String? v) => v!.length != 11 ? "Invalid IFSC" : null;
  String? cityVal(String? v) {
  if (v == null || v.isEmpty) return "Required";
  if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v)) return "Invalid city";
  return null;
}

  String? pinVal(String? v) => v!.length != 6 ? "Invalid Pincode" : null;

String? usernameVal(String? v) {
  if (v == null || v.isEmpty) return "Required";
  if (!RegExp(r'^[a-zA-Z0-9_]{4,20}$').hasMatch(v)) {
    return "4-20 chars, no spaces";
  }
  return null;
}

  // ================= INPUT DECORATION =================

String getStepTitle() {
  switch (currentStep) {
    case 0:
      return "Personal Details";
    case 1:
      return "Business Details";
    case 2:
      return "Address Details";
    case 3:
      return "Bank Details";
    case 4:
      return "Documents";
    default:
      return "";
  }
}
  bool validateStep() {
  switch (currentStep) {

  case 0:
  return req(fullName.text) == null &&
     usernameVal(username.text) == null &&   
      emailVal(email.text) == null &&
      phoneVal(mobile.text) == null &&
      req(password.text) == null &&
      req(confirmPassword.text) == null &&
      password.text == confirmPassword.text;

    case 1:
      return req(businessName.text) == null &&
          gstVal(gst.text) == null;

    case 2:
      return pinVal(pincode.text) == null &&
          cityVal(city.text) == null;

    case 3:
      return accountVal(accountNumber.text) == null &&
          ifscVal(ifsc.text) == null;

    case 4:
      return req(authorizedSignatory.text) == null &&
          req(signatureDate.text) == null &&
          govIdNumberVal(govIdNumber.text) == null &&
          govIdFile != null;

    default:
      return true;
  }
}

 // ================= API =================

 //=====fetchCityStateFromPincode====//
 Future<void> fetchCityStateFromPincode(String pin) async {
  if (pin.length != 6) return;

  try {
    final url = Uri.parse("https://api.postalpincode.in/pincode/$pin");
    final response = await http.get(url);

    final data = jsonDecode(response.body);

    if (data[0]['Status'] == "Success") {
      final postOffice = data[0]['PostOffice'][0];

      setState(() {
        city.text = postOffice['District'] ?? "";
        stateCtrl.text = postOffice['State'] ?? "";
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid Pincode")),
      );
    }
  } catch (e) {
    print("Pincode API Error: $e");
  }
}
  ///==============Gst and pan checking==========//

Future<void> fetchGSTDetails(String gstValue) async {
  try {
    var uri = Uri.parse("${ApiService.baseUrl}register.php");

    var response = await http.post(uri, body: {
      "action": "get_gst_details",
      "gst_no": gstValue.toUpperCase()
    });

    var data = jsonDecode(response.body);

    if (data['status'] == 'success') {
      setState(() {
       pan.text = (data['pan'] ?? '').toString();
        stateCtrl.text = data['state_name'];
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(data['message'])));
    }

  } catch (e) {
    print("API Error: $e");
  }
}
//===========pincode======//

Future<bool> validatePincodeCityAPI() async {
  try {
    var uri = Uri.parse("${ApiService.baseUrl}register.php");

    var response = await http.post(uri, body: {
      "action": "validate_pincode_city", // ✅ ADD THIS
      "pincode": pincode.text,
      "city": city.text
    });

    var data = jsonDecode(response.body);

    if (data['status'] == 'error') {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(data['message'])));
      return false;
    }

    return true;
  } catch (e) {
    print("Pincode API Error: $e");
    return false;
  }
}
//-=======registerVendor===========//

  Future<void> registerVendor() async {
    try {
      var uri = Uri.parse("${ApiService.baseUrl}register.php");
      var request = http.MultipartRequest("POST", uri);

      // TEXT FIELDS
      request.fields['vendor_name'] = fullName.text;
      request.fields['username'] = username.text;
      request.fields['email_id'] = email.text;
      request.fields['phone'] = mobile.text;
      request.fields['password'] = password.text;

      request.fields['company_name'] = businessName.text;
      request.fields['gst_no'] = gst.text;
      request.fields['pancard_no'] = pan.text;
      request.fields['brand_name'] = brandName.text;

      request.fields['address'] = address.text;
      request.fields['roomno'] = roomNo.text;
      request.fields['street'] = street.text;
      request.fields['landmark'] = landmark.text;
      request.fields['city'] = city.text;
      request.fields['state'] = stateCtrl.text;
     
      request.fields['pincode'] = pincode.text;
      request.fields['country'] = country.text;

      request.fields['business_type'] = businessType;
      request.fields['business_type_other'] = otherCategory.text;

      request.fields['ac_no'] = accountNumber.text;
      request.fields['bank_name'] = bankName.text;
      request.fields['ifsc_code'] = ifsc.text;
      request.fields['branch_name'] = branchName.text;
      request.fields['micr_no'] = micrNo.text;
      request.fields['swift_code'] = swiftCode.text;

     request.fields['gov_id'] =
    "${govId.text} - ${govIdNumber.text}";
      request.fields['authorized_signatory'] = authorizedSignatory.text;
      request.fields['signature_date'] = signatureDate.text;

      // FILES
if (companyLogo != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'company_logo', 
          companyLogo!.path,
          contentType: MediaType('image', 'jpeg'), // explicitly set MIME type
        ),
      );
      print("Company Logo Added: ${companyLogo!.path}");
    }// GST CERTIFICATE FILE
if (gstCertificate != null) {
  request.files.add(
    await http.MultipartFile.fromPath(
      'gst_certificate',
      gstCertificate!.path,
      contentType: MediaType('image', 'jpeg'),
    ),
  );
  print("GST Certificate Added: ${gstCertificate!.path}");
}


    // Government ID File
    if (govIdFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'gov_id_file', 
          govIdFile!.path,
          contentType: MediaType('image', 'jpeg'), // explicitly set MIME type
        ),
      );
      print("Gov ID File Added: ${govIdFile!.path}");
    }

      var response = await request.send();
var res = await http.Response.fromStream(response);

print("Raw Response: ${res.body}");

print("REGISTER RESPONSE: ${res.body}");
var data = jsonDecode(res.body);

final status = (data['status'] ?? '').toString().trim().toLowerCase();
if (status.contains('success')) {

  if (!mounted) return;

  Future.microtask(() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ApprovalMessageScreen(
          
        ),
      ),
    );
  });}
else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(data['message'] ?? "Registration failed"),
    ),
  );
}

} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Error: $e")),
  );
}
}

  // ================= STEPS =================
  List<Widget> steps() {
    return [
      // STEP 1 - Personal
      Column(children: [
        TextFormField(controller: fullName,keyboardType: TextInputType.text,
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
  ], decoration: input("Full Name(company owner name)", Icons.person), validator: req),
        SizedBox(height: 15),
TextFormField(
  controller: username,
  decoration: input("Username", Icons.person_outline),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
  ],
  validator: usernameVal,
),
        SizedBox(height: 15),

        TextFormField(controller: email, decoration: input("Email", Icons.email), validator: emailVal,),
        SizedBox(height: 15),

      TextFormField(
  controller: mobile,
  keyboardType: TextInputType.number,
  decoration: input("Mobile", Icons.phone),
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ],
  validator: phoneVal,
),
        SizedBox(height: 15),
        TextFormField(
          controller: password,
          obscureText: isPasswordHidden,
          decoration: input("Password", Icons.lock).copyWith(
            suffixIcon: IconButton(
              icon: Icon(isPasswordHidden ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden),
            ),
          ),
          validator: (v) => v!.length < 6 ? "Min 6 characters" : null,
        ),
        SizedBox(height: 15),
      TextFormField(
  controller: confirmPassword,
  obscureText: isConfirmPasswordHidden,
  decoration: input("Confirm Password", Icons.lock).copyWith(
    suffixIcon: IconButton(
      icon: Icon(isConfirmPasswordHidden ? Icons.visibility_off : Icons.visibility),
      onPressed: () => setState(() => isConfirmPasswordHidden = !isConfirmPasswordHidden),
    ),
  ),
  validator: (v) => v != password.text ? "Passwords do not match" : null,
),
      ]),

      // STEP 2 - Business
      Column(children: [
        GestureDetector(
          onTap: pickLogo,
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
            child: companyLogo != null ? Image.file(companyLogo!, fit: BoxFit.cover) : Icon(Icons.camera_alt),
          ),
        ),
        SizedBox(height: 10),
        Text("Upload Logo",),
        SizedBox(height: 15),
        TextFormField(controller: businessName,inputFormatters: [
  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\u0900-\u097F ]')),
], decoration: input("Business Name", Icons.business),validator: req,),
        SizedBox(height: 15),SizedBox(height: 15),

DropdownButtonFormField<String>(
  value: businessType,
  items: [
    DropdownMenuItem(value: "Individual", child: Text("Individual")),
    DropdownMenuItem(value: "Company", child: Text("Company")),
    DropdownMenuItem(value: "Partnership", child: Text("Partnership")),
  ],
  onChanged: (val) {
    setState(() {
      businessType = val!;
    });
  },
  decoration: input("Business Type", Icons.category),
  validator: (v) => v == null ? "Select Business Type" : null,
),
        SizedBox(height: 15),
        TextFormField(controller: brandName,inputFormatters: [
  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\u0900-\u097F ]')),
], decoration: input("Brand Name", Icons.branding_watermark),validator: req,),
        SizedBox(height: 15),
  TextFormField(
  controller: gst,

onChanged: (value) {
  final gstValue = value.toUpperCase();
  gst.value = gst.value.copyWith(
    text: gstValue,
    selection: TextSelection.collapsed(offset: gstValue.length),
  );

  if (gstValue.length == 15) {
    fetchGSTDetails(gstValue);
  }
},

  decoration: input("GST", Icons.receipt),
  textCapitalization: TextCapitalization.characters,
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
    LengthLimitingTextInputFormatter(15),
  ],
  validator: gstVal,
),
        SizedBox(height: 15),
       TextFormField(
  controller: pan,
  readOnly: true,
  keyboardType: TextInputType.text,
  textCapitalization: TextCapitalization.characters,
  decoration: input("PAN (Auto)", Icons.credit_card),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
    LengthLimitingTextInputFormatter(10),
  ],
  validator: panVal,
),
      ]),

      // STEP 3 - Address
      Column(children: [
        TextFormField(controller: address,inputFormatters: [
  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\u0900-\u097F ]')),
], decoration: input("Address", Icons.home), validator: req),
        SizedBox(height: 15),
        TextFormField(controller: roomNo, decoration: input("Room No", Icons.home),validator: req,),
        SizedBox(height: 15),
        TextFormField(controller: street, decoration: input("Street", Icons.route),validator: req,),
        SizedBox(height: 15),
        TextFormField(controller: landmark, decoration: input("Landmark", Icons.place),validator: req,),
        SizedBox(height: 15),

         TextFormField(
  controller: pincode,
  keyboardType: TextInputType.number,
  decoration: input("Pincode", Icons.pin),
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(6),
  ],
  onChanged: (value) {
    if (value.length == 6) {
      fetchCityStateFromPincode(value);
    } else {
      city.clear();
      stateCtrl.clear();
    }
  },
  validator: pinVal,
),
        SizedBox(height: 15),

     TextFormField(
  controller: city,
  decoration: input("City (Auto)", Icons.location_city),
  validator: cityVal,
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
  ],
),
        SizedBox(height: 15),
 TextFormField(
  controller: stateCtrl,
   
  decoration: input("State (Auto)", Icons.map),
  validator: req,
),

        SizedBox(height: 15),
        TextFormField(controller: country, decoration: input("Country", Icons.flag), validator: req,),
      ]),

      // STEP 4 - Bank
      Column(children: [
        TextFormField(controller: accountHolder,inputFormatters: [
  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\u0900-\u097F ]')),
], decoration: input("Account Holder", Icons.person), validator: req,),
        SizedBox(height: 15),
        TextFormField(controller: bankName, inputFormatters: [
  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\u0900-\u097F ]')),
],decoration: input("Bank Name", Icons.account_balance), validator: req,),
        SizedBox(height: 15),
  TextFormField(
  controller: accountNumber,
  keyboardType: TextInputType.number,
  decoration: input("Account No", Icons.numbers),

  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(18),
  ],

  validator: accountVal,
),
        
        SizedBox(height: 15),
    TextFormField(
  controller: ifsc,
  textCapitalization: TextCapitalization.characters, // 👈 uppercase
  decoration: input("IFSC", Icons.code),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
    LengthLimitingTextInputFormatter(11),
  ],
  validator: ifscVal,
),
        SizedBox(height: 15),
        TextFormField(controller: branchName, decoration: input("Branch Name", Icons.account_tree)),
        SizedBox(height: 15),
   TextFormField(
  controller: micrNo,
  keyboardType: TextInputType.number,
  decoration: input("MICR", Icons.confirmation_number),
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(9),
  ],
  validator: micrVal,
),
        SizedBox(height: 15),
    TextFormField(
  controller: swiftCode,
  textCapitalization: TextCapitalization.characters, // 👈 uppercase
  decoration: input("SWIFT", Icons.code),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
    LengthLimitingTextInputFormatter(11),
  ],
  validator: swiftVal,
),
      ]),

// STEP 5 - Documents
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // ---------------- GOV ID TYPE ----------------
DropdownButtonFormField<String>(
  value: govId.text.isEmpty ? null : govId.text,
  items: ["Aadhaar", "PAN", "Voter ID"]
      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
      .toList(),
  onChanged: (val) => setState(() {
    govId.text = val!;
    govIdNumber.clear();
  }),
  decoration: input("Government ID Type", Icons.badge),
  validator: (v) => v == null ? "Select ID Type" : null,
),
    SizedBox(height: 15),
TextFormField(
  controller: govIdNumber,
  decoration: input("Enter ID Number", Icons.numbers),
  validator: (v) {
    if (v == null || v.isEmpty) return "Enter ID Number";

    if (govId.text == "Aadhaar" && v.length != 12) {
      return "Aadhaar must be 12 digits";
    }

     if (govId.text == "PAN") {
      if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(v)) {
        return "Invalid PAN (e.g. ABCDE1234F)";
      }
    }
      if (govId.text == "Voter ID") {
      if (!RegExp(r'^[A-Z]{3}[0-9]{7}$').hasMatch(v)) {
        return "Invalid Voter ID (e.g. ABC1234567)";
      }
    }

    return null;
  },
),
    // ---------------- GOV ID NUMBER ----------------
      SizedBox(height: 15),

    // ---------------- UPLOAD GOV ID FILE ----------------
    ElevatedButton.icon(
      icon: Icon(Icons.upload_file),
      onPressed: () async {
  File? file = await pickFile();

  if (file != null) {
    bool isValid = await verifyDocument(file);

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Document does not match ID number")),
      );
      return;
    }

    setState(() {
      govIdFile = file;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Document Verified")),
    );
  }
},
      label: Text(govIdFile == null ? "Upload Gov ID" : "Uploaded ✔"),
      style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
    ),
    SizedBox(height: 15),
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    ElevatedButton.icon(
      onPressed: pickGSTCertificate,
      icon: Icon(Icons.upload_file),
      label: Text("Upload GST Certificate"),
      style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
    ),

    if (gstCertificate != null)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          gstCertificate!.name,
          style: TextStyle(color: Colors.green),
        ),
      ),
  ],
),
    SizedBox(height: 15),

    // ---------------- AUTHORIZED SIGNATORY ----------------
    TextFormField(
      controller: authorizedSignatory,
      decoration: input("Authorized Signatory", Icons.person),
      validator: req,
    ),
    SizedBox(height: 15),

    // ---------------- SIGNATURE DATE ----------------
    TextFormField(
      controller: signatureDate,
      readOnly: true,
      decoration: input("Signature Date", Icons.date_range),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          signatureDate.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        }
      },
      validator: req,
    ), 
  ],
),  ];
  }

  // ================= NAVIGATION =================
  void nextStep() async {
  if (!_formKey.currentState!.validate()) {
    return; // stop if any field is empty/wrong
  }
  if (currentStep == 2) {
    bool isValid = await validatePincodeCityAPI();
    if (!isValid) return;
  }
if (currentStep == 4 && govIdFile == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("⚠ Please upload Government ID")),
    );
    return;
  }
  if (currentStep < 4) {
    setState(() => currentStep++);
  } else {
  setState(() => isLoading = true);

  bool isValid = await validatePincodeCityAPI(); // ✅ final check
  if (!isValid) {
    setState(() => isLoading = false);
    return;
  }

  await registerVendor();
  setState(() => isLoading = false);
}
}

  void prevStep() {
    if (currentStep > 0) setState(() => currentStep--);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(25),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset("assets/icon.png", height: 100),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                    ),
                    child: Column(
                      children: [
                        Text(getStepTitle(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3C67A0))),
                        SizedBox(height: 20),
                        steps()[currentStep],
                        SizedBox(height: 20),
                        Row(
                          children: [
                            if (currentStep > 0) Expanded(child: OutlinedButton(onPressed: prevStep, child: Text("Back"))),
                            if (currentStep > 0) SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading ? null : nextStep,
                                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF3C67A0)),
                                child: isLoading
                                    ? CircularProgressIndicator(color: Colors.white)
                                    : Text(currentStep == 4 ? "Register" : "Next", style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        )
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