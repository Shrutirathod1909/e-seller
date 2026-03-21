import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ecolods/api/api_service.dart';
import 'package:ecolods/screen/notification_screen.dart';
import 'package:ecolods/screen/appbarscreen.dart';

class DashboardScreen extends StatefulWidget {
  final String companyName;
  final int vendorId;

  const DashboardScreen({
    super.key,
    required this.companyName,
    required this.vendorId,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int notificationCount = 0;
  late Future<Map<String, dynamic>> dashboardFuture;

  @override
  void initState() {
    super.initState();
    dashboardFuture = fetchDashboard();
    fetchNotificationCount();
  }

  /// Notification Count
  Future<void> fetchNotificationCount() async {
    try {
      String url =
          "${ApiService.baseUrl}notification.php?action=notification_count&company_name=${Uri.encodeComponent(widget.companyName)}";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            notificationCount = data['count'] ?? 0;
          });
        }
      }
    } catch (e) {
      print("Notification Error : $e");
    }
  }

  /// Dashboard API
  Future<Map<String, dynamic>> fetchDashboard() async {
    final url =
        "${ApiService.baseUrl}dashboard.php?vendor_id=${widget.vendorId}&company_name=${Uri.encodeComponent(widget.companyName)}";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Dashboard API Response: $data"); // Debugging
      return data;
    } else {
      throw Exception("Dashboard Load Failed");
    }
  }

  /// Greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning!";
    if (hour >= 12 && hour < 17) return "Good Afternoon!";
    if (hour >= 17 && hour < 21) return "Good Evening!";
    return "Good Night!";
  }

  /// Product Item
  Widget productItem(String name, int sold) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
      title: Text(
        name.isEmpty ? "No Product" : name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Text(
        sold.toString(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  /// Horizontal bar
  Widget buildHorizontalBar(
      String label, double value, double maxValue, Color color) {
    double percent = maxValue == 0 ? 0 : value / maxValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 14,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value.toStringAsFixed(0),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Stats Card
 Widget _statCard(String label, int count, Color color) {
  return Expanded(
    child: Container(
      height: 90, // ✅ FIXED HEIGHT (all same)
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// COUNT
          FittedBox( // ✅ auto resize text
            child: Text(
              count.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),

          const SizedBox(height: 6),

          /// LABEL
          Text(
            label,
            maxLines: 1, // ✅ ONE LINE
            overflow: TextOverflow.ellipsis, // ✅ ...
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: const Color(0xfff5f5f5),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text("No Data"));
            }

            final data = snapshot.data!;
            double approved = (data['approved_products'] ?? 0).toDouble();
            double pending = (data['pending_products'] ?? 0).toDouble();
            double rejected = (data['rejected_products'] ?? 0).toDouble();
            double totalProducts = (data['total_products'] ?? 0).toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header
                  Row(
                    children: [
                      const CircleAvatar(radius: 22),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getGreeting()),
                          Text(
                            data['company_name'] ?? widget.companyName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NotificationScreen(
                                      companyName: widget.companyName),
                                ),
                              ).then((_) => fetchNotificationCount());
                            },
                          ),
                          if (notificationCount > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  notificationCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  /// Stats Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statCard("Total Products", totalProducts.toInt(), Colors.blue),
                      _statCard("Approved", approved.toInt(), Colors.green),
                      _statCard("Pending", pending.toInt(), Colors.orange),
                      _statCard("Rejected", rejected.toInt(), Colors.red),
                    ],
                  ),
                  const SizedBox(height: 25),

                  /// Product Status Bars
                  buildHorizontalBar("Approved", approved, totalProducts, Colors.green),
                  buildHorizontalBar("Pending", pending, totalProducts, Colors.orange),
                  buildHorizontalBar("Rejected", rejected, totalProducts, Colors.red),
                  const SizedBox(height: 25),

                  /// Top Product
                  const Text(
                    "Top Selling Product",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: productItem(
                      data['top_product_name'] ?? "",
                      data['top_product_qty'] ?? 0,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}