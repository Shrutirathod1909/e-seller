  import 'package:flutter/material.dart';
  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'package:ecolods/api/api_service.dart';

  class ProductDetailScreen extends StatefulWidget {
    final int vendorId;
    final Map<String, dynamic>? existingData;
    final Function(String)? onProductCreated;

    const ProductDetailScreen({
      super.key,
      required this.vendorId,
      this.existingData,
      this.onProductCreated,
    });

    @override
    State<ProductDetailScreen> createState() => ProductDetailScreenState();
  }

  class ProductDetailScreenState extends State<ProductDetailScreen> {
    final _formKey = GlobalKey<FormState>();
    bool isLoading = false;

    // Controllers
    final productName = TextEditingController();
    final subtitleController = TextEditingController();
    final weightController = TextEditingController();
    final hsnController = TextEditingController();
    final countryController = TextEditingController();
    final descriptionController = TextEditingController();

    // Dropdown values
    String? primaryId, categoryId, subCategoryId, childCategoryId;
    String? gender, paymentMethod, gstType, unit;

    List primaryList = [], categoryList = [], subCategoryList = [], childCategoryList = [], unitList = [];

    bool get isEdit => widget.existingData != null;

    @override
    void initState() {
      super.initState();
      fetchPrimary();
      fetchUnit();
      if (isEdit) loadExistingData();
    }

    bool saveData() {
      // This will be called in step 0 before calling saveProduct
      return _formKey.currentState?.validate() ?? false;
    }
    void loadExistingData() {
      final data = widget.existingData!;
      productName.text = data["item_name"] ?? "";
      subtitleController.text = data["subtitle"] ?? "";
      categoryId = data["category"]?.toString();
      subCategoryId = data["subcategory"]?.toString();
      childCategoryId = data["child_category"]?.toString();
      gender = data["gender"];
      paymentMethod = data["payment_method"];
      gstType = data["gst_type"];
      unit = data["unit"];
      weightController.text = data["weight"] ?? "";
      hsnController.text = data["hsn"] ?? "";
      countryController.text = data["country_of_origin"] ?? "";
      descriptionController.text = data["product_description"] ?? "";

      if (categoryId != null) fetchSubCategory(categoryId!);
      if (subCategoryId != null) fetchChildCategory(subCategoryId!);
    }

    /// ================= FETCH =================
    Future fetchPrimary() async {
      var res = await http.get(Uri.parse("${ApiService.baseUrl}categories_api.php?action=primary"));
      var data = json.decode(res.body);
      setState(() => primaryList = data['data'] ?? []);
    }

    Future fetchCategory(String id) async {
      var res = await http.get(Uri.parse("${ApiService.baseUrl}categories_api.php?action=category&primary_id=$id"));
      var data = json.decode(res.body);
      setState(() {
        categoryList = data['data'] ?? [];
        subCategoryList = [];
        childCategoryList = [];
      });
    }

    Future fetchSubCategory(String id) async {
      var res = await http.get(Uri.parse("${ApiService.baseUrl}categories_api.php?action=subcategory&category_id=$id"));
      var data = json.decode(res.body);
      setState(() {
        subCategoryList = data['data'] ?? [];
        childCategoryList = [];
      });
    }

    Future fetchChildCategory(String id) async {
      var res = await http.get(Uri.parse("${ApiService.baseUrl}categories_api.php?action=childcategory&subcategory_id=$id"));
      var data = json.decode(res.body);
      setState(() => childCategoryList = data['data'] ?? []);
    }

    Future fetchUnit() async {
      var res = await http.get(Uri.parse("${ApiService.baseUrl}categories_api.php?action=unitmeasurement"));
      var data = json.decode(res.body);
      setState(() => unitList = data['data'] ?? []);
    }

    /// ================= SAVE =================
  Future<String?> saveProduct() async {
  if (!(_formKey.currentState?.validate() ?? false)) return null;

  print("VENDOR ID: ${widget.vendorId}");

  if (categoryId == null || subCategoryId == null || childCategoryId == null) {
    showMsg("Please select Category, Subcategory & Child Category");
    return null;
  }
  if (gender == null) {
    showMsg("Please select Gender");
    return null;
  }
  if (paymentMethod == null) {
    showMsg("Please select Payment Method");
    return null;
  }
  if (gstType == null) {
    showMsg("Please select GST Type");
    return null;
  }
  if (unit == null) {
    showMsg("Please select Unit");
    return null;
  }

  setState(() => isLoading = true);

  try {
    var res = await http.post(
      Uri.parse("${ApiService.baseUrl}product.php"),
      body: {
        "action": "add",
        "vendor_id": widget.vendorId.toString(), // ✅ FIX
        "item_name": productName.text.trim(),
        "subtitle": subtitleController.text.trim(),
        "category": categoryId ?? "",
        "subcategory": subCategoryId ?? "",
        "child_category": childCategoryId ?? "",
        "gender": gender ?? "",
        "payment_method": paymentMethod ?? "",
        "gst_type": gstType ?? "",
        "unit": unit ?? "",
        "weight": weightController.text.trim(),
        "hsn": hsnController.text.trim(),
        "country_of_origin": countryController.text.trim(),
        "product_description": descriptionController.text.trim(),
      },
    );

    print("BODY: ${res.body}");

    var data = json.decode(res.body);

    if (data["status"] == "success" && data["productid"] != null) {
      String id = data["productid"].toString();

      widget.onProductCreated?.call(id);

      showMsg("Product Created ✅ ID: $id");
      return id;
    } else {
      showMsg(data["message"] ?? "Failed ❌");
    }
  } catch (e) {
    showMsg("Error: $e");
  } finally {
    setState(() => isLoading = false);
  }

  return null;
}   void showMsg(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    /// ================= UI =================
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text("Product Details")),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      textField(productName, "Product Name"),
                      textField(subtitleController, "Subtitle"),
                      autoDropdown("Primary", primaryList, primaryId, (v) {
                        setState(() => primaryId = v);
                        fetchCategory(v!);
                      }),
                      autoDropdown("Category", categoryList, categoryId, (v) {
                        setState(() => categoryId = v);
                        fetchSubCategory(v!);
                      }),
                      autoDropdown("SubCategory", subCategoryList, subCategoryId, (v) {
                        setState(() => subCategoryId = v);
                        fetchChildCategory(v!);
                      }),
                      autoDropdown("Child Category", childCategoryList, childCategoryId, (v) => setState(() => childCategoryId = v)),
                      simpleDropdown("Gender", ["Male", "Female", "Both"], gender, (v) => setState(() => gender = v)),
                      simpleDropdown("Payment", ["Prepaid", "COD", "Both"], paymentMethod, (v) => setState(() => paymentMethod = v)),
                      simpleDropdown("GST Type", ["N/A", "Inc", "Exc"], gstType, (v) => setState(() => gstType = v)),
                      unitDropdown(),
                      textField(weightController, "Weight", keyboardType: TextInputType.number),
                      textField(hsnController, "HSN Code", keyboardType: TextInputType.number),
                      textField(countryController, "Country"),
                      textField(descriptionController, "Description", maxLines: 3),
                      const SizedBox(height: 20),
                      ElevatedButton(
  onPressed: widget.vendorId == 0
      ? null
      : () async {

          String? id = await saveProduct();
          if (id != null) {
            showMsg("Product saved ✅ ID: $id");
          }
        },
                        child: const Text("Save Product"),
                      ),
                    ],
                  ),
                ),
              ),
      );
    }

    Widget textField(TextEditingController controller, String hint,
        {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: (v) => v!.isEmpty ? "$hint required" : null,
          decoration: InputDecoration(
            labelText: hint,
            filled: true,
            fillColor: const Color(0xffECECF3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    Widget simpleDropdown(String hint, List list, String? value, Function(String?) onChanged) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: hint,
            filled: true,
            fillColor: const Color(0xffECECF3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: list.map<DropdownMenuItem<String>>((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      );
    }

    Widget unitDropdown() {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          value: unit,
          decoration: InputDecoration(
            labelText: "Unit",
            filled: true,
            fillColor: const Color(0xffECECF3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: unitList.map<DropdownMenuItem<String>>((item) => DropdownMenuItem(value: item["name"], child: Text(item["name"]))).toList(),
          onChanged: (v) => setState(() => unit = v),
        ),
      );
    }

    Widget autoDropdown(String label, List list, String? value, Function(String?) onSelected) {
      final options = list.cast<Map<String, dynamic>>();

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: Autocomplete<Map<String, dynamic>>(
          optionsBuilder: (text) {
            if (text.text.isEmpty) return options;
            return options.where((item) => item["name"].toString().toLowerCase().contains(text.text.toLowerCase()));
          },
          displayStringForOption: (option) => option["name"].toString(),
          onSelected: (item) => onSelected(item["id"].toString()),
          fieldViewBuilder: (context, controller, focusNode, _) {
            if (value != null && controller.text.isEmpty) {
              final selected = options.firstWhere((e) => e["id"].toString() == value, orElse: () => {});
              controller.text = selected["name"]?.toString() ?? "";
            }
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: label,
                filled: true,
                fillColor: const Color(0xffECECF3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        ),
      );
    }
  }