import 'dart:convert';
import 'package:ecolods/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DiscountStep extends StatefulWidget {
  final String productId;
  final double salePrice;
  final Map<String, dynamic>? existingData;

  const DiscountStep({
    super.key,
    required this.productId,
    required this.salePrice,
    this.existingData,
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

  double currentSalePrice = 0;

  bool get isEdit => widget.existingData != null;

  /// ================= INIT =================
  @override
  void initState() {
    super.initState();

    print("🟡 INIT PRICE: ${widget.salePrice}");

    final data = widget.existingData ?? {};

    discountType = discountTypes.contains(data["disc_type"])
        ? data["disc_type"]
        : "percentage";

    discountValueController.text = data["disc_amt"]?.toString() ?? "";
    startDateController.text = data["disc_start_date"] ?? "";
    endDateController.text = data["disc_end_date"] ?? "";

    currentSalePrice = widget.salePrice;

    loadDiscount();

    discountValueController.addListener(() {
      if (discountType != null) setState(() {});
    });
  }

  /// ================= PRICE UPDATE FIX =================
  @override
  void didUpdateWidget(covariant DiscountStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.salePrice != oldWidget.salePrice &&
        widget.salePrice > 0) {
      print("🟢 UPDATED PRICE RECEIVED: ${widget.salePrice}");

      setState(() {
        currentSalePrice = widget.salePrice;
      });
    }
  }

  /// ================= CALCULATIONS =================
  double getDiscountAmount() {
    double value = double.tryParse(discountValueController.text) ?? 0;

    if (discountType == "percentage") {
      return (currentSalePrice * value) / 100;
    }
    return value;
  }

  double getFinalPrice() {
    return currentSalePrice - getDiscountAmount();
  }

  /// ================= LOAD =================
  Future loadDiscount() async {
    try {
      var url = Uri.parse("${ApiService.baseUrl}discount.php");

      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get",
          "productid": widget.productId,
        }),
      );

      print("RAW GET RESPONSE: ${response.body}");

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {
        final res = data["data"];

        String? type = res["disc_type"];
        if (!discountTypes.contains(type)) type = null;

        setState(() {
          discountType = type ?? "percentage";
          discountValueController.text =
              res["disc_amt"]?.toString() ?? '';
          startDateController.text =
              res["disc_start_date"] ?? '';
          endDateController.text =
              res["disc_end_date"] ?? '';
        });
      }
    } catch (e) {
      print("LOAD ERROR: $e");
    }

    setState(() => isLoading = false);
  }

  /// ================= DATE PICKER =================
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

  /// ================= SAVE =================
  Future<bool> saveData() async {
    if (isSaving) return false;

    FocusScope.of(context).unfocus();

    double value = double.tryParse(discountValueController.text) ?? 0;

    /// ❌ VALIDATION
    if (currentSalePrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid price ❌")),
      );
      return false;
    }

    if (value > currentSalePrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Discount > Price not allowed ❌")),
      );
      return false;
    }

    if (startDateController.text.isEmpty ||
        endDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select dates ❌")),
      );
      return false;
    }

    DateTime start = DateTime.parse(startDateController.text);
    DateTime end = DateTime.parse(endDateController.text);

    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End date must be after start ❌")),
      );
      return false;
    }

    setState(() => isSaving = true);

    try {
      var url = Uri.parse("${ApiService.baseUrl}discount.php");

      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "save",
          "productid": widget.productId,
          "disc_type": discountType,
          "disc_amt": value,
          "disc_start_date": startDateController.text,
          "disc_end_date": endDateController.text,

          /// 🔥 MAIN FIX
          "original_price": currentSalePrice,
        }),
      );

      print("RAW SAVE RESPONSE: ${response.body}");

      var data = jsonDecode(response.body);

      if (data["status"] == "success") {
        double serverPrice =
            (data["sale_price"] ?? getFinalPrice()).toDouble();

        setState(() {
          currentSalePrice = serverPrice;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Discount Saved ✅")),
        );

        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Error ❌")),
        );
      }
    } catch (e) {
      print("SAVE ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server Error ❌")),
      );
    }

    setState(() => isSaving = false);
    return false;
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    print("🔵 BUILD PRICE: ${widget.salePrice}");

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Original Price: ₹ $currentSalePrice",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              /// START DATE
              TextField(
                controller: startDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Start Date",
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
                  labelText: "End Date",
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                onTap: () => pickDate(endDateController),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: discountTypes.contains(discountType)
                    ? discountType
                    : null,
                decoration: const InputDecoration(
                  labelText: "Discount Type",
                  border: OutlineInputBorder(),
                ),
                items: discountTypes
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => discountType = value);
                },
              ),

              const SizedBox(height: 16),

              TextField(
                controller: discountValueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Discount Value",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Discount: ₹ ${getDiscountAmount().toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.green),
              ),

              Text(
                "Final Price: ₹ ${getFinalPrice().toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        if (isSaving)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  /// ================= FORM =================
  Map<String, dynamic> getFormData() {
    return {
      "disc_type": discountType,
      "disc_amt": discountValueController.text,
      "disc_start_date": startDateController.text,
      "disc_end_date": endDateController.text,
      "final_price": getFinalPrice(),
    };
  }
}