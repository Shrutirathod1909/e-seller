import 'dart:io';
import 'dart:convert';
import 'package:ecolods/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen> {

  File? panImage, bankImage, selfieImage;
  File? generalAgreementImage, commissionAgreementImage, rightsAgreementImage, deliveryAgreementImage;

  final picker = ImagePicker();
  final textRecognizer = TextRecognizer();

  int vendorId = 0;
  String? detectedPan;
  bool isLoading = false;

  final String apiUrl = "${ApiService.baseUrl}kyc_document.php";

  @override
  void initState() {
    super.initState();
    loadVendorId().then((_) => fetchKyc());
  }

  Future<void> loadVendorId() async {
    final prefs = await SharedPreferences.getInstance();
    vendorId = prefs.getInt("vendor_id") ?? 0;
  }

  Future<File?> urlToFile(String url, String name) async {
    try {
      final res = await http.get(Uri.parse(url));
      final file = File('${Directory.systemTemp.path}/$name');
      await file.writeAsBytes(res.bodyBytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  // ================= FETCH =================
  Future<void> fetchKyc() async {
    if (vendorId == 0) return;

    try {
      final res = await http.get(Uri.parse("$apiUrl?vendor_id=$vendorId"));
      final json = jsonDecode(res.body);

      if (json['status'] == "success") {
        final data = json['data'];
        final gov = data['gov_id_file'] ?? {};
        String base = ApiService.baseUrl;

        SharedPreferences prefs = await SharedPreferences.getInstance();

        if (gov['pan'] != null && gov['pan'] != "") {
          panImage = await urlToFile(base + gov['pan'], "pan.jpg");
          await prefs.setString("pan", "done");
        }

        if (gov['bank'] != null && gov['bank'] != "") {
          bankImage = await urlToFile(base + gov['bank'], "bank.jpg");
          await prefs.setString("bank", "done");
        }

        if (data['selfie'] != null && data['selfie'] != "") {
          selfieImage = await urlToFile(base + data['selfie'], "selfie.jpg");
          await prefs.setString("selfie", "done");
        }

        if (data['file_agreement'] != null && data['file_agreement'] != "") {
          generalAgreementImage = await urlToFile(base + data['file_agreement'], "general.jpg");
          await prefs.setString("general", "done");
        }

        if (data['commission_agreement'] != null && data['commission_agreement'] != "") {
          commissionAgreementImage = await urlToFile(base + data['commission_agreement'], "commission.jpg");
          await prefs.setString("commission", "done");
        }

        if (data['rights_agreement'] != null && data['rights_agreement'] != "") {
          rightsAgreementImage = await urlToFile(base + data['rights_agreement'], "rights.jpg");
          await prefs.setString("rights", "done");
        }

        if (data['delivery_agreement'] != null && data['delivery_agreement'] != "") {
          deliveryAgreementImage = await urlToFile(base + data['delivery_agreement'], "delivery.jpg");
          await prefs.setString("delivery", "done");
        }

        setState(() {});
      }
    } catch (e) {
      print("GET ERROR: $e");
    }
  }

  // ================= PICK =================
  Future<void> pickImage(String type) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);

    setState(() {
      switch (type) {
        case "pan": panImage = file; break;
        case "bank": bankImage = file; break;
        case "selfie": selfieImage = file; break;
        case "general": generalAgreementImage = file; break;
        case "commission": commissionAgreementImage = file; break;
        case "rights": rightsAgreementImage = file; break;
        case "delivery": deliveryAgreementImage = file; break;
      }
    });

    // PAN VERIFY
    if (type == "pan") {
      final input = InputImage.fromFile(file);
      final textData = await textRecognizer.processImage(input);

      String text = textData.text.replaceAll(" ", "").toUpperCase();

      String? match = RegExp(r'[A-Z]{5}[0-9]{4}[A-Z]')
          .firstMatch(text)
          ?.group(0);

    if (match != null) {
  setState(() {
    detectedPan = match;
  });
} else {
  setState(() {
    detectedPan = null;
    panImage = null; // 🔥 remove invalid image also
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("❌ Invalid PAN")),
  );
}

      setState(() {});
    }
  }

  void deleteImage(String type) {
    setState(() {
      switch (type) {
        case "pan": panImage = null; detectedPan = null; break;
        case "bank": bankImage = null; break;
        case "selfie": selfieImage = null; break;
        case "general": generalAgreementImage = null; break;
        case "commission": commissionAgreementImage = null; break;
        case "rights": rightsAgreementImage = null; break;
        case "delivery": deliveryAgreementImage = null; break;
      }
    });
  }

  // ================= SUBMIT =================
  Future<void> submitKyc() async {
    setState(() => isLoading = true);

    var request = http.MultipartRequest("POST", Uri.parse(apiUrl));
    request.fields['vendor_id'] = vendorId.toString();

    if (panImage != null)
      request.files.add(await http.MultipartFile.fromPath('pan', panImage!.path));
    if (bankImage != null)
      request.files.add(await http.MultipartFile.fromPath('bank', bankImage!.path));
    if (selfieImage != null)
      request.files.add(await http.MultipartFile.fromPath('selfie', selfieImage!.path));

    if (generalAgreementImage != null)
      request.files.add(await http.MultipartFile.fromPath('general', generalAgreementImage!.path));
    if (commissionAgreementImage != null)
      request.files.add(await http.MultipartFile.fromPath('commission', commissionAgreementImage!.path));
    if (rightsAgreementImage != null)
      request.files.add(await http.MultipartFile.fromPath('rights', rightsAgreementImage!.path));
    if (deliveryAgreementImage != null)
      request.files.add(await http.MultipartFile.fromPath('delivery', deliveryAgreementImage!.path));

    var res = await http.Response.fromStream(await request.send());
    setState(() => isLoading = false);

    final json = jsonDecode(res.body);

    // SAVE PROGRESS
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (panImage != null) await prefs.setString("pan", "done");
    if (bankImage != null) await prefs.setString("bank", "done");
    if (selfieImage != null) await prefs.setString("selfie", "done");
    if (generalAgreementImage != null) await prefs.setString("general", "done");
    if (commissionAgreementImage != null) await prefs.setString("commission", "done");
    if (rightsAgreementImage != null) await prefs.setString("rights", "done");
    if (deliveryAgreementImage != null) await prefs.setString("delivery", "done");

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(json['message'])));

    Navigator.pop(context, true); // 🔥 IMPORTANT
  }

  // ================= UI =================
  Widget buildImageBox(String title, File? file, String type) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (file == null) {
                pickImage(type);
              }
            },
            child: Container(
              width: 70,
              height: 70,
              color: Colors.grey[200],
              child: file == null
                  ? const Icon(Icons.upload)
                  : Image.file(file, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
          if (file != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => deleteImage(type),
            )
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("KYC Upload"),
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFF3B3F6B),
    ),

    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

            buildImageBox("PAN Card", panImage, "pan"),
            if (detectedPan != null)
              Text(
                "Detected PAN: $detectedPan",
                style: const TextStyle(color: Colors.green),
              ),

            buildImageBox("Bank Passbook", bankImage, "bank"),
            buildImageBox("Selfie", selfieImage, "selfie"),

            const Divider(),

            buildImageBox("General Agreement", generalAgreementImage, "general"),
            buildImageBox("Commission Agreement", commissionAgreementImage, "commission"),
            buildImageBox("Rights Agreement", rightsAgreementImage, "rights"),
            buildImageBox("Delivery Agreement", deliveryAgreementImage, "delivery"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : submitKyc,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B3F6B),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Submit KYC",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
            )
          ],
        ),
      ),
    ),
  );
}}