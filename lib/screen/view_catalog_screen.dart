import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecolods/api/api_service.dart';
import 'package:ecolods/screen/add_single_catalog_screen.dart';

class ViewCatalogScreen extends StatefulWidget {
  const ViewCatalogScreen({super.key});

  @override
  State<ViewCatalogScreen> createState() => _ViewCatalogScreenState();
}

class _ViewCatalogScreenState extends State<ViewCatalogScreen> {
  int selectedTab = 0;
  List catalogList = [];
  List filteredList = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  int vendorId = 0;
  String apiUrl = "${ApiService.baseUrl}product.php";

  String safe(dynamic value) => value?.toString() ?? "";

  @override
  void initState() {
    super.initState();
    loadVendorId();
  }

  Future<void> loadVendorId() async {
    final prefs = await SharedPreferences.getInstance();
    vendorId = prefs.getInt("vendor_id") ?? 0;

    if (vendorId != 0) fetchCatalog();
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

  Future fetchCatalog() async {
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
        }),
      );

      var data = jsonDecode(response.body);
      if (data["status"] == "success") {
        setState(() {
          catalogList = data["data"] ?? [];
          filteredList = List.from(catalogList);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  void searchProduct(String query) {
    final q = query.toLowerCase();
    setState(() {
      filteredList = catalogList.where((item) {
        return safe(item["item_name"]).toLowerCase().contains(q) ||
            safe(item["sku"]).toLowerCase().contains(q);
      }).toList();
    });
  }

  void showVariantsDialog(List variants) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Variants"),
        content: SizedBox(
          width: 300,
          height: 400,
          child: variants.isEmpty
              ? const Center(child: Text("No Variants"))
              : ListView.builder(
                  itemCount: variants.length,
                  itemBuilder: (_, i) {
                    var v = variants[i];
                    return Card(
                      child: ListTile(
                        title: Text("Color: ${safe(v["colour"])}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Size: ${safe(v["size"])}"),
                            Text("SKU: ${safe(v["sku_code"])}"),
                            Text("Price: ₹${safe(v["sale_price"])}"),
                            Text("Stock: ${safe(v["qty"])}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
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

  void addNewProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddSingleCatalogScreen()),
    ).then((refresh) {
      if (refresh == true) fetchCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catalog Management", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3B3F6B),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchCatalog),
          IconButton(icon: const Icon(Icons.add), onPressed: addNewProduct),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              onChanged: searchProduct,
              decoration: InputDecoration(
                hintText: "Search product...",
                prefixIcon: const Icon(Icons.search),
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
                              subtitle: Text("SKU: ${safe(item["sku"])}"),
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
    onPressed: () async {

      // 🔄 Loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 📦 Fetch variants
      final variants =
          await fetchVariantsOnly(safe(item["productid"]));

      Navigator.pop(context); // ❌ close loader

      // 🚀 Navigate to Edit Screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddSingleCatalogScreen(
            productData: item,   // ✅ product data pass
            variants: variants,  // ✅ variants pass
          ),
        ),
      );

      // 🔁 Refresh list after update
      if (result == true) {
        fetchCatalog();
      }
    },
  ),
                                  IconButton(
                                    icon:
                                        Icon(selectedTab == 3 ? Icons.restore : Icons.delete),
                                    onPressed: () {
                                      deleteProduct(safe(item["productid"]));
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
    return GestureDetector(
      onTap: () {
        setState(() => selectedTab = index);
        fetchCatalog();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selectedTab == index ? const Color(0xFF3B3F6B) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selectedTab == index ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}