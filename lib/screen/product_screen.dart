import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecolods/api/api_service.dart';
import 'package:ecolods/screen/appbarscreen.dart';

class SellerProductScreen extends StatefulWidget {
  const SellerProductScreen({super.key});

  @override
  State<SellerProductScreen> createState() => _SellerProductScreenState();
}

class _SellerProductScreenState extends State<SellerProductScreen> {

  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = true;

  TextEditingController searchController = TextEditingController();
  final String apiUrl = "${ApiService.baseUrl}product.php";

  @override
  void initState() {
    super.initState();
    fetchProducts();
    searchController.addListener(onSearchChanged);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<int> getVendorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("vendor_id") ?? 0;
  }

  void onSearchChanged() {
    final query = searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => filteredProducts = List.from(allProducts));
      return;
    }

    setState(() {
      filteredProducts = allProducts.where((p) {
        final name = (p["item_name"] ?? "").toString().toLowerCase();
        final sku = (p["sku"] ?? "").toString().toLowerCase();
        final brand = (p["brand"] ?? "").toString().toLowerCase();
        return name.contains(query) ||
            sku.contains(query) ||
            brand.contains(query);
      }).toList();
    });
  }

  Future<void> fetchProducts() async {
    try {
      setState(() => isLoading = true);
      final vendorId = await getVendorId();
      if (vendorId == 0) return;

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "show",
          "vendor_id": vendorId,
          "status": "approved"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == "success") {
          allProducts =
              List<Map<String, dynamic>>.from(data["data"] ?? []);
          setState(() {
            filteredProducts = List.from(allProducts);
          });
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔥 MODERN PRODUCT CARD
  Widget productCard(Map<String, dynamic> p) {

    final price = "₹${p["sale_price"] ?? '0'}";
    final imageUrl = (p["image1"] ?? "").toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Row(
        children: [

          /// IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
            child: imageUrl.isEmpty
                ? Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 40),
                  )
                : Image.network(
                    imageUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 70),
                  ),
          ),

          /// DETAILS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    p["item_name"] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "SKU: ${p["sku"] ?? ""}",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.blue,
                        ),
                      ),

                      
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      /// 🔥 GRADIENT APPBAR
      appBar: const CustomAppBar(),

      backgroundColor: const Color(0xfff4f6f9),

      body: Column(
        children: [

          /// 🔥 SEARCH BOX
          Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(14),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search Product / SKU / Brand",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          /// 🔥 LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? const Center(child: Text("No products found"))
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return productCard(filteredProducts[index]);
                        },
                      ),
          ),
        ],
      ),

    
    );
  }
}