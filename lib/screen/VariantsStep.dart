import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ecolods/api/api_service.dart';

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

  List<Map<String, dynamic>> variants = [];

  @override
  void initState() {
    super.initState();

    /// 🔥 Prefill existing variants
    if (widget.existingVariants.isNotEmpty) {
      variants = widget.existingVariants.map<Map<String, dynamic>>((e) {
        return {
          "id": e["id"], // 🔥 needed for update
          "colour": e["colour"] ?? "",
          "size": e["size"] ?? "",
          "sku_code": e["sku_code"] ?? "",
          "sale_price": e["sale_price"].toString(),
          "qty": e["qty"].toString(),
        };
      }).toList();
    } else {
      addVariant();
    }
  }

  /// ➕ Add Variant
  void addVariant() {
    setState(() {
      variants.add({
        "id": null,
        "colour": "",
        "size": "",
        "sku_code": "",
        "sale_price": "",
        "qty": "",
      });
    });
  }

  /// ❌ Remove Variant
  void removeVariant(int index) {
    setState(() {
      variants.removeAt(index);
    });
  }

  /// ✅ Validate
  bool validateVariants() {
    for (var v in variants) {
      if (v["colour"].toString().isEmpty ||
          v["size"].toString().isEmpty ||
          v["sku_code"].toString().isEmpty ||
          v["sale_price"].toString().isEmpty ||
          v["qty"].toString().isEmpty) {
        return false;
      }
    }
    return true;
  }

  /// 🔥 SAVE API (ADD + UPDATE)
  Future<bool> saveData() async {
    if (isSaving) return false;

    if (!validateVariants()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all variant fields")),
      );
      return false;
    }

    isSaving = true;

    try {
      var body = {
        "action": "update_variants",
        "product_id": widget.productId,
        "vendor_id": widget.vendorId,
        "variants": variants,
      };

      print("==== PAYLOAD ====");
      print(jsonEncode(body));

      var res = await http.post(
        Uri.parse("${ApiService.baseUrl}product.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("==== RESPONSE ====");
      print(res.body);

      var data = json.decode(res.body);

      if (data["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Variants Saved Successfully")),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Error")),
        );
        return false;
      }
    } catch (e) {
      print("ERROR: $e");
      return false;
    } finally {
      isSaving = false;
    }
  }

  /// 🧾 Input Field
  Widget inputField(String hint, String key, int index,
      {TextInputType type = TextInputType.text}) {
    return Expanded(
      child: TextFormField(
        keyboardType: type,
        initialValue: variants[index][key]?.toString() ?? "",
        onChanged: (val) {
          variants[index][key] = val;
        },
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

  /// 🎨 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Variants"),
      ),
      body: Column(
        children: [
          /// LIST
          Expanded(
            child: ListView.builder(
              itemCount: variants.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            inputField("Color", "colour", index),
                            const SizedBox(width: 10),
                            inputField("Size", "size", index),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            inputField("SKU", "sku_code", index),
                            const SizedBox(width: 10),
                            inputField("Price", "sale_price", index,
                                type: TextInputType.number),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            inputField("Qty", "qty", index,
                                type: TextInputType.number),
                            IconButton(
                              onPressed: () => removeVariant(index),
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// ➕ ADD BUTTON
          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: addVariant,
              child: const Text("Add Variant"),
            ),
          ),

          /// 💾 SAVE BUTTON
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  bool success = await saveData();
                  if (success) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text("Save Variants"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}