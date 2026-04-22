import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ecolods/api/api_service.dart';

class StockUpdateScreen extends StatefulWidget {
  final int productId;
  final int stock;
  final String skucode;
  final String name;
  final String image;

  const StockUpdateScreen({
    super.key,
    required this.productId,
    required this.stock,
    required this.skucode,
    required this.name,
    required this.image,
  });

  @override
  State<StockUpdateScreen> createState() => _StockUpdateScreenState();
}

class _StockUpdateScreenState extends State<StockUpdateScreen> {
  TextEditingController qtyController = TextEditingController(text: "1");
  String action = "increase";
  bool loading = false;

  Future<void> updateStock() async {
    setState(() => loading = true);

    final res = await http.post(
      Uri.parse("${ApiService.baseUrl}Inventory.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "action": action,
        "skucode": widget.skucode,
        "qty": int.parse(qtyController.text),
      }),
    );

    final data = jsonDecode(res.body);

    setState(() => loading = false);

    if (data["status"] == "success") {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Stock")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            widget.image.isNotEmpty
                ? Image.network(widget.image, height: 150)
                : const Icon(Icons.image, size: 100),
            Text(widget.name),
            Text("SKU: ${widget.skucode}"),
            Text("Stock: ${widget.stock}"),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        setState(() => action = "increase"),
                    child: const Text("ADD"),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        setState(() => action = "decrease"),
                    child: const Text("SUBTRACT"),
                  ),
                ),
              ],
            ),

            TextField(controller: qtyController),

            ElevatedButton(
              onPressed: loading ? null : updateStock,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("UPDATE"),
            )
          ],
        ),
      ),
    );
  }
}