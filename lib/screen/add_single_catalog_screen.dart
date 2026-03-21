import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'VariantsStep.dart';
import 'product_detail.dart';
import 'productinfoscreen.dart';
import 'image_upload.dart';
import 'discount_screen.dart';

class AddSingleCatalogScreen extends StatefulWidget {
  final Map<String, dynamic>? productData;
  final List? variants;

  const AddSingleCatalogScreen({super.key, this.productData, this.variants});

  @override
  State<AddSingleCatalogScreen> createState() =>
      _AddSingleCatalogScreenState();
}

class _AddSingleCatalogScreenState extends State<AddSingleCatalogScreen> {
  int step = 0;
  String productId = "";
  int vendorId = 0;
  bool isSubmitting = false;

  List existingVariants = [];
  Map<String, dynamic> productDataLocal = {};

  final GlobalKey<ProductDetailScreenState> step1Key = GlobalKey();
  final GlobalKey<ProductInfoStepState> step2Key = GlobalKey();
  final GlobalKey<ImageUploadStepState> step3Key = GlobalKey();
  final GlobalKey<DiscountStepState> step4Key = GlobalKey();
  final GlobalKey<VariantsStepState> variantsKey = GlobalKey();

  bool get isEdit => widget.productData != null;

  @override
  void initState() {
    super.initState();
    loadVendor();

    if (isEdit) {
      productId = widget.productData!["productid"]?.toString() ?? "";
      productDataLocal = Map.from(widget.productData!);
      existingVariants = widget.variants ?? [];
    }
  }

Future<void> loadVendor() async {
  final prefs = await SharedPreferences.getInstance();

  int id = prefs.getInt("vendor_id") ?? 0;

  print("Loaded vendor_id: $id");

  if (id == 0) {
    showMsg("Vendor ID not found ❌");
    return;
  }

  setState(() {
    vendorId = id;
  });
}
  Widget getStepWidget() {
    if (vendorId == 0) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (step) {
      case 0:
        return ProductDetailScreen(
          key: step1Key,
          vendorId: vendorId,
          existingData: productDataLocal,
          onProductCreated: (id) {
            print("RECEIVED ID: $id");
            setState(() {
              productId = id;
              step = 1;
            });
          },
        );

      case 1:
        return ProductInfoStep(
          key: step2Key,
          productId: productId,
        );

      case 2:
        return ImageUploadStep(
          key: step3Key,
          productId: productId,
        );

      case 3:
        return DiscountStep(
          key: step4Key,
          productId: productId,
        );

      case 4:
        return VariantsStep(
          key: variantsKey,
          productId: int.tryParse(productId) ?? 0,
          vendorId: vendorId,
          existingVariants: existingVariants,
        );

      default:
        return const SizedBox();
    }
  }

  Future<void> handleStepAction() async {
    if (vendorId == 0 || isSubmitting) return;

    setState(() => isSubmitting = true);

    try {
      bool valid = false;

      switch (step) {
        case 0:
          valid = step1Key.currentState?.saveData() ?? false;
          if (!valid) return;
          if (productId.isEmpty) {
            showMsg("Please click Save Product first");
            return;
          }
          setState(() => step = 1);
          return;

        case 1:
          valid = await step2Key.currentState?.saveData() ?? false;
          if (!valid) return;
          break;

        case 2:
          valid = await step3Key.currentState?.saveData() ?? false;
          if (!valid) return;
          break;

        case 3:
          valid = await step4Key.currentState?.saveData() ?? false;
          if (!valid) return;
          setState(() => step = 4);
          return;

        case 4:
          valid = await variantsKey.currentState?.saveData() ?? false;
          if (!valid) return;

          showMsg("Catalog Completed ✅");
          Navigator.pop(context, true);
          return;
      }

      if (step < 4) setState(() => step++);
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget bottomButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff3F3D6B),
        ),
        onPressed: (vendorId == 0 || isSubmitting) ? null : handleStepAction,
        child: isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                step == 4
                    ? (isEdit ? "Update" : "Submit")
                    : (isEdit ? "Update & Next" : "Next"),
                style: const TextStyle(color: Colors.white),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(isEdit ? "Edit Catalog" : "Add Catalog",
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff3F3D6B),
      ),
      body: getStepWidget(),
      bottomNavigationBar: bottomButton(),
    );
  }
}