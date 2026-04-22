import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ecolods/api/api_service.dart';
import 'package:flutter/services.dart';

class ProductDetailScreen extends StatefulWidget {
  final int vendorId;
    final int companyId;
  final Map<String, dynamic>? existingData;
  final Function(String)? onProductCreated;


  const ProductDetailScreen({
    super.key,
    required this.vendorId,
        required this.companyId,
    this.existingData,
    this.onProductCreated,
  });

  @override
  State<ProductDetailScreen> createState() => ProductDetailScreenState();
}

class ProductDetailScreenState extends State<ProductDetailScreen> {
String? primaryName;
String? categoryName;
String? subCategoryName;
String? childCategoryName;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  /// Controllers
  final productName = TextEditingController();
  final subtitleController = TextEditingController();
  final weightController = TextEditingController();
  final hsnController = TextEditingController();
  final countryController = TextEditingController();
  final descriptionController = TextEditingController();

  /// Dropdown values
  String? primaryId, categoryId, subCategoryId, childCategoryId;
  String? gender, paymentMethod, gstType, symbol;

  List primaryList = [],
      categoryList = [],
      subCategoryList = [],
      childCategoryList = [],
      unitList = [];

bool get isEdit {
  final id = widget.existingData?["productid"];
  return id != null && id.toString().isNotEmpty && id.toString() != "0";
}

  @override
  void initState() {
    super.initState();
    fetchPrimary();
    fetchUnit();

    /// ✅ IMPORTANT FIX (draft + edit both)
    if (widget.existingData != null) {
      loadExistingData();
    }
  }

  /// ================= LOAD EXISTING =================
  void loadExistingData() {
    final data = widget.existingData!;

    productName.text = data["item_name"] ?? "";
    subtitleController.text = data["subtitle"] ?? "";

    primaryId = data["primary_categories_name"]?.toString(); // ✅ FIX
    categoryId = data["category"]?.toString();
    subCategoryId = data["subcategory"]?.toString();
    childCategoryId = data["child_category"]?.toString();

    gender = data["gender"];
    paymentMethod = data["payment_method"];
    gstType = data["gst_type"];
    symbol = data["symbol"];

    weightController.text = data["weight"] ?? "";
    hsnController.text = data["hsn"] ?? "";
    countryController.text = data["country_of_origin"] ?? "";
    descriptionController.text = data["product_description"] ?? "";

    /// cascading dropdown restore
    if (primaryId != null) fetchCategory(primaryId!);
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

    int productIdInt = isEdit
        ? int.tryParse(widget.existingData!["productid"].toString()) ?? 0
        : 0;

    setState(() => isLoading = true);

    try {
      var res = await http.post(
        Uri.parse("${ApiService.baseUrl}product.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": (productIdInt > 0) ? "update_product" : "add",
if (productIdInt > 0) "productid": productIdInt,
          "vendor_id": widget.vendorId,
          "company_id": widget.companyId,
          "item_name": productName.text.trim(),
          "subtitle": subtitleController.text.trim(),
         "primary_categories_name": primaryName ?? primaryId ??"",
"category": categoryName ?? categoryId ?? "",
"subcategory": subCategoryName ?? subCategoryId ?? "",
"child_category": childCategoryName ?? childCategoryId ?? "",
          "gender": gender ?? "",
          "payment_method": paymentMethod ?? "",
          "gst_type": gstType ?? "",
        "symbol": symbol ?? "",
          "weight": weightController.text.trim(),
          "hsn": hsnController.text.trim(),
          "country_of_origin": countryController.text.trim(),
          "product_description": descriptionController.text.trim(),
        }),
      );

      var data = json.decode(res.body);

 if (data["status"] == "success") {

  String id = data["productid"].toString();

  // ✅ FULL DATA UPDATE (IMPORTANT)
  if (data["product"] != null) {
    setState(() {
      widget.existingData?.clear();
      widget.existingData?.addAll(data["product"]);
      loadExistingData();
    });
  }

  // ✅ Update existingData with full product
  if (isEdit && data["product"] != null) {
    setState(() {
      widget.existingData?.clear();
      widget.existingData?.addAll(data["product"]);
      loadExistingData(); // reload all fields including dropdowns
    });
  }

  widget.onProductCreated?.call(id);
  showMsg(isEdit ? "Product Updated ✅" : "Product Created ✅");

     print("===== REQUEST DATA =====");
  print("RESPONSE: ${res.body}");

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
  }

  /// ✅ ================= GET FORM DATA =================
  Map<String, dynamic> getFormData() {
    return {
      "company_id": widget.companyId,
      "item_name": productName.text.trim(),
      "subtitle": subtitleController.text.trim(),
      "primary_id": primaryId,
      "category": categoryId,
      "subcategory": subCategoryId,
      "child_category": childCategoryId,
      "gender": gender,
      "payment_method": paymentMethod,
      "gst_type": gstType,
      "symbol": symbol,
      "weight": weightController.text.trim(),
      "hsn": hsnController.text.trim(),
      "country_of_origin": countryController.text.trim(),
      "product_description": descriptionController.text.trim(),
    };
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    cardContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Product Info",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          textField(productName, "Product Name",
                              icon: Icons.shopping_bag),
                          textField(subtitleController, "Subtitle",
                              icon: Icons.edit),
autoDropdown(
  "Primary",
  primaryList,
  primaryId,
  (id, name) {
    setState(() {
      primaryId = id;
      primaryName = name;
    });
    fetchCategory(id!);
  },
  Icons.layers,
),

                          autoDropdown(
  "Category",
  categoryList,
  categoryId,
  (id, name) {
    setState(() {
      categoryId = id;
      categoryName = name;
    });
    fetchSubCategory(id!);
  },
  Icons.category,
),

autoDropdown(
  "SubCategory",
  subCategoryList,
  subCategoryId,
  (id, name) {
    setState(() {
      subCategoryId = id;
      subCategoryName = name;
    });
    fetchChildCategory(id!);
  },
  Icons.list_alt,
),

autoDropdown(
  "Child Category",
  childCategoryList,
  childCategoryId,
  (id, name) {
    setState(() {
      childCategoryId = id;
      childCategoryName = name;
    });
  },
  Icons.category_outlined,
),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    cardContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Additional Info",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),

                          simpleDropdown("Gender",
                              ["Male", "Female", "Both"], gender,
                              (v) => setState(() => gender = v),
                              icon: Icons.person),

                          simpleDropdown("Payment",
                              ["Prepaid", "COD", "Both"], paymentMethod,
                              (v) => setState(() => paymentMethod = v),
                              icon: Icons.payment),

                          simpleDropdown("GST Type",
                              ["N/A", "Inc", "Exc"], gstType,
                              (v) => setState(() => gstType = v),
                              icon: Icons.receipt),

                         autoSymbolDropdown(icon: Icons.straighten),

                          textField(weightController, "Weight",
                            isNumber: true,
                              keyboardType: TextInputType.number,
                              
                              icon: Icons.scale),

                          textField(hsnController, "HSN Code",
                            isNumber: true, 
                              keyboardType: TextInputType.number,
                              icon: Icons.confirmation_num),
textField(
  countryController,
  "Country",
  icon: Icons.flag,
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
  ],
),

                          textField(descriptionController, "Description",
                              maxLines: 3, icon: Icons.description),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// ================= HELPERS =================
  Widget cardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5)
        ],
      ),
      child: child,
    );
  }

 // ONLY showing changed part (textField method updated)

Widget textField(
  TextEditingController controller,
  String hint, {
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  IconData? icon,
  bool isNumber = false,
  List<TextInputFormatter>? inputFormatters,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : keyboardType,
      maxLines: maxLines,

      validator: (v) {
        if (!isEdit && (v == null || v.trim().isEmpty)) {
          return "$hint required";
        }

        if (isNumber &&
            v != null &&
            v.trim().isNotEmpty &&
            int.tryParse(v) == null) {
          return "Enter valid number";
        }

        return null;
      },

      inputFormatters: inputFormatters ??
          (isNumber ? [FilteringTextInputFormatter.digitsOnly] : null),

      style: const TextStyle(fontSize: 14),

      decoration: InputDecoration(
        hintText: hint,

        prefixIcon: icon != null
            ? Icon(icon, color: const Color.fromARGB(255, 103, 103, 103))
            : null,

        filled: true,
        fillColor: Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 99, 99, 99),
            width: 1.5,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    ),
  );
} Widget simpleDropdown(
  String hint,
  List list,
  String? value,
  Function(String?) onChanged, {
  IconData? icon,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<String>(
      value: value,
      icon: const SizedBox(), // ❌ remove default arrow

      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,

        filled: true,
        fillColor: Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 99, 99, 99),
            width: 1.5,
          ),
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dropdownColor: Colors.white,

      items: list.map<DropdownMenuItem<String>>((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),

      onChanged: onChanged,
    ),
  );
}
  Widget autoSymbolDropdown({IconData? icon}) {
  final options = unitList.cast<Map<String, dynamic>>();

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    child: Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (text) {
        if (text.text.isEmpty) return options;
        return options.where((item) => item["name"]
            .toString()
            .toLowerCase()
            .contains(text.text.toLowerCase()));
      },

      displayStringForOption: (option) => option["name"].toString(),

      onSelected: (item) {
  setState(() => symbol = item["symbol"].toString()); // ✅ use symbol
},

      fieldViewBuilder: (context, controller, focusNode, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
       if (symbol != null && controller.text.isEmpty) {
  final selected = options.firstWhere(
    (e) => e["symbol"].toString() == symbol,
    orElse: () => {},
  );
  controller.text = selected["name"]?.toString() ?? "";
}
        });

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 14),

            decoration: InputDecoration(
              hintText: "Unit",

              prefixIcon: icon != null
                  ? Icon(icon, color: const Color.fromARGB(255, 103, 103, 103))
                  : null,

              filled: true,
              fillColor: Colors.white,

              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 99, 99, 99),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },

      optionsViewBuilder: (context, onSelectedItem, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 5,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 300,
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final item = options.elementAt(index);

                  return ListTile(
                    leading: const Icon(Icons.straighten,
                        size: 18, color: Color.fromARGB(255, 98, 99, 99)),
                    title: Text(item["name"]),
                    onTap: () => onSelectedItem(item),
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
  );
} 
Widget autoDropdown(
  String label,
  List list,
  String? value,
  Function(String? id, String? name) onSelected,
  IconData icon,
) {
  final options = list.cast<Map<String, dynamic>>();

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    child: Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (text) {
        if (text.text.isEmpty) return options;
        return options.where((item) =>
            item["name"]
                .toString()
                .toLowerCase()
                .contains(text.text.toLowerCase()));
      },

      displayStringForOption: (option) => option["name"].toString(),

      onSelected: (item) {
        onSelected(
          item["id"].toString(),
          item["name"].toString(),
        );
      },

      fieldViewBuilder: (context, controller, focusNode, _) {

        /// 🔥 IMPORTANT FIX (SET VALUE)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (value != null && controller.text.isEmpty) {
            final selected = options.firstWhere(
              (e) => e["id"].toString() == value.toString(),
              orElse: () => {},
            );

            if (selected.isNotEmpty) {
              controller.text = selected["name"].toString();
            }
          }
        });

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 6)
            ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: label,
              prefixIcon: Icon(icon,
                  color: const Color.fromARGB(255, 103, 103, 103)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 99, 99, 99),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },

      optionsViewBuilder: (context, onSelectedItem, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 5,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 300,
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final item = options.elementAt(index);

                  return ListTile(
                    leading: const Icon(Icons.label,
                        size: 18,
                        color: Color.fromARGB(255, 98, 99, 99)),
                    title: Text(item["name"]),
                    onTap: () => onSelectedItem(item),
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
  );
} /// ✅ DISPOSE FIX
  @override
  void dispose() {
    productName.dispose();
    subtitleController.dispose();
    weightController.dispose();
    hsnController.dispose();
    countryController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}