import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ecolods/api/api_service.dart';

class NotificationScreen extends StatefulWidget {
  final String companyName;

  const NotificationScreen({super.key, required this.companyName});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {

  late Future<List<dynamic>> notificationFuture;

  @override
  void initState() {
    super.initState();
    notificationFuture = fetchNotifications();
  }

  Future<List<dynamic>> fetchNotifications() async {

    String url =
        "${ApiService.baseUrl}notification.php?action=notification_list&company_name=${Uri.encodeComponent(widget.companyName)}";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {

      final data = json.decode(response.body);

      if (data['status'] == "success") {
        return data['data'] ?? [];
      } else {
        return [];
      }

    } else {
      throw Exception("Failed to load notifications");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

appBar: AppBar(
  foregroundColor: Colors.white,
  title: const Text(
    "Notifications",
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),
  flexibleSpace: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF3B3F6B), // Dark Blue
          Color(0xFF3C67A0), // Light Blue
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),
),

      body: FutureBuilder<List<dynamic>>(

        future: notificationFuture,

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text("Error: ${snapshot.error}")
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Text("No Notifications"),
            );
          }

          return ListView.builder(

            itemCount: notifications.length,
itemBuilder: (context, index) {
  final item = notifications[index];

  String status = (item['approved'] ?? "").toString().toLowerCase();

  Color statusColor;
  IconData statusIcon;

  if (status == "approved") {
    statusColor = Colors.green;
    statusIcon = Icons.check_circle;
  } else if (status == "rejected") {
    statusColor = Colors.red;
    statusIcon = Icons.cancel;
  } else {
    statusColor = Colors.orange;
    statusIcon = Icons.access_time;
  }

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade300,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// 🔹 TOP ROW (Title + Date)
        Row(
          children: [

            /// PRODUCT NAME
            Expanded(
              child: Text(
                item['product_name'] ?? "Product",
                maxLines: 2, // ✅ ONE LINE
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            /// DATE (TOP RIGHT)
            Text(
              item['order_date'] ?? "",
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        /// 🔹 ORDER ID (ONE LINE)
        Text(
          "Order ID: ${item['order_id'] ?? ''}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),

        const SizedBox(height: 4),

        /// 🔹 CUSTOMER
        Text(
          "Customer: ${item['customer_name'] ?? ''}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),

        const SizedBox(height: 8),

        /// 🔹 BOTTOM ROW (STATUS)
        Row(
          children: [

            Icon(statusIcon, color: statusColor, size: 18),

            const SizedBox(width: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}        );
        },
      ),
    );
  }
}