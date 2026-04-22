import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:ecolods/screen/orders_screen.dart';
import 'package:ecolods/screen/product_screen.dart';
import 'package:ecolods/screen/view_catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ecolods/api/api_service.dart';
import 'package:ecolods/screen/notification_screen.dart';
import 'package:ecolods/screen/appbarscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> {
  int _oldValue = 0;

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(
        begin: _oldValue,
        end: widget.value,
      ),
      duration: widget.duration,
      builder: (context, val, child) {
        return Text(
          val.toString(),
          style: widget.style,
        );
      },
    );
  }
}
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
  void showNotificationPopup(int count) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("🔔 You have $count new notifications"),
      backgroundColor: Colors.black,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: "View",
        textColor: Colors.yellow,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationScreen(
                companyName: widget.companyName,
              ),
            ),
          );
        },
      ),
    ),
  );
}
  int notificationCount = 0;
int receivedCount = 0;
int failedCount = 0;
int abandonedCartCount = 0;
  Map<String, dynamic> dashboardData = {};
  Map<String, dynamic> stockData = {}; // ✅ FIXED
DateTime? fromDate;
DateTime? toDate;
  bool isLoading = true;
  Timer? _autoRefreshTimer;
  List<Map<String, dynamic>> cartItems = [];
List<Map<String, dynamic>> wishlistItems = [];
bool isCartLoading = false;
bool isWishlistLoading = false;

bool isFetchingOrders = false;
String formatDate(DateTime date) {
  return "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
}


 @override
void initState() {
  super.initState();

  loadProfileImage(); 
  fetchDashboardData(showLoader: true);
  fetchNotificationCount();
  fetchStockData();
  fetchCartItems();
  fetchWishlistItems();
  

  fetchOrderCounts(
    fromDate: fromDate != null ? formatDate(fromDate!) : null,
    toDate: toDate != null ? formatDate(toDate!) : null,
  );

  _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    fetchDashboardData();
    fetchNotificationCount();
    fetchStockData();
    fetchCartItems();
    fetchWishlistItems();

    fetchOrderCounts(
      fromDate: fromDate != null ? formatDate(fromDate!) : null,
      toDate: toDate != null ? formatDate(toDate!) : null,
    );
  });
}
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

void resetDateFilter() {
  setState(() {
    fromDate = null;
    toDate = null;
  });

  // reload all data without filter
  fetchOrderCounts();
  fetchCartItems();
  fetchWishlistItems();
}
File? profileImage;
  /// ================= DASHBOARD =================

Future<void> loadProfileImage() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? path = prefs.getString("profile_image");

  if (path != null && path.isNotEmpty && File(path).existsSync()) {
    setState(() {
      profileImage = File(path);
    });
  }
}

 Future<void> fetchDashboardData({bool showLoader = false}) async {
  if (showLoader) {
    setState(() => isLoading = true);
  }

  try {
    final url =
        "${ApiService.baseUrl}dashboard.php?vendor_id=${widget.vendorId}";

    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15)); // ⏱️ timeout add

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // ✅ API status check
      if (data["status"] == true) {
        // ✅ avoid unnecessary rebuild
        if (jsonEncode(dashboardData) != jsonEncode(data)) {
          setState(() {
            dashboardData = data;
          });
        }
      } else {
        print("API Error: ${data["message"]}");
      }
    } else {
      print("HTTP Error: ${response.statusCode}");
    }
  } catch (e) {
    print("Dashboard Error: $e");
  } finally {
    // ✅ always stop loader
    if (showLoader) {
      setState(() => isLoading = false);
    }
  }
}

Future<void> pickFromDate() async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: fromDate ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
  );

  if (picked != null && picked != fromDate) {
    setState(() {
      fromDate = picked;
    });

    fetchOrderCounts(
      fromDate: formatDate(fromDate!),
      toDate: toDate != null ? formatDate(toDate!) : null,
    );
  }
}

Future<void> pickToDate() async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: toDate ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
  );

  if (picked != null && picked != toDate) {
    setState(() {
      toDate = picked;
    });

    fetchOrderCounts(
      fromDate: fromDate != null ? formatDate(fromDate!) : null,
      toDate: formatDate(toDate!),
    );
  }
}

Future<void> fetchOrderCounts({String? fromDate, String? toDate}) async {
  if (isFetchingOrders) return; // 🚫 prevent duplicate

  isFetchingOrders = true;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String companyId = prefs.get("company_id")?.toString() ?? "";

  if (companyId.isEmpty) {
    isFetchingOrders = false;
    return;
  }

  String baseUrl =
      "${ApiService.baseUrl}orders.php?action=order_details_list&company_id=$companyId";

  if (fromDate != null) {
    baseUrl += "&from_date=$fromDate";
  }
  if (toDate != null) {
    baseUrl += "&to_date=$toDate";
  }

  try {
    final responses = await Future.wait([
      http.get(Uri.parse("$baseUrl&type=received")),
      http.get(Uri.parse("$baseUrl&type=failed")),
    ]);

    final res1 = responses[0];
    if (res1.statusCode == 200) {
      final data = json.decode(res1.body);
      if (data['status'] == 'success') {
        receivedCount = data['count'] ?? 0;
      }
    }

    final res2 = responses[1];
    if (res2.statusCode == 200) {
      final data = json.decode(res2.body);
      if (data['status'] == 'success') {
        failedCount = data['count'] ?? 0;
      }
    }

    if (!mounted) return;
    setState(() {});
  } catch (e) {
    print("Error fetching counts: $e");
  } finally {
    isFetchingOrders = false; // ✅ reset
  }
}
Future<void> fetchStockData() async {
  try {
    final url =
        "${ApiService.baseUrl}Inventory.php?vendor_id=${widget.vendorId}";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          stockData = {
            "total_products": data['total_products'] ?? 0,
            "total_stock": data['total_products'] ?? 0,
            "out_of_stock": data['out_of_stock'] ?? 0,
            "low_stock": data['low_stock'] ?? 0,
          };
        });
      } else {
        print("Stock API Error: ${data['message']}");
      }
    } else {
      print("HTTP Error: ${response.statusCode}");
    }
  } catch (e) {
    print("Stock Error: $e");
  }
}  /// ================= NOTIFICATION =================
Future<void> fetchNotificationCount() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    int lastSeen = prefs.getInt("notification_last_seen") ?? 0;

    final url =
        "${ApiService.baseUrl}notification.php?action=notification_count"
        "&company_name=${Uri.encodeComponent(widget.companyName)}"
        "&last_seen=$lastSeen";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'success') {
      int newCount = int.tryParse(data['count'].toString()) ?? 0;

      // ✅ SHOW POPUP ONLY IF NEW NOTIFICATION ARRIVES
      if (newCount > notificationCount && newCount > 0) {
        showNotificationPopup(newCount);
      }

      setState(() {
        notificationCount = newCount;
      });
    }
  } catch (e) {
    print("Notification Error: $e");
  }
}

 Future<void> fetchCartItems() async {
  if (widget.vendorId == 0) return;

SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // 🔹 Get company_id as dynamic, then convert to string
    dynamic companyIdValue = prefs.get("company_id");
    String companyId = companyIdValue.toString(); 
  setState(() => isCartLoading = true);

  try {
    String url =
        "${ApiService.baseUrl}orders.php?action=seller_cart_active&company_id=$companyId";
    // Add from/to date if selected
    if (fromDate != null) {
      url += "&from_date=${fromDate!.year}-${fromDate!.month.toString().padLeft(2,'0')}-${fromDate!.day.toString().padLeft(2,'0')}";
    }
    if (toDate != null) {
      url += "&to_date=${toDate!.year}-${toDate!.month.toString().padLeft(2,'0')}-${toDate!.day.toString().padLeft(2,'0')}";
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          cartItems = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    }
  } catch (e) {
    print("Cart Error: $e");
  } finally {
    setState(() => isCartLoading = false);
  }
}
Future<void> fetchWishlistItems() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // 🔹 Get company_id as dynamic, then convert to string
    dynamic companyIdValue = prefs.get("company_id");
    String companyId = companyIdValue.toString(); 

  setState(() => isWishlistLoading = true);

  try {
    String url =
        "${ApiService.baseUrl}orders.php?action=seller_wishlist&company_id=$companyId";

    if (fromDate != null) {
      url += "&from_date=${fromDate!.year}-${fromDate!.month.toString().padLeft(2,'0')}-${fromDate!.day.toString().padLeft(2,'0')}";
    }
    if (toDate != null) {
      url += "&to_date=${toDate!.year}-${toDate!.month.toString().padLeft(2,'0')}-${toDate!.day.toString().padLeft(2,'0')}";
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          wishlistItems = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    }
  } catch (e) {
    print("Wishlist Error: $e");
  } finally {
    setState(() => isWishlistLoading = false);
  }
}
  

  /// ================= GREETING =================
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning!";
    if (hour >= 12 && hour < 17) return "Good Afternoon!";
    if (hour >= 17 && hour < 21) return "Good Evening!";
    return "Good Night!";
  }

  /// ================= PRODUCT CARD =================
  Widget productCard(Map product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),

        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: (product['image'] ?? "").isEmpty
              ? Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported),
                )
              : Image.network(
                  product['image'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image),
                ),
        ),

        title: Text(
          product['item_name'] ?? "",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),

        subtitle: Row(
          children: [
            const Icon(Icons.shopping_cart,
                size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              "${product['total_orders'] ?? 0} sold",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),

        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "#${index + 1}",
            style:
                const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  /// ================= TOP PRODUCTS =================
  Widget topProductWidget() {
    List topProducts = dashboardData['top_products'] ?? [];

    if (topProducts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No Data Available"),
      );
    }

    return Column(
      children: List.generate(topProducts.length, (index) {
        return productCard(topProducts[index], index);
      }),
    );
  }

  /// ================= BAR =================
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
          Text(value.toStringAsFixed(0),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// ================= STAT CARD =================
Widget _statCard(
  String label,
  int count,
  Color color, {
  VoidCallback? onTap,
}) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 90,
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

            /// 🔥 ANIMATED COUNT HERE
            FittedBox(
              child: AnimatedCounter(
                value: count,
                duration: const Duration(milliseconds: 600),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    ),
  );
}  /// ================= UI =================
 @override
Widget build(BuildContext context) {
  double approved = (dashboardData['approved_products'] ?? 0).toDouble();
  double pending = (dashboardData['pending_products'] ?? 0).toDouble();
  double rejected = (dashboardData['rejected_products'] ?? 0).toDouble();
  double totalProducts = (dashboardData['total_products'] ?? 0).toDouble();

  double total_products = (stockData['total_stock'] ?? 0).toDouble();
  double outStock = (stockData['out_of_stock'] ?? 0).toDouble();
  double lowStock = (stockData['low_stock'] ?? 0).toDouble();

  return Scaffold(
    appBar: const CustomAppBar(),
    backgroundColor: const Color(0xfff5f5f5),
    body: SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// HEADER
                  Row(
                    children: [
                    CircleAvatar(
  radius: 22,
  backgroundColor: const Color.fromARGB(255, 247, 247, 247),
  child: ClipOval(
    child: profileImage != null
        ? Image.file(
            profileImage!,
            width: 44,
            height: 44,
            fit: BoxFit.contain, // 🔥 IMPORTANT (cover)
          )
        : const Icon(Icons.person, color: Colors.grey),
  ),
),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getGreeting()),
                          Text(widget.companyName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),

                      /// NOTIFICATION
 Stack(
  children: [
    IconButton(
      icon: const Icon(Icons.notifications_none),
     onPressed: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => NotificationScreen(
        companyName: widget.companyName,
      ),
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(
    "notification_last_seen",
    DateTime.now().millisecondsSinceEpoch,
  );

  setState(() {
    notificationCount = 0;
  });

  fetchNotificationCount(); // refresh from API
},   ),

    if (notificationCount > 0)
      Positioned(
        right: 8,
        top: 8,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$notificationCount',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
      ),
  ],
)                   ]
                  ),     

                  const SizedBox(height: 20),

                  /// ================= ORDER DETAILS (MOVED TOP) =================
                  const Text("Order Details",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

             
             
                  const SizedBox(height: 10),

                  /// DATE FILTER
                  Row(
  children: [
    Expanded(
      child: GestureDetector(
        onTap: pickFromDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            fromDate == null
                ? "From Date"
                : "${fromDate!.day}-${fromDate!.month}-${fromDate!.year}",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),

    const SizedBox(width: 8),

    Expanded(
      child: GestureDetector(
        onTap: pickToDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            toDate == null
                ? "To Date"
                : "${toDate!.day}-${toDate!.month}-${toDate!.year}",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),

    const SizedBox(width: 8),

    GestureDetector(
      onTap: resetDateFilter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "Reset",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    ),
  ],
),
                  const SizedBox(height: 10),

                 Row(
  children: [
    Expanded(
      child: Row(
        children: [
         _statCard(
  "Received",
  receivedCount,
  Colors.green,
  onTap: () async {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const OrdersScreen(
        selectedType: "received",
        selectedTypeName: "Received Orders",
      ),
    ),
  );
},
),
          _statCard(
  "Abandoned Cart",
  cartItems.length,
  Colors.blue,
 onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const OrdersScreen(
        selectedType: "cart",
        selectedTypeName: "Cart Orders",
      ),
    ),
  );
},
),
          _statCard(
  "Wishlist",
  wishlistItems.length,
  Colors.orange,
 onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const OrdersScreen(
        selectedType: "wishlist",
        selectedTypeName: "Wishlist",
      ),
    ),
  );
},
),
 _statCard(
  "Failed",
  failedCount,
  Colors.red,
  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const OrdersScreen(
        selectedType: "failed",
        selectedTypeName: "Failed Orders",
      ),
    ),
  );
},
),
          
        ],
      ),
    ),

    const SizedBox(width: 10),
  ],
),

                  const SizedBox(height: 20),

                  /// PRODUCT DETAILS
                  const Text("Product Details",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                    _statCard(
  "Total",
  totalProducts.toInt(),
  Colors.blue,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
       builder: (_) => ViewCatalogScreen(
  company_id: widget.vendorId,
  vendorId: widget.vendorId,
  initialTab: 0, // 🔥 approved tab
),
      ),
    );
  },
),
                     _statCard(
  "Approved",
  approved.toInt(),
  Colors.green,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewCatalogScreen(
  company_id: widget.vendorId,
  vendorId: widget.vendorId,
  initialTab: 0, // 🔥 approved tab
),
      ),
    );
  },
),
                      _statCard(
  "Pending",
  pending.toInt(),
  Colors.orange,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
       builder: (_) => ViewCatalogScreen(
  company_id: widget.vendorId,
  vendorId: widget.vendorId,
  initialTab: 1, 
),
      ),
    );
  },
),
      _statCard(
  "Rejected",
  rejected.toInt(),
  Colors.red,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewCatalogScreen(
  company_id: widget.vendorId,
  vendorId: widget.vendorId,
  initialTab: 2, 
),
      ),
    );
  },
),
                    ],
                  ),

                  const SizedBox(height: 25),

                  /// STOCK DETAILS
                  const Text("Stock Details",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                     _statCard(
  "Total",
  total_products.toInt(),
  Colors.blue,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerProductScreen(
          initialFilter: "all",
        ),
      ),
    );
  },
),

_statCard(
  "Out Of Stock",
  outStock.toInt(),
  Colors.red,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerProductScreen(
          initialFilter: "out",
        ),
      ),
    );
  },
),
_statCard(
  "Low Stock",
  lowStock.toInt(),
  Colors.orange,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerProductScreen(
          initialFilter: "low",
        ),
      ),
    );
  },
),],
                  ),

                  const SizedBox(height: 20),

                  /// TOP PRODUCTS
                  const Text("Top Products",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

                  const SizedBox(height: 10),

                  topProductWidget(),
                ],
              ),
            ),
    ),
  );
}}