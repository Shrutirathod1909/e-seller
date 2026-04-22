import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecolods/api/api_service.dart';
import 'package:ecolods/screen/appbarscreen.dart';

class SellerProductScreen extends StatefulWidget {
  final String initialFilter;

  const SellerProductScreen({
    super.key,
    this.initialFilter = "all",
  });

  @override
  State<SellerProductScreen> createState() =>
      _SellerProductScreenState();
}

class _SellerProductScreenState extends State<SellerProductScreen> {
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  Map<String, dynamic> stockData = {};

  bool isLoading = true;

  String selectedFilter = "all";
  String searchQuery = "";

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
    fetchProducts();
  }

  Future<int> getVendorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("vendor_id") ?? 0;
  }

  Future<void> fetchProducts() async {
    final vendorId = await getVendorId();

    final invRes = await http.get(
      Uri.parse("${ApiService.baseUrl}Inventory.php?vendor_id=$vendorId"),
    );

    final invData = json.decode(invRes.body);

    if (invData["status"] == "success") {
      stockData = invData;

      List invList = invData['data'] ?? [];

      allProducts = invList.map<Map<String, dynamic>>((inv) {
        return inv;
      }).toList();

      applyFilter();
    }

    setState(() => isLoading = false);
  }

 void applyFilter() {
  List<Map<String, dynamic>> temp =
      List<Map<String, dynamic>>.from(allProducts);

  // STOCK FILTER
  if (selectedFilter == "out") {
    temp = temp.where((p) {
      int stock = int.tryParse(p["stock_count"].toString()) ?? 0;
      return stock == 0;
    }).toList();
  } else if (selectedFilter == "low") {
    temp = temp.where((p) {
      int stock = int.tryParse(p["stock_count"].toString()) ?? 0;
      return stock > 0 && stock <= 5;
    }).toList();
  }

  // SEARCH FILTER
  final query = searchQuery.trim().toLowerCase();

  if (query.isNotEmpty) {
    temp = temp.where((p) {
      final name = (p["item_name"] ?? "").toString().toLowerCase();
      final sku = (p["skucode"] ?? "").toString().toLowerCase();

      return name.contains(query) || sku.contains(query);
    }).toList();
  }

  setState(() {
    filteredProducts = temp;
  });
}
 Widget searchBar() {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: TextField(
      controller: searchController,
      onChanged: (val) {
        searchQuery = val;
        applyFilter();
      },
      decoration: InputDecoration(
        hintText: "Search products...",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
               onPressed: () {
              searchController.clear();
              searchQuery = "";
              applyFilter();
            },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}
  Widget statCard(String title, int value, Color color, String filter) {
    bool active = selectedFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedFilter = filter);
          applyFilter();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                "$value",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: active ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget productCard(Map<String, dynamic> p) {
  final name = p["item_name"] ?? "";
  final imageUrl = (p["image"] ?? "").toString();
  final skucode = p["skucode"] ?? "";

  int stock = int.tryParse(p["stock_count"].toString()) ?? 0;
  final productId = int.parse(p["productid"].toString());

  Color stockColor =
      stock == 0 ? Colors.red : (stock <= 5 ? Colors.orange : Colors.green);

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ✅ IMAGE SECTION (FIXED HEIGHT)
        Stack(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 110, // 🔥 FIXED HEIGHT (IMPORTANT)
                width: double.infinity,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image),
                      ),
              ),
            ),

            /// ✏️ EDIT BUTTON
            Positioned(
              right: 8,
              top: 8,
              child: InkWell(
                onTap: () =>
                    showStockPopup(productId, stock, skucode),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 16),
                ),
              ),
            ),

            /// 📦 STOCK BADGE
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stockColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  stock == 0
                      ? "Out"
                      : stock <= 5
                          ? "Low"
                          : "In Stock",
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),

        /// ✅ TEXT SECTION (EXPANDED FIX)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔥 FIX: Prevent overflow
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                Text(
                  "Stock: $stock",
                  style: TextStyle(
                    color: stockColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
void showStockPopup(
    int productId, int currentStock, String skucode) {
  TextEditingController qtyController =
      TextEditingController(text: "1");

  String action = "increase";

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    Text(
                      "Current Stock: $currentStock",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: action == "increase"
                                  ? Colors.green
                                  : Colors.grey[300],
                            ),
                            onPressed: () =>
                                setModalState(() => action = "increase"),
                            child: Text(
                              "ADD",
                              style: TextStyle(
                                color: action == "increase"
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: action == "decrease"
                                  ? Colors.red
                                  : Colors.grey[300],
                            ),
                            onPressed: () =>
                                setModalState(() => action = "decrease"),
                            child: Text(
                              "SUBTRACT",
                              style: TextStyle(
                                color: action == "decrease"
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Quantity",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          int qty = int.tryParse(qtyController.text) ?? 1;
                          Navigator.pop(context);

                          updateStock(
                            productId,
                            skucode,
                            action,
                            currentStock,
                            qty,
                          );
                        },
                        child: const Text("UPDATE"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
  Future<void> updateStock(
    int productId,
    String skucode,
    String action,
    int currentStock,
    int qty,
  ) async {
    int newStock = currentStock;

    if (action == "increase") {
      newStock += qty;
    } else {
      newStock -= qty;
      if (newStock < 0) newStock = 0;
    }

    setState(() {
      for (var p in allProducts) {
        if (p["productid"].toString() == productId.toString()) {
          p["stock_count"] = newStock;
        }
      }
      applyFilter();
    });

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}Inventory.php"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "action": action,
          "skucode": skucode,
          "qty": qty,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["status"] != "success") {
        throw Exception(data["message"]);
      }
    } catch (e) {
      setState(() {
        for (var p in allProducts) {
          if (p["productid"].toString() ==
              productId.toString()) {
            p["stock_count"] = currentStock;
          }
        }
        applyFilter();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: const Color(0xfff4f6f9),
      body: SafeArea(
        child: Column(
          children: [
            searchBar(),

            Row(
              children: [
                statCard("Total", allProducts.length, Colors.blue, "all"),
                statCard("Out",
                    stockData['out_of_stock'] ?? 0, Colors.red, "out"),
                statCard("Low",
                    stockData['low_stock'] ?? 0, Colors.orange, "low"),
              ],
            ),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredProducts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                          crossAxisSpacing: 10, // 👉 horizontal gap (between 2 cards)
  mainAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                      itemBuilder: (_, i) =>
                          productCard(filteredProducts[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}