import 'dart:convert';
import 'package:ecolods/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class VariantsStep extends StatefulWidget {
  final int productId;
  final int vendorId;
  final List existingVariants;

  const VariantsStep({
    super.key,
    required this.productId,
    required this.vendorId,
    required this.existingVariants,
  });

  @override
  State<VariantsStep> createState() => VariantsStepState();
}

class VariantsStepState extends State<VariantsStep> {
  bool isSaving = false;
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> variants = [];
  final Map<String, Map<String, TextEditingController>> controllers = {};

  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();

    if (widget.existingVariants.isNotEmpty) {
      for (var e in widget.existingVariants) {
        String uid = uuid.v4();

        variants.add({
          "uid": uid,
          "id": e["id"],
        });

        controllers[uid] = {
          "colour": TextEditingController(text: e["colour"] ?? ""),
          "size": TextEditingController(text: e["size"] ?? ""),
          "sku_code": TextEditingController(text: e["sku_code"] ?? ""),
          "list_price": TextEditingController(
              text: e["list_price"]?.toString() ?? ""),
          "qty":
              TextEditingController(text: e["qty"]?.toString() ?? ""),
        };
      }
    } else {
      addVariant();
    }
  }

  @override
  void dispose() {
    for (var map in controllers.values) {
      for (var c in map.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  /// ================= ADD =================
  void addVariant() {
    setState(() {
      String uid = uuid.v4();

      variants.add({
        "uid": uid,
        "id": null,
      });

      controllers[uid] = {
        "colour": TextEditingController(),
        "size": TextEditingController(),
        "sku_code": TextEditingController(),
        "list_price": TextEditingController(),
        "qty": TextEditingController(),
      };
    });
  }

  /// ================= REMOVE =================
  void removeVariant(int index) {
    if (variants.length == 1) return;

    setState(() {
      String uid = variants[index]["uid"];

      controllers[uid]?.forEach((_, c) => c.dispose());
      controllers.remove(uid);

      variants.removeAt(index);
    });
  }

  /// ================= CLEAN DATA =================
  List<Map<String, dynamic>> getCleanVariants() {
    List<Map<String, dynamic>> result = [];

    for (var v in variants) {
      String uid = v["uid"];

      String sku = controllers[uid]?["sku_code"]?.text.trim() ?? "";

      if (sku.isEmpty) continue;

      result.add({
        "id": v["id"],
        "colour": controllers[uid]?["colour"]?.text.trim() ?? "",
        "size": controllers[uid]?["size"]?.text.trim() ?? "",
        "sku_code": sku,
        "list_price": double.tryParse(
                controllers[uid]?["list_price"]?.text.trim() ?? "") ??
            0,
        "qty":
            int.tryParse(controllers[uid]?["qty"]?.text.trim() ?? "") ??
                0,
      });
    }

    return result;
  }

  /// ================= VALIDATE SKU =================
  bool validateDuplicateSKU(List variants) {
    final skus = <String>{};

    for (var v in variants) {
      if (skus.contains(v["sku_code"])) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Duplicate SKU: ${v["sku_code"]}")),
        );
        return false;
      }
      skus.add(v["sku_code"]);
    }
    return true;
  }

  /// ================= SAVE API =================
  Future<bool> saveData() async {
    if (isSaving) return false;

    if (!(_formKey.currentState?.validate() ?? false)) return false;

    List clean = getCleanVariants();

    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No valid variants")),
      );
      return false;
    }

    if (!validateDuplicateSKU(clean)) return false;

    setState(() => isSaving = true);

    try {
      var res = await http.post(
        Uri.parse("${ApiService.baseUrl}product.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "update_variants",
          "product_id": widget.productId,
          "vendor_id": widget.vendorId,
          "variants": clean,
        }),
      );

      var data = json.decode(res.body);

      if (data["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved Successfully")),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Error")),
        );
        return false;
      }
    } catch (e) {
      debugPrint("ERROR: $e");
      return false;
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  /// ================= INPUT FIELD =================
  Widget inputField(String hint, String key, int index,
      {bool isNumber = false, bool isTextOnly = false}) {
    String uid = variants[index]["uid"];

    return Expanded(
      child: TextFormField(
        controller: controllers[uid]?[key],
        keyboardType:
            isNumber ? TextInputType.number : TextInputType.text,
        validator: (val) {
          if (key == "sku_code" && (val == null || val.trim().isEmpty)) {
            return "SKU required";
          }

          if (key == "list_price") {
            if (val == null || val.trim().isEmpty) {
              return "Price required";
            }
            if (double.tryParse(val) == null ||
                double.parse(val) <= 0) {
              return "Invalid price";
            }
          }

          if (val == null || val.trim().isEmpty) {
            return "$hint required";
          }

          if (isNumber && num.tryParse(val) == null) {
            return "Invalid number";
          }

          if (isTextOnly &&
              !RegExp(r'^[a-zA-Z ]+$').hasMatch(val)) {
            return "Only text allowed";
          }

          return null;
        },
        inputFormatters: [
          if (isNumber) FilteringTextInputFormatter.digitsOnly,
          if (isTextOnly)
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
        ],
        decoration: InputDecoration(
          labelText: hint,
          filled: true,
          fillColor: const Color(0xffECECF3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> getFormData() {
    return {
      "product_id": widget.productId,
      "vendor_id": widget.vendorId,
      "variants": getCleanVariants(),
    };
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: variants.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6)
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Variant ${index + 1}"),
                          IconButton(
                            onPressed: variants.length == 1
                                ? null
                                : () => removeVariant(index),
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                          )
                        ],
                      ),

                      Row(
                        children: [
                          inputField("Color", "colour", index,
                              isTextOnly: true),
                          const SizedBox(width: 10),
                          inputField("Size", "size", index),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          inputField("SKU", "sku_code", index),
                          const SizedBox(width: 10),
                          inputField("List Price", "list_price", index,
                              isNumber: true),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          inputField("Qty", "qty", index,
                              isNumber: true),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: addVariant,
                child: const Icon(Icons.add),
              ),
            ),

            if (isSaving)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}