import 'dart:async';
import 'dart:convert';
import 'package:ecolods/api/api_service.dart';
import 'package:ecolods/screen/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {

  List orders = [];
  List filteredOrders = [];
  bool isLoading = true;

  String selectedStatus = "all";
  String searchQuery = "";

  final TextEditingController searchController = TextEditingController();
  Timer? _timer;

  /// API CALL
  Future<void> fetchOrders() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String companyName = prefs.getString("company_name") ?? "";

      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}orders.php?action=list&company_name=${Uri.encodeComponent(companyName)}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          orders = data["data"] ?? [];
        });

        applyFilters();
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  /// FILTER
  void applyFilters() {
    List temp = orders.where((order) {

      final matchesStatus =
          selectedStatus == "all" || order["approved"] == selectedStatus;

      final matchesSearch =
          searchQuery.isEmpty ||
          (order["product_name"] ?? "")
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          (order["customer_name"] ?? "")
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());

      return matchesStatus && matchesSearch;

    }).toList();

    setState(() {
      filteredOrders = temp;
      isLoading = false;
    });
  }

  /// FILTER CHIP
  Widget filterChip(String title, String value) {

    bool isActive = selectedStatus == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(title),
        selected: isActive,
        selectedColor: Colors.blue,
        backgroundColor: Colors.grey.shade200,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelStyle: TextStyle(
          color: isActive ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        onSelected: (_) {
          setState(() {
            selectedStatus = value;
          });
          applyFilters();
        },
      ),
    );
  }

  /// ORDER CARD
  Widget orderItem(Map order) {

    Color statusColor;

    switch (order["approved"]) {
      case "pending":
        statusColor = Colors.orange;
        break;
      case "confirmed":
        statusColor = Colors.green;
        break;
      case "shipped":
        statusColor = Colors.blue;
        break;
      case "rejected":
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return InkWell(

      borderRadius: BorderRadius.circular(16),

      onTap: () async {

        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OrderDetailsScreen(orderId: order["order_id"]),
          ),
        );

        if (updated != null) {
          setState(() {
            for (var o in orders) {
              if (o["order_id"] == updated["order_id"]) {
                o["approved"] = updated["status"];
              }
            }
          });

          applyFilters();
        }
      },

      child: Container(

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),

        child: Row(

          children: [

            /// ICON
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.inventory_2, color: statusColor),
            ),

            const SizedBox(width: 12),

            /// DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    order["product_name"] ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    order["customer_name"] ?? "",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        order["order_date"] ?? "",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// STATUS BADGE
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                (order["approved"] ?? "").toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    fetchOrders();

    searchController.addListener(() {
      searchQuery = searchController.text;
      applyFilters();
    });

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchOrders();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      /// 🔥 GRADIENT APPBAR
      appBar: AppBar(
         foregroundColor: Colors.white,
        title: const Text("Orders",style:TextStyle(color: Colors.white) ,),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [ Color(0xFF3B3F6B), // Dark Blue
              Color(0xFF3C67A0),],
            ),
          ),
        ),
      ),

      backgroundColor: const Color(0xfff4f6f9),

      body: SafeArea(

        child: Column(

          children: [

            /// 🔍 SEARCH
            Padding(
              padding: const EdgeInsets.fromLTRB(16,16,16,10),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(14),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search product or customer",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              searchController.clear();
                              searchQuery = "";
                              applyFilters();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            /// FILTER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    filterChip("All", "all"),
                    filterChip("Pending", "pending"),
                    filterChip("Confirmed", "confirmed"),
                    filterChip("Shipped", "shipped"),
                    filterChip("Rejected", "rejected"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// LIST
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory,
                                  size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                "No Orders Found",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: fetchOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: orderItem(filteredOrders[index]),
                              );
                            },
                          ),
                        ),
            ),

          ],
        ),
      ),
    );
  }
}