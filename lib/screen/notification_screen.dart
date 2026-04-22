import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecolods/api/api_service.dart';

class NotificationScreen extends StatefulWidget {
  final String companyName;

  const NotificationScreen({super.key, required this.companyName});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
void initState() {
  super.initState();
  markAsSeen();
  loadNotifications();
}
Future<void> approveVendor(String vendorId) async {
  try {
    final response = await http.post(
      Uri.parse("${ApiService.baseUrl}notification.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "action": "approve_vendor",
        "vendor_id": vendorId,
      }),
    );

    final data = json.decode(response.body);

    print("Approve Response: $data");

    if (data['status'] == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),
      );

      // 🔄 Refresh notifications
      loadNotifications();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),
      );
    }
  } catch (e) {
    print("Error: $e");
  }
}
  /* ---------------- FETCH ---------------- */
  Future<void> loadNotifications() async {
    try {
      String url =
          "${ApiService.baseUrl}notification.php?action=notification_list"
          "&company_name=${Uri.encodeComponent(widget.companyName)}"
          "&t=${DateTime.now().millisecondsSinceEpoch}";

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == "success") {
        setState(() {
          notifications = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

Future<void> markAsSeen() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setInt(
    "notification_last_seen",
    DateTime.now().millisecondsSinceEpoch,
  );
}

  /* ---------------- UI (UNCHANGED DESIGN) ---------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        centerTitle: true,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B3F6B), Color(0xFF3C67A0)],
            ),
          ),
        ),
        title: const Text("Notification"),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text("No Notifications"))
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];

                    String type = item['type'] ?? "order";
                    String status =
                        (item['approved'] ?? "").toLowerCase();

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

                    String title;
                    String subtitle;

                    if (type == "vendor") {
                      title = "Account Approved 🎉";
                      subtitle = "Your account approved";
                    } else if (type == "product") {
                      title = item['product_name'] ?? "Product";
                      subtitle = "Status: ${item['approved'] ?? ''}";
                    } else {
                      title = item['product_name'] ?? "Order";
                      subtitle = "Customer: ${item['customer_name'] ?? ''}";
                    }

                    return Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: status == "approved"
                            ? Colors.green.shade50
                            : status == "rejected"
                                ? Colors.red.shade50
                                : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: statusColor,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                item['order_date'] ?? "",
                                style: const TextStyle(fontSize: 11),
                              )
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(subtitle),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(statusIcon,
                                  color: statusColor, size: 18),
                              const SizedBox(width: 5),
                              Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}