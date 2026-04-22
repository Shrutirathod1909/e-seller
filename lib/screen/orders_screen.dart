import 'dart:async';
import 'dart:convert';
import 'package:ecolods/api/api_service.dart';
import 'package:ecolods/screen/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrdersScreen extends StatefulWidget {
 final String? selectedType;        // 👈 ADD
  final String? selectedTypeName;    // 👈 ADD

  const OrdersScreen({
    super.key,
    this.selectedType,
    this.selectedTypeName,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List get filteredCurrentList {
  if (searchQuery.isEmpty) return currentList;

  return currentList.where((item) {
    final name =
        (item["item_name"] ?? "").toString().toLowerCase();

    final customer =
        (item["customer_name"] ?? "").toString().toLowerCase();

    return name.contains(searchQuery.toLowerCase()) ||
        customer.contains(searchQuery.toLowerCase());
  }).toList();
}
Color getStatusColor(String? status) {
  final s = status?.toLowerCase().trim();

  switch (s) {
    case "pending":
      return Colors.orange;

    case "confirmed":
      return Colors.green;

    case "shipped":
      return Colors.blue;

    case "rejected":
      return Colors.red;

    case "failed":
    case "cancelled":
      return Colors.redAccent;

    case "order received":
    case "order placed":
      return Colors.teal;

    case "added in cart":
      return Colors.deepPurple;

    case "deleted":
      return Colors.brown;

    case "created":
      return Colors.pink;

    default:
      return Colors.grey;
  }
}
void openSearchableDropdown() {

  TextEditingController searchCtrl = TextEditingController();

  List<Map<String, String>> filteredList =
      List.from(dropdownItems);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(20)),
    ),

    builder: (context) {

      return StatefulBuilder(
        builder: (context, setModalState) {

          return Padding(
            padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).viewInsets.bottom),

            child: Container(
              height: 420,
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [

                  /// 🔍 SEARCH FIELD
                  TextField(
                    controller: searchCtrl,

                    decoration: InputDecoration(
                      hintText: "Search order type...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),

                    onChanged: (value) {
                      setModalState(() {
                        filteredList = dropdownItems
                            .where((item) => item["label"]!
                                .toLowerCase()
                                .contains(
                                    value.toLowerCase()))
                            .toList();
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  /// 📋 LIST
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredList.length,

                      itemBuilder: (context, index) {
                        final item = filteredList[index];

                        return ListTile(
                          title: Text(item["label"]!),

                          tileColor:
                              selectedType == item["value"]
                                  ? Colors.blue.shade50
                                  : null,

                          trailing:
                              selectedType == item["value"]
                                  ? const Icon(Icons.check,
                                      color: Colors.green)
                                  : null,

                          onTap: () {

                            setState(() {
                              selectedType =
                                  item["value"];
                              isLoading = true;
                            });

                            fetchSellerInteractions(
                                item["value"]!);

                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
List<Map<String, String>> dropdownItems = [
  {"label": "Received", "value": "received"},
  {"label": "Failed", "value": "failed"},
  {"label": "Add to Cart", "value": "cart"},           // ✅ FIX
  {"label": "Abandoned Cart", "value": "abandoned"}, 
  {"label": "Wishlist", "value": "wishlist"},
];
List receivedItems = [];
List failedItems = [];
List cartItems = [];
List abandonedItems = [];
List wishlistItems = [];
  List orders = [];
  List filteredOrders = [];
  bool isLoading = true;
String? selectedType = "received";
  String selectedStatus = "all";
  String searchQuery = "";

  final TextEditingController searchController = TextEditingController();
  Timer? _timer;


  Future<void> fetchSellerInteractions(String type,
    {String? fromDate, String? toDate}) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String companyId = prefs.get("company_id").toString();

    String action = "";
    String url = "";

    if (type == "cart") {
      action = "seller_cart_active";
      url =
          "${ApiService.baseUrl}orders.php?action=$action&company_id=$companyId";
    } 
    else if (type == "abandoned") {
      action = "seller_cart_abandoned";
      url =
          "${ApiService.baseUrl}orders.php?action=$action&company_id=$companyId";
    } 
    else if (type == "wishlist") {
      action = "seller_wishlist";
      url =
          "${ApiService.baseUrl}orders.php?action=$action&company_id=$companyId";
    } 
    else if (type == "received" || type == "failed") {
      // ✅ NEW API CALL
      url =
          "${ApiService.baseUrl}orders.php?action=order_details_list"
          "&company_id=$companyId&type=$type";

      if (fromDate != null && toDate != null) {
        url += "&from_date=$fromDate&to_date=$toDate";
      }
    }

    final response = await http.get(Uri.parse(url));


    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        if (type == "cart") {
          cartItems = data["data"] ?? [];
        } 
        else if (type == "abandoned") {
          abandonedItems = data["data"] ?? [];
        } 
        else if (type == "wishlist") {
          wishlistItems = data["data"] ?? [];
        } 
        else if (type == "received") {
          receivedItems = data["data"] ?? [];   // ✅ NEW
        } 
        else if (type == "failed") {
          failedItems = data["data"] ?? [];     // ✅ NEW
        }

        isLoading = false;
      });

      applyFilters();
    }
  } catch (e) {
    debugPrint("Error fetching $type: $e");
    setState(() => isLoading = false);
  }
}
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

  // 🔍 SEARCH LISTENER
  searchController.addListener(() {
    searchQuery = searchController.text;
    applyFilters();
  });

  // 🚀 INITIAL LOAD LOGIC (same as your current logic)
  if (widget.selectedType != null) {
    selectedType = widget.selectedType;
    fetchSellerInteractions(widget.selectedType!);
  } else {
    fetchOrders();
  }

  // 🔄 AUTO REFRESH TIMER (same logic but safer)
  _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
    if (!mounted) return;

    if (selectedType != null) {
      fetchSellerInteractions(selectedType!);
    } else {
      fetchOrders();
    }
  });
}

  @override
  void dispose() {
    _timer?.cancel();
    searchController.dispose();
    super.dispose();
  }

List get currentList {
  if (selectedType == "cart") return cartItems;
  if (selectedType == "abandoned") return abandonedItems;
  if (selectedType == "wishlist") return wishlistItems;
  if (selectedType == "received") return receivedItems;
  if (selectedType == "failed") return failedItems;
  return [];
}
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      /// 🔥 GRADIENT APPBAR
    appBar: AppBar(
  foregroundColor: Colors.white,
  title: Text(
    widget.selectedTypeName ?? "Orders",
    style: const TextStyle(color: Colors.white),
  ),
  centerTitle: true,
  elevation: 0,
  flexibleSpace: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF3B3F6B), Color(0xFF3C67A0)],
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
            
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Row(
    children: [

      /// 🔽 SEARCHABLE DROPDOWN BUTTON
      Expanded(
        child: InkWell(
          onTap: () => openSearchableDropdown(),
          borderRadius: BorderRadius.circular(14),

          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                )
              ],
            ),

            child: Row(
              children: [

                const Icon(Icons.tune),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    selectedType == null
                        ? "Select Order Type"
                        : dropdownItems.firstWhere(
                            (e) => e["value"] == selectedType)["label"]!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),

                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
      ),

      const SizedBox(width: 12),

      /// 🔄 RESET BUTTON
      InkWell(
        onTap: () {
          setState(() {
            selectedType = null;
            isLoading = true;

            selectedStatus = "all";
            searchController.clear();
            searchQuery = "";
          });

          fetchOrders();
        },

        borderRadius: BorderRadius.circular(12),

        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),

          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent),
          ),

          child: Row(
            children: const [
              Icon(Icons.refresh,
                  color: Colors.redAccent, size: 18),
              SizedBox(width: 6),
              Text(
                "Reset",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
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
Expanded(
  child: isLoading
      ? const Center(child: CircularProgressIndicator())

      /// ✅ USE FILTERED LIST HERE
      : filteredCurrentList.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredCurrentList.length,
              itemBuilder: (context, index) {
                final item = filteredCurrentList[index];

                Color statusColor =
                    getStatusColor(item["status"]);

                return Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [

                      /// 🔥 LEFT STRIP
                      Container(
                        width: 5,
                        height: 110,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius:
                              const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            bottomLeft:
                                Radius.circular(18),
                          ),
                        ),
                      ),

                      /// 📦 CONTENT
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(14),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              /// TITLE + DATE
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item["item_name"] ??
                                          "No Name",
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),

                                  Text(
                                    item["created_on"] ??
                                        "",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors
                                          .grey.shade500,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              /// 👤 CUSTOMER
                              Row(
                                children: [
                                  Icon(Icons.person,
                                      size: 16,
                                      color: Colors.grey
                                          .shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    item["customer_name"] ??
                                        "N/A",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors
                                          .grey.shade800,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              /// 🆔 ID (wishlist hide)
                              if (selectedType != "wishlist")
                                Row(
                                  children: [
                                    Icon(
                                        Icons
                                            .confirmation_number,
                                        size: 16,
                                        color: Colors.grey
                                            .shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      selectedType ==
                                                  "received" ||
                                              selectedType ==
                                                  "failed"
                                          ? "Order ID: ${item["order_id"] ?? ""}"
                                          : "Cart ID: ${item["cart_id"] ?? ""}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey
                                            .shade700,
                                      ),
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 12),

                              /// 🔥 STATUS
                              Align(
                                alignment:
                                    Alignment.centerRight,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(
                                            20),
                                  ),
                                  child: Text(
                                    (item["status"] ?? "")
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )

      /// 🟢 SECOND LIST (Orders)
      : filteredOrders.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: 10),
                  child: orderItem(filteredOrders[index]),
                );
              },
            )

      /// ❌ EMPTY
      : Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox,
                  size: 60,
                  color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Text(
                "No Data Found",
                style: TextStyle(
                    color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
)   ]
        )
      )
    );
  }
}