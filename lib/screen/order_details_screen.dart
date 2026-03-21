import 'dart:convert';
import 'package:ecolods/screen/Bill_screen.dart';
import 'package:ecolods/screen/appbarscreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ecolods/api/api_service.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map order = {};
  List products = [];
  bool loading = true;
  bool updatingStatus = false;
  TextEditingController searchController = TextEditingController();
List filteredProducts = [];

  @override
  void initState() {
    super.initState();
    getOrderDetails();
    getProducts();
  }


  void showRejectDialog() {

  TextEditingController reasonController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {

      return AlertDialog(
        title: const Text("Reject Order"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Text("Please enter reject reason"),

            const SizedBox(height: 10),

            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Enter reason...",
                border: OutlineInputBorder(),
              ),
            ),

          ],
        ),
        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () {

              if(reasonController.text.trim().isEmpty){
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter reason"))
                );
                return;
              }

              Navigator.pop(context);

              updateOrderStatus(
                "rejected",
                reasonController.text,
              );

            },
            child: const Text("Submit"),
          )

        ],
      );
    },
  );
}

  /// GET ORDER DETAILS
  Future getOrderDetails() async {
    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}order_details.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"order_id": widget.orderId}),
      );

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {
        setState(() {
          order = data["order"] ?? {};
          loading = false;
        });
      } else {
        setState(() {
          order = {};
          loading = false;
        });
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  /// GET PRODUCTS
 Future getProducts() async {
  try {
    final response = await http.post(
      Uri.parse("${ApiService.baseUrl}order_products.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"order_id": widget.orderId}),
    );

    var data = jsonDecode(response.body);

    if (data["status"] == "success") {
      setState(() {
        products = data["products"];
        filteredProducts = products; // default
      });
    }
  } catch (e) {
    print("Product API Error: $e");
  }
}
  /// UPDATE ORDER STATUS
Future updateOrderStatus(String status, [String reason = ""]) async {
  setState(() => updatingStatus = true);

  try {
    final response = await http.post(
      Uri.parse("${ApiService.baseUrl}orders.php?action=update_status"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "order_id": widget.orderId,
        "status": status,
        "reason": reason
      },
    );

    var data = jsonDecode(response.body);

    if (data["status"] == "success") {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Order ${status == 'confirmed' ? 'accepted' : status == 'shipped' ? 'shipped' : 'rejected'} successfully",
          ),
        ),
      );

      /// 🔥 UPDATE LOCAL UI
      setState(() {
        order["approved"] = status;
      });

      updatingStatus = false;

      /// 🔥 GO BACK WITH DATA
      Navigator.pop(context, {
        "order_id": widget.orderId,
        "status": status
      });

    } else {
      setState(() => updatingStatus = false);
    }

  } catch (e) {
    setState(() => updatingStatus = false);
  }
}
  /// PRODUCT ITEM
  Widget productItem(Map item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade200,
            ),
            child: const Icon(Icons.inventory_2_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["product_name"] ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Qty: ${item["qty"] ?? "1"}   Size: ${item["size"] ?? ""}",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            "₹${item["sale_price"] ?? "0"}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          )
        ],
      ),
    );
  }

  /// PRICE ROW
  Widget priceRow(String title, String price, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text("₹$price",
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  String format(double val) => val.toStringAsFixed(2);

  String formatDate(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  /// ACTION BUTTONS
Widget actionButtons() {

 String status =
    (order["approved"] ?? "pending").toString().trim().toLowerCase();

  /// PENDING
  if (status == "pending") {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => showRejectDialog(),
            child: const Text(
              "Reject Order",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => updateOrderStatus("confirmed"),
            child: const Text(
              "Accept Order",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// CONFIRMED
  else if (status == "confirmed") {
    return Column(
      children: [

        /// SHIP BUTTON
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => updateOrderStatus("shipped"),
            child: const Text(
              "Mark Shipped",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),

        const SizedBox(height: 10),

        /// BILL BUTTON
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.receipt_long,color: Colors.white,),
            label: const Text("View Bill",style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InvoiceScreen(
                    invoiceNo: order["order_id"].toString(),
                  ),
                ),
              );

            },
          ),
        ),
      ],
    );
  }

  /// SHIPPED
  else if (status == "shipped") {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.receipt),
        label: const Text("View Bill"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceScreen(
                invoiceNo: order["order_id"].toString(),
              ),
            ),
          );

        },
      ),
    );
  }

  else {
    return const SizedBox.shrink();
  }
}


 @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    double orderAmount = 0;
    for (var item in products) {
      double price = double.tryParse(item["sale_price"].toString()) ?? 0;
      double qty = double.tryParse(item["qty"].toString()) ?? 1;
      orderAmount += price * qty;
    }

    double cgst = double.tryParse(order["cgst"]?.toString() ?? "0") ?? 0;
    double sgst = double.tryParse(order["sgst"]?.toString() ?? "0") ?? 0;
    double discount =
        double.tryParse(order["total_discount"]?.toString() ?? "0") ?? 0;
    double shipping =
        double.tryParse(order["shipping_price"]?.toString() ?? "0") ?? 0;

    double totalAmount = orderAmount + cgst + sgst + shipping - discount;

    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: const Color(0xfff5f5f5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// CUSTOMER INFO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(blurRadius: 10, color: Colors.black12)
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(radius: 24),
                    title: Text(order["customer_name"] ?? ""),
                    subtitle: Text(order["email_id"] ?? ""),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${order["customer_address"] ?? ""}, ${order["city"] ?? ""}",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// PRODUCTS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return productItem(products[index]);
                    },
                  ),
                  const Divider(),
                  priceRow("Order Amount", format(orderAmount)),
                  priceRow("GST", format(cgst + sgst)),
                  priceRow("Discount", format(discount)),
                  priceRow("Shipping", format(shipping)),
                  const Divider(),
                  priceRow("Total Amount", format(totalAmount), bold: true),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// STATUS
            if (order["approved"] != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Status: ${order["approved"]}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (order["approved_on"] != null)
                      Text(
                        formatDate(order["approved_on"]),
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),

            actionButtons(),
          ],
        ),
      ),
    );
  }
}