import 'dart:convert';
import 'package:ecolods/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DiscountStep extends StatefulWidget {
  final String productId;

  const DiscountStep({
    super.key,
    required this.productId,
  });

  @override
  State<DiscountStep> createState() => DiscountStepState();
}

class DiscountStepState extends State<DiscountStep> {

  String? discountType;

  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final discountValueController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  final List<String> discountTypes = ["percentage", "amount"];

  @override
  void initState() {
    super.initState();
    loadDiscount();
  }

  /// LOAD DATA
  Future loadDiscount() async {
    try {
      var url = Uri.parse("${ApiService.baseUrl}discount.php");

      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"productid": widget.productId}),
      );

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {

        String? type = data["data"]["disc_type"];
        if (!discountTypes.contains(type)) type = null;

        setState(() {
          discountType = type;
          discountValueController.text = data["data"]["disc_amt"] ?? '';
          startDateController.text = data["data"]["disc_start_date"] ?? '';
          endDateController.text = data["data"]["disc_end_date"] ?? '';
          isLoading = false;
        });

      } else {
        setState(() => isLoading = false);
      }

    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  /// ✅ AUTO SAVE (USED BY NEXT BUTTON)
  Future<bool> saveData() async {

    if (discountType == null ||
        discountValueController.text.isEmpty ||
        startDateController.text.isEmpty ||
        endDateController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return false;
    }

    setState(() {
      isSaving = true;
    });

    try {

      var url = Uri.parse("${ApiService.baseUrl}discount.php");

      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "productid": widget.productId,
          "disc_type": discountType,
          "disc_amt": discountValueController.text,
          "disc_start_date": startDateController.text,
          "disc_end_date": endDateController.text
        }),
      );

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {
        return true; // ✅ SUCCESS
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Error saving discount")),
        );
        return false;
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server Error")),
      );

      return false;

    } finally {

      setState(() {
        isSaving = false;
      });

    }
  }

  /// DATE PICKER
  Future pickDate(TextEditingController controller) async {

    DateTime initialDate = DateTime.now();

    if (controller.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(controller.text);
      } catch (_) {}
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      controller.text =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Column(
        children: [

          /// START DATE
          TextField(
            controller: startDateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: "Discount Start Date",
              prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
            onTap: () => pickDate(startDateController),
          ),

          const SizedBox(height: 16),

          /// END DATE
          TextField(
            controller: endDateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: "Discount End Date",
              prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
            onTap: () => pickDate(endDateController),
          ),

          const SizedBox(height: 16),

          /// TYPE
          DropdownButtonFormField<String>(
            value: discountTypes.contains(discountType) ? discountType : null,
            decoration: const InputDecoration(
              labelText: "Discount Type",
              prefixIcon: Icon(Icons.percent),
              border: OutlineInputBorder(),
            ),
            items: discountTypes
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e[0].toUpperCase() + e.substring(1)),
                    ))
                .toList(),
            onChanged: (value) => setState(() => discountType = value),
          ),

          const SizedBox(height: 16),

          /// VALUE
          TextField(
            controller: discountValueController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Discount Value",
              prefixIcon: Icon(Icons.discount),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          /// 🔥 LOADING
          if (isSaving)
            const CircularProgressIndicator(),
        ],
      ),
    );
  }
}