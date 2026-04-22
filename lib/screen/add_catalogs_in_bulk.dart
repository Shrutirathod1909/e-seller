import 'dart:convert';
import 'dart:io';
import 'package:ecolods/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// -------------------------
/// CSV Upload Screen
/// -------------------------
/// -------------------------
/// CSV Upload Screen (Updated UI)
/// -------------------------
class UploadTemplateScreen extends StatefulWidget {
  const UploadTemplateScreen({super.key});

  @override
  State<UploadTemplateScreen> createState() => _UploadTemplateScreenState();
}

class _UploadTemplateScreenState extends State<UploadTemplateScreen> {
  File? selectedFile;
  bool isLoading = false;

  String vendorId = "0";
  String companyId = "0";

  List products = [];
  bool showResultBox = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      vendorId = prefs.get("vendor_id")?.toString() ?? "0";
      companyId = prefs.get("company_id")?.toString() ?? "0";
    });
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        showResultBox = false;
      });
    }
  }

  Future<void> uploadFile() async {
    if (selectedFile == null) {
      showMsg("Please select file");
      return;
    }
    if (vendorId == "0" || companyId == "0") {
      showMsg("Vendor/Company missing. Login again.");
      return;
    }

    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiService.baseUrl}add_catalogs_bulk.php"),
      );

      request.fields['vendor_id'] = vendorId;
      request.fields['company_id'] = companyId;

      request.files.add(
        await http.MultipartFile.fromPath('file', selectedFile!.path),
      );

      var response = await request.send();
      var res = await response.stream.bytesToString();

      setState(() => isLoading = false);

      var jsonRes = jsonDecode(res);

      if (response.statusCode == 200 && jsonRes['status'] == true) {
        showMsg(jsonRes['msg']);

        setState(() {
          products = jsonRes['products'];
          showResultBox = true;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BulkImageUploadScreen(
              products: products,
              createdBy: vendorId,
            ),
          ),
        );
      } else {
        showMsg(jsonRes['msg'] ?? "Upload Failed");
      }
    } catch (e) {
      setState(() => isLoading = false);
      showMsg("Error: $e");
    }
  }

  Future<void> downloadTemplate() async {
    final url = Uri.parse("${ApiService.baseUrl}downloadtemplate.php");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Widget _gradientButton({required String text, required VoidCallback onTap}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B3F6B), Color(0xFF3C67A0)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Text(
              text,
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text("Upload Template"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B3F6B), Color(0xFF3C67A0)],
            ),
          ),
        ),
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double boxWidth = constraints.maxWidth > 900
                ? 520
                : constraints.maxWidth > 600
                    ? 450
                    : constraints.maxWidth * 0.92;

            return SingleChildScrollView(
              child: Container(
                width: boxWidth,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Upload CSV Template",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Upload your CSV file to import products",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // File picker
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: pickFile,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B3F6B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "Choose File",
                                style: TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedFile != null
                                  ? selectedFile!.path.split('/').last
                                  : "No file selected",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Buttons
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        _gradientButton(
                          text: isLoading ? "Uploading..." : "START UPLOAD",
                          onTap: isLoading ? () {} : uploadFile,
                        ),
                        _gradientButton(
                          text: "DOWNLOAD TEMPLATE",
                          onTap: downloadTemplate,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// -------------------------
/// Bulk Image Upload Screen (Updated UI)
/// -------------------------
class BulkImageUploadScreen extends StatefulWidget {
  final List products;
  final String createdBy;

  const BulkImageUploadScreen({
    super.key,
    required this.products,
    required this.createdBy,
  });

  @override
  State<BulkImageUploadScreen> createState() => _BulkImageUploadScreenState();
}

class _BulkImageUploadScreenState extends State<BulkImageUploadScreen> {
  Map<int, List<XFile>> selectedImages = {};
  Map<int, bool> isUploadingMap = {}; // separate upload state per product

  @override
  void initState() {
    super.initState();
    loadExistingImages();
  }

  Future<void> loadExistingImages() async {
    for (var p in widget.products) {
      int pid = int.tryParse(p['product_id'].toString()) ?? 0;
      var url = Uri.parse('${ApiService.baseUrl}get_product_images.php?product_id=$pid');
      var resp = await http.get(url);
      if (resp.statusCode == 200) {
        var jsonRes = jsonDecode(resp.body);
        if (jsonRes['status'] == true) {
          setState(() {
            selectedImages[pid] = (jsonRes['images'] as List)
                .map((img) => XFile(img['url']))
                .toList();
          });
        }
      }
    }
  }

  Future<void> pickImages(int productId) async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        selectedImages[productId] = [
          ...?selectedImages[productId],
          ...picked,
        ];
      });
    } else {
      showMsg("No images selected");
    }
  }

  Future<void> uploadImages(int productId, String skuCode) async {
    if (isUploadingMap[productId] == true) return; // prevent double tap

    final images = selectedImages[productId];
    if (images == null || images.isEmpty) {
      showMsg("Please pick images first");
      return;
    }

    setState(() => isUploadingMap[productId] = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}bluk_image_upload.php'),
      );

      request.fields['product_id'] = productId.toString();
      request.fields['sku_code'] = skuCode;
      request.fields['created_by'] = widget.createdBy;

      for (var img in images) {
        if (img.path.startsWith('http')) continue;
        request.files.add(await http.MultipartFile.fromPath('image[]', img.path));
      }

      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      var jsonResp = jsonDecode(respStr);

      showMsg(jsonResp['msg'] ?? 'Image upload failed');
      if (jsonResp['status'] == true) loadExistingImages();
    } catch (e) {
      showMsg("Error: $e");
    } finally {
      setState(() => isUploadingMap[productId] = false);
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _gradientButton({required String text, required VoidCallback onTap, bool disabled = false}) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: disabled
            ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
            : const LinearGradient(colors: [Color(0xFF3B3F6B), Color(0xFF3C67A0)]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: disabled ? null : onTap,
          child: Center(
            child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
                foregroundColor: Colors.white,

        title: const Text(
          "Bulk Image Upload",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF3B3F6B), Color(0xFF3C67A0)]),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: widget.products.length,
        itemBuilder: (context, index) {
          var p = widget.products[index];
          int pid = int.tryParse(p['product_id'].toString()) ?? 0;
          List<XFile>? images = selectedImages[pid];
          bool isUploading = isUploadingMap[pid] == true;

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['item_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("SKU: ${p['sku_code'] ?? ''}", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  if (images != null && images.isNotEmpty)
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, i) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: images[i].path.startsWith('http')
                                  ? Image.network(images[i].path, width: 80, height: 80, fit: BoxFit.cover)
                                  : Image.file(File(images[i].path), width: 80, height: 80, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    SizedBox(height: 80, child: Center(child: Text("No images"))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _gradientButton(
                          text: "Pick Images",
                          onTap: () => pickImages(pid),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _gradientButton(
                          text: isUploading ? "Uploading..." : "Upload",
                          onTap: () => uploadImages(pid, p['sku_code'] ?? ''),
                          disabled: isUploading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}