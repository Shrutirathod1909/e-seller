import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:ecolods/api/api_service.dart';

class ImageUploadStep extends StatefulWidget {
  final String productId;
  final Map<String, dynamic>? existingData;

  const ImageUploadStep({
    super.key,
    required this.productId,
    this.existingData,
  });

  @override
  State<ImageUploadStep> createState() => ImageUploadStepState();
}

class ImageUploadStepState extends State<ImageUploadStep> {
  final picker = ImagePicker();

  List<dynamic> images = List.filled(12, null);
  List<File?> tempFiles = List.filled(12, null);

  bool isUploading = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadImagesFromAPI();
  }

  /* ================= GET IMAGES ================= */

  Future loadImagesFromAPI() async {
    try {
      var response = await http.post(
        Uri.parse("${ApiService.baseUrl}image.php"),
        body: {
          "productid": widget.productId.toString(),
        },
      );

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {
        setState(() {
          images = List.filled(12, null);
          List list = data["images"];

          for (int i = 0; i < list.length && i < 12; i++) {
            images[i] = list[i];
          }
        });
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
  }

  /* ================= PICK IMAGE ================= */

  Future pickImage(int index) async {
    if (isUploading) return;

    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        tempFiles[index] = File(picked.path);
      });

      uploadImage(index);
    }
  }

  /* ================= UPLOAD IMAGE ================= */

  Future uploadImage(int index) async {
    if (tempFiles[index] == null) return;

    setState(() => isUploading = true);

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiService.baseUrl}image.php"),
      );

      request.fields["productid"] = widget.productId.toString();
      request.fields["image_index"] = (index + 1).toString();

      request.files.add(
        await http.MultipartFile.fromPath(
          "image",
          tempFiles[index]!.path,
        ),
      );

      var response = await request.send();
      var res = await response.stream.bytesToString();
      var jsonResp = jsonDecode(res);

      if (jsonResp["status"] == "success") {
        setState(() {
          images[index] = jsonResp["image"];
          tempFiles[index] = null;
        });
      }
    } catch (e) {
      debugPrint("Upload error: $e");
    }

    setState(() => isUploading = false);
  }

  /* ================= DELETE IMAGE ================= */

  Future removeImage(int index) async {
    try {
      await http.post(
        Uri.parse("${ApiService.baseUrl}image.php"),
        body: {
          "productid": widget.productId.toString(),
          "image_index": (index + 1).toString(),
          "delete": "1",
        },
      );

      setState(() {
        images[index] = null;
        tempFiles[index] = null;
      });
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  /* ================= FORM DATA ================= */

  Map<String, dynamic> getFormData() {
    return {
      "productId": widget.productId,
      "images": images.whereType<String>().toList(),
    };
  }

  /* ================= VALIDATION ================= */

  Future<bool> saveData() async {
    if (isSaving) return false;

    setState(() => isSaving = true);

    try {
      if (!images.any((e) => e != null && e.toString().isNotEmpty)) {
        setState(() => isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Please upload at least 1 image")),
        );

        return false;
      }

      debugPrint("📦 FINAL IMAGE DATA:");
      debugPrint(jsonEncode(getFormData()));

      setState(() => isSaving = false);
      return true;
    } catch (e) {
      setState(() => isSaving = false);
      return false;
    }
  }

  /* ================= IMAGE BOX ================= */

  Widget imageBox(int index) {
    final img = images[index];
    final file = tempFiles[index];

    return GestureDetector(
      onTap: () => pickImage(index),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: file != null
                  ? Image.file(file, fit: BoxFit.cover)
                  : img != null
                      ? Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.broken_image),
                        )
                      : const Center(child: Icon(Icons.add_a_photo)),
            ),
          ),

          if (img != null || file != null)
            Positioned(
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => removeImage(index),
              ),
            ),
        ],
      ),
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: 12,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) => imageBox(index),
        ),

        if (isUploading)
          const Center(child: CircularProgressIndicator()),

        if (isSaving)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}