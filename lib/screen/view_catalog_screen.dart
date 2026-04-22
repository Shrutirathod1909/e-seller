import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecolods/api/api_service.dart';
import 'package:ecolods/screen/add_single_catalog_screen.dart';

class ViewCatalogScreen extends StatefulWidget {
  final int? vendorId;
  final int company_id;
  final int initialTab;
  final VoidCallback? onUpdate; // 🔹 callback to refresh dashboard

  const ViewCatalogScreen({super.key, this.vendorId, this.onUpdate,   this.initialTab = 0,required this.company_id});

  @override
  State<ViewCatalogScreen> createState() => _ViewCatalogScreenState();
}

class _ViewCatalogScreenState extends State<ViewCatalogScreen> {
  int selectedTab = 0;
  List catalogList = [];
  List filteredList = [];
  bool isLoading = true;
  List categoryList = [];
  TextEditingController searchController = TextEditingController();
  int vendorId = 0;
  String apiUrl = "${ApiService.baseUrl}product.php";

  int approvedCount = 0;
int pendingCount = 0;
int rejectedCount = 0;
int restoreCount = 0;

  String? selectedCategory; 

  String safe(dynamic value) => value?.toString() ?? "";

  @override
  void initState() {
    super.initState();
    
  selectedTab = widget.initialTab;
    loadVendorId();
    loadCategories();
    
  }

Future<void> loadCategories() async {
  try {
    final response = await http.get(
      Uri.parse("${ApiService.baseUrl}categories_api.php?action=primary"),
    );

    final data = jsonDecode(response.body);
    print("Category API Response: $data"); // 🔹 debug

    if (data["status"] == "success") {
      setState(() {
        categoryList = data["data"]; // 🔹 assign list
      });
    } else {
      print("No categories found");
    }
  } catch (e) {
    print("Category Error: $e");
  }
}


  Future<void> loadVendorId() async {
    final prefs = await SharedPreferences.getInstance();
    vendorId = prefs.getInt("vendor_id") ?? 0;

    if (vendorId != 0) {
  fetchCatalog();
  fetchCounts(); // ✅ ADD THIS
}
  }

  Future<List> fetchVariantsOnly(String productId) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "show_variants",
          "product_id": int.tryParse(productId) ?? 0,
        }),
      );
      final data = jsonDecode(response.body);
      if (data["status"] == "success") return data["data"] ?? [];
    } catch (e) {
      print("Variant Error: $e");
    }
    return [];
  }

Future<void> fetchCounts() async {
  try {
    final statuses = ["approved", "pending", "rejected", "restore"];

    for (var status in statuses) {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "show",
          "vendor_id": vendorId,
          "status": status,
        }),
      );

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {
        int count = (data["data"] ?? []).length;

        setState(() {
          if (status == "approved") approvedCount = count;
          if (status == "pending") pendingCount = count;
          if (status == "rejected") rejectedCount = count;
          if (status == "restore") restoreCount = count;
        });
      }
    }
  } catch (e) {
    print("Count Error: $e");
  }
}
Future fetchCatalog({int page = 1, int perPage = 50}) async {
  setState(() => isLoading = true);
  try {
    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "action": "show",
        "vendor_id": vendorId,
        "status": selectedTab == 0
            ? "approved"
            : selectedTab == 1
                ? "pending"
                : selectedTab == 2
                    ? "rejected"
                    : "restore",
        "page": page,
        "per_page": perPage,
      }),
    );

    var data = jsonDecode(response.body);
    var newItems = data["status"] == "success" ? data["data"] ?? [] : [];

    setState(() {
      if (page == 1) catalogList = newItems;
      else catalogList.addAll(newItems);
      applyCategoryFilter(selectedCategory);
    });
  } catch (e) {
    print("Fetch catalog error: $e");
    setState(() => filteredList = []);
  } finally {
    setState(() => isLoading = false);
  }
}

void searchProduct(String query) {
  final q = query.toLowerCase().trim();

  List tempList = catalogList.where((item) {
    final matchesCategory = selectedCategory == null ||
        safe(item["category"]).toLowerCase().trim() ==
            selectedCategory!.toLowerCase().trim();
    final matchesSearch = safe(item["item_name"]).toLowerCase().contains(q) ||
        safe(item["sku"]).toLowerCase().contains(q);

    return matchesCategory && (q.isEmpty || matchesSearch);
  }).toList();

  setState(() {
    filteredList = tempList;
  });

  print("Search Query: '$query', Filtered Count: ${filteredList.length}");
}

Widget buildVariantField(String label, dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return const SizedBox(); // ❌ don't show anything
  }
  return Text("$label: $value");
}
Widget buildRow(IconData icon, String label, dynamic value,
    {bool isPrice = false}) {
  if (value == null || value.toString().trim().isEmpty) {
    return const SizedBox();
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            isPrice ? "₹$value" : value.toString(),
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    ),
  );
}
 void showVariantsDialog(List variants) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 350,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Product Variants",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                )
              ],
            ),

            const Divider(),

            /// 🔥 BODY
            Expanded(
              child: variants.isEmpty
                  ? const Center(child: Text("No Variants Found"))
                  : ListView.builder(
                      itemCount: variants.length,
                      itemBuilder: (_, i) {
                        var v = variants[i];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              /// 🔹 TITLE
                              Text(
                                "Variant ${i + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 8),

                              /// 🔹 DATA ROWS
                              buildRow(Icons.color_lens, "Color", v["colour"]),
                              buildRow(Icons.straighten, "Size", v["size"]),
                              buildRow(Icons.qr_code, "SKU", v["sku_code"]),
                              buildRow(Icons.currency_rupee, "Price", v["cad_price"], isPrice: true),
                              buildRow(Icons.inventory, "Stock", v["qty"]),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}



  Future deleteProduct(String productid) async {
    await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "action": selectedTab == 3 ? "restore" : "delete",
        "vendor_id": vendorId,
        "productid": int.tryParse(productid) ?? 0,
      }),
    );
    fetchCatalog();
  }

void applyCategoryFilter(String? categoryName) {
  selectedCategory = categoryName;

  List tempList = catalogList.where((item) {
    final itemCategory = safe(item["primary_categories_name"]).toLowerCase().trim();
    final filterCategory = selectedCategory?.toLowerCase().trim() ?? "";
    return filterCategory.isEmpty || itemCategory == filterCategory;
  }).toList();

  setState(() {
    filteredList = tempList;
  });

  print("Selected Category: $selectedCategory, Filtered Count: ${filteredList.length}");
}

  void applyFilter(String type) {
  List tempList = List.from(catalogList); // ✅ use full list

  double getPrice(item) =>
      double.tryParse(item["cad_price"]?.toString() ?? "0") ?? 0;

  int getQty(item) =>
      int.tryParse(item["qty"]?.toString() ?? "0") ?? 0;

  if (type == "price_low") {
    tempList.sort((a, b) => getPrice(a).compareTo(getPrice(b)));
  } else if (type == "price_high") {
    tempList.sort((a, b) => getPrice(b).compareTo(getPrice(a)));
  } else if (type == "stock_low") {
    tempList.sort((a, b) => getQty(a).compareTo(getQty(b)));
  } else if (type == "name") {
    tempList.sort(
        (a, b) => safe(a["item_name"]).compareTo(safe(b["item_name"])));
  }

  setState(() {
    filteredList = tempList;
  });
}
void openFilterDialog() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Filter Products"),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [

            /// 🔹 RESET
           ListTile(
  title: const Text("All"),
  onTap: () {
    Navigator.pop(context);
    setState(() {
      selectedCategory = null; // reset category
      filteredList = List.from(catalogList); // show all
    });
  },
),

            const Divider(),

            /// 🔹 CATEGORY LIST
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Text(
                "Filter by Category",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

       ...categoryList.map((cat) {
  return ListTile(
    title: Text(cat["name"]),
    onTap: () {
      Navigator.pop(context); // close dialog
      applyCategoryFilter(cat["name"]); // filter list
    },
  );
}).toList(),
            const Divider(),

            /// 🔹 PRICE / SORT FILTER
            ListTile(
              title: const Text("Price Low → High"),
              onTap: () {
                Navigator.pop(context);
                applyFilter("price_low");
              },
            ),
            ListTile(
              title: const Text("Price High → Low"),
              onTap: () {
                Navigator.pop(context);
                applyFilter("price_high");
              },
            ),
            ListTile(
              title: const Text("Stock Low → High"),
              onTap: () {
                Navigator.pop(context);
                applyFilter("stock_low");
              },
            ),
            ListTile(
              title: const Text("Name A → Z"),
              onTap: () {
                Navigator.pop(context);
                applyFilter("name");
              },
            ),
          ],
        ),
      ),
    ),
  );
}
 void addNewProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddSingleCatalogScreen(vendorId: vendorId,company_id: widget.company_id,)),
    ).then((refresh) {
      if (refresh == true) fetchCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text("Catalog Management", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3B3F6B),
      actions: [
  IconButton(
  icon: const Icon(Icons.refresh),
  onPressed: () {
    fetchCatalog();
    fetchCounts(); // ✅ ADD THIS
  },
),
  IconButton(icon: const Icon(Icons.filter_list), onPressed: openFilterDialog), // ✅ NEW
  IconButton(icon: const Icon(Icons.add), onPressed: addNewProduct),
],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child:TextField(
  controller: searchController,
  onChanged: searchProduct,
  decoration: InputDecoration(
    hintText: "Search product...",
    prefixIcon: const Icon(Icons.search),
    suffixIcon:IconButton(
  icon: const Icon(Icons.close),
  onPressed: () {
    searchController.clear();
    setState(() {
      filteredList = selectedCategory != null
          ? catalogList.where((item) {
              return safe(item["category"]).toLowerCase() ==
                  selectedCategory!.toLowerCase();
            }).toList()
          : List.from(catalogList);
    });
  },
),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  ),
),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                statusTab("Approved", 0),
                statusTab("Pending", 1),
                statusTab("Rejected", 2),
                statusTab("Restore", 3),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? const Center(child: Text("No Products Found"))
                    : ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (_, i) {
                          var item = filteredList[i];
                          List<String> images = [];
                          if (item["image1"] != null && item["image1"].isNotEmpty) {
                            images.add(item["image1"]);
                          }
                          // You can add image2, image3 if your API provides them

                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              leading: SizedBox(
                                width: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: images.length,
                                  itemBuilder: (_, idx) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: Image.network(
                                        images[idx],
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(
                                              child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2)));
                                        },
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.broken_image, size: 70),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              title: Text(safe(item["item_name"])),
subtitle: Text(
  "ProductID: ${safe(item["productid"])}\n"
  "Category: ${safe(item["primary_categories_name"])}\n"
  "SKU: ${safe(item["sku"])}",
),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    onPressed: () async {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) =>
                                            const Center(child: CircularProgressIndicator()),
                                      );
                                      final variants =
                                          await fetchVariantsOnly(safe(item["productid"]));
                                      Navigator.pop(context);
                                      showVariantsDialog(variants);
                                    },
                                  ),
                              if (selectedTab == 1)
IconButton(
  icon: const Icon(Icons.edit),
  onPressed: () {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Product"),
        content: const Text("Do you want to edit this product?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 🔄 Loader
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              // 📦 Fetch variants
              final variants = await fetchVariantsOnly(safe(item["productid"]));
              Navigator.pop(context); // ❌ close loader

              // 🚀 Navigate to Edit Screen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddSingleCatalogScreen(
                    vendorId: vendorId,
                    productData: item,
                    variants: variants,
                    company_id: widget.company_id,
                  ),
                ),
              );

              // 🔁 Refresh list after update
              if (result == true) fetchCatalog();
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  },
),                           
                                    IconButton(
  icon: Icon(selectedTab == 3 ? Icons.restore : Icons.delete),
  onPressed: () {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(selectedTab == 3 ? "Restore Product" : "Delete Product"),
        content: Text(
          selectedTab == 3
              ? "Are you sure you want to restore this product?"
              : "Are you sure you want to delete this product?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteProduct(safe(item["productid"]));
            },
            child: const Text(
              "Yes",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  },
),
                                  
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

 Widget statusTab(String title, int index) {
  int count = 0;

  if (index == 0) count = approvedCount;
  if (index == 1) count = pendingCount;
  if (index == 2) count = rejectedCount;
  if (index == 3) count = restoreCount;

  return GestureDetector(
    onTap: () async { // ✅ mark function as async
  setState(() => selectedTab = index);

  await fetchCatalog(); // ✅ now you can await

  if (selectedCategory != null && selectedCategory!.isNotEmpty) {
    applyCategoryFilter(selectedCategory!);
  }
},
    child: Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selectedTab == index
            ? const Color(0xFF3B3F6B)
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "$title ($count)", // ✅ ONLY CHANGE
        style: TextStyle(
          color: selectedTab == index ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
}