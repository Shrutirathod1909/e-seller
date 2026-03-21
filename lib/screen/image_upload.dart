import 'dart:io';
import 'package:ecolods/api/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ImageUploadStep extends StatefulWidget {
  final String productId;

  const ImageUploadStep({
    super.key,
    required this.productId,
  });

  @override
  State<ImageUploadStep> createState() => ImageUploadStepState();
}

class ImageUploadStepState extends State<ImageUploadStep> {
  final ImagePicker picker = ImagePicker();

  // Can store either File (local) or String (server URL)
  List<dynamic> images = List.generate(12, (index) => null);

  bool isUploading = false;

  /// PICK IMAGE AND AUTO UPLOAD
  Future pickImage(int index) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        images[index] = File(picked.path);
      });

      // Auto upload the picked image
      await uploadSingleImage(index);
    }
  }

  /// UPLOAD SINGLE IMAGE
 Future uploadSingleImage(int index) async {
  if (images[index] == null) return;

  /// 🔥 IMPORTANT CHECK
  if (widget.productId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Product ID missing ❌")),
    );
    return;
  }

  print("IMAGE STEP PRODUCT ID: ${widget.productId}");

  setState(() => isUploading = true);

  try {
    var uri = Uri.parse("${ApiService.baseUrl}image.php");
    var request = http.MultipartRequest("POST", uri);

    request.fields['productid'] = widget.productId;
    request.fields['image_index'] = (index + 1).toString();

    if (images[index] is File) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "image",
          (images[index] as File).path,
        ),
      );
    }

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    print("UPLOAD RESPONSE: $responseData");

    var jsonResp = jsonDecode(responseData);

    if (response.statusCode == 200 &&
        jsonResp['status'] == 'success') {
      setState(() {
        images[index] =
            "${ApiService.baseUrl}uploads/${jsonResp['image']}";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Image ${index + 1} uploaded successfully ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Image ${index + 1} upload failed")),
      );
    }
  } catch (e) {
    print("Upload error: $e");
  } finally {
    setState(() => isUploading = false);
  }
}

  /// REMOVE IMAGE
  void removeImage(int index) {
    setState(() {
      images[index] = null;
    });
  }

  /// IMAGE BOX
  Widget imageBox(int index) {
    final img = images[index];
    return GestureDetector(
      onTap: () => pickImage(index),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: img == null
                ? const Center(
                    child: Icon(
                      Icons.add_a_photo,
                      color: Color(0xFF3B3F6B),
                      size: 30,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: img is File
                        ? Image.file(
                            img,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Image.network(
                            img,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            },
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                          ),
                  ),
          ),
          if (img != null)
            Positioned(
              top: -5,
              right: -5,
              child: IconButton(
                icon: const Icon(
                  Icons.cancel,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => removeImage(index),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) => imageBox(index),
          ),
        ),
        if (isUploading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  /// Step validation for parent widget
  Future<bool> saveData() async {
    return true;
  }
}