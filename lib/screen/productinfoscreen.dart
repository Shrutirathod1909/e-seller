import 'package:ecolods/api/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class ProductInfoStep extends StatefulWidget {
  final String productId;
  final Function(double)? onPriceChanged;
  final Map<String, dynamic>? existingData;

  const ProductInfoStep({
    super.key,
    required this.productId,
    this.onPriceChanged,
    this.existingData,
  });

  @override
  State<ProductInfoStep> createState() => ProductInfoStepState();
}

class ProductInfoStepState extends State<ProductInfoStep> {
  final _formKey = GlobalKey<FormState>();

  final brand = TextEditingController();
  final sku = TextEditingController();
  final barcode = TextEditingController();
  final material = TextEditingController();
  final color = TextEditingController();
  final size = TextEditingController();

  final length = TextEditingController();
  final width = TextEditingController();
  final height = TextEditingController();
  final weight = TextEditingController();

  final warranty = TextEditingController();
  final cadPrice = TextEditingController();

  bool get isEdit => widget.existingData != null;

  @override
  void initState() {
    super.initState();

    final data = widget.existingData ?? {};

    brand.text = data["brand"]?.toString() ?? "";
    sku.text = data["sku"]?.toString() ?? "";
    barcode.text = data["barcode"]?.toString() ?? "";
    material.text = data["material"]?.toString() ?? "";
    color.text = data["color"]?.toString() ?? "";
    size.text = data["size"]?.toString() ?? "";

    width.text = data["width"]?.toString() ?? "";
    height.text = data["height"]?.toString() ?? "";
    weight.text = data["weight"]?.toString() ?? "";

    cadPrice.text = data["cad_price"]?.toString() ?? "";
    warranty.text = data["warranty"]?.toString() ?? "";

    loadProductInfo();
  }

  /// ================= GET =================
  Future loadProductInfo() async {
    try {
      var url = Uri.parse("${ApiService.baseUrl}product_info.php");

      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get",
          "productid": widget.productId
        }),
      );

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {
        final d = data["data"];

        setState(() {
          sku.text = d["sku"] ?? "";
          barcode.text = d["barcode"] ?? "";
          material.text = d["material"] ?? "";
          color.text = d["color"] ?? "";
          size.text = d["size"] ?? "";

          width.text = d["width"] ?? "";
          height.text = d["height"] ?? "";
          weight.text = d["weight"] ?? "";

          cadPrice.text = (d["cad_price"] ?? 0).toString();

          warranty.text =
              (d["warranty_desc"] ?? "").toString().replaceAll(" Months", "");
        });
      }
    } catch (e) {
      print("ERROR: $e");
    }
  }

  /// ================= SAFE PARSE =================
  double safeDouble(String v) {
    if (v.trim().isEmpty) return 0.0;
    return double.tryParse(v) ?? 0.0;
  }

  /// ================= FORM DATA =================
  Map<String, dynamic> getFormData() {
    double cad = safeDouble(cadPrice.text);

    return {
      "action": "update",
      "productid": widget.productId,

      "sku": sku.text,
      "barcode": barcode.text,
      "material": material.text,
      "color": color.text,
      "size": size.text,

      "height": height.text,
      "width": width.text,
      "weight": weight.text,

      "warranty": warranty.text.isNotEmpty
          ? "${warranty.text} Months"
          : "",

      // 🔥 IMPORTANT FIX (NO NULL EVER)
      "mrp_price": 0.0,
      "sale_price": 0.0,
      "cad_price": cad,
    };
  }

  /// ================= SAVE =================
  Future<bool> saveData() async {
    if (!_formKey.currentState!.validate()) return false;

    double price = safeDouble(cadPrice.text);
    widget.onPriceChanged?.call(price);

    try {
      var url = Uri.parse("${ApiService.baseUrl}product_info.php");

      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(getFormData()),
      );

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {
        await loadProductInfo();
        return true;
      }

      return false;
    } catch (e) {
      print("ERROR: $e");
      return false;
    }
  }

  /// ================= FIELD =================
  Widget inputField(
    String label,
    IconData icon,
    TextEditingController c, {
    bool isNumber = false,
    bool isTextOnly = false,
    bool isRequiredAlways = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType:
            isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: [
          if (isNumber)
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          if (isTextOnly)
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
        ],
        validator: (v) {
          if (isRequiredAlways && (v == null || v.trim().isEmpty)) {
            return "$label is required";
          }

          if (!isEdit && (v == null || v.trim().isEmpty)) {
            return "$label is required";
          }

          if (isNumber &&
              v != null &&
              v.trim().isNotEmpty &&
              double.tryParse(v) == null) {
            return "Enter valid number";
          }

          if (label == "CAD Price" &&
              v != null &&
              v.trim().isNotEmpty &&
              double.tryParse(v)! <= 0) {
            return "Price must be greater than 0";
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// BASIC
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5)
                ],
              ),
              child: Column(
                children: [
                  inputField("Brand Name", Icons.business, brand, isTextOnly: true),
                  inputField("SKU Code", Icons.qr_code, sku),
                  inputField("Barcode", Icons.qr_code_2, barcode, isNumber: true),
                  inputField("Material", Icons.category, material, isTextOnly: true),
                  inputField("Color", Icons.palette, color, isTextOnly: true),
                  inputField("Size", Icons.straighten, size),

                  inputField(
                    "CAD Price",
                    Icons.currency_rupee,
                    cadPrice,
                    isNumber: true,
                    isRequiredAlways: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// DIMENSIONS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5)
                ],
              ),
              child: Column(
                children: [
                  inputField("Length", Icons.height, length, isNumber: true),
                  inputField("Width", Icons.width_full, width, isNumber: true),
                  inputField("Height", Icons.height_outlined, height, isNumber: true),
                  inputField("Weight", Icons.scale, weight, isNumber: true),
                  inputField("Warranty (Months)", Icons.verified, warranty, isNumber: true),
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
    brand.dispose();
    sku.dispose();
    barcode.dispose();
    material.dispose();
    color.dispose();
    size.dispose();
    length.dispose();
    width.dispose();
    height.dispose();
    weight.dispose();
    warranty.dispose();
    cadPrice.dispose();
    super.dispose();
  }
}