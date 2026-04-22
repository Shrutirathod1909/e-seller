import 'package:flutter/material.dart';
import 'VariantsStep.dart';
import 'product_detail.dart';
import 'productinfoscreen.dart';
import 'image_upload.dart';
import 'discount_screen.dart';

class AddSingleCatalogScreen extends StatefulWidget {
  final int vendorId;
  final int company_id;
  final Map<String, dynamic>? productData;
  final List? variants;

  const AddSingleCatalogScreen({
    super.key,
    required this.vendorId,
    required this.company_id,
    this.productData,
    this.variants,
  });

  @override
  State<AddSingleCatalogScreen> createState() =>
      _AddSingleCatalogScreenState();
}

class _AddSingleCatalogScreenState extends State<AddSingleCatalogScreen> {
  int step = 0;
  String productId = "";
  bool isSubmitting = false;

  double cadPrice = 0; // ✅ UPDATED

  /// Global draft
  Map<String, dynamic> draftData = {};
  List existingVariants = [];
  Map<String, dynamic> productDataLocal = {};

  final GlobalKey<ProductDetailScreenState> step1Key = GlobalKey();
  final GlobalKey<ProductInfoStepState> step2Key = GlobalKey();
  final GlobalKey<ImageUploadStepState> step3Key = GlobalKey();
  final GlobalKey<DiscountStepState> step4Key = GlobalKey();
  final GlobalKey<VariantsStepState> variantsKey = GlobalKey();

  bool get isEdit => widget.productData != null;
  int get vendorId => widget.vendorId;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      productId = widget.productData!["productid"]?.toString() ?? "";
      productDataLocal = Map.from(widget.productData!);
      existingVariants = widget.variants ?? [];

      /// ✅ UPDATED
      cadPrice = double.tryParse(
              widget.productData!["cad_price"]?.toString() ?? "0") ??
          0;

      // preload into draft
      draftData.addAll(productDataLocal);
      draftData["variants"] = existingVariants;
    }
  }

  /// ================= NEXT BUTTON =================
  Future<void> handleStepAction() async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);

    try {
      bool valid = false;

      switch (step) {
        case 0:
          String? id = await step1Key.currentState?.saveProduct();
          if (id == null) return;

          productId = id;

          draftData["productid"] = id;
          draftData.addAll(step1Key.currentState?.getFormData() ?? {});
          break;

      case 1:
  valid = await step2Key.currentState?.saveData() ?? false;
  if (!valid) return;

  // ✅ DO NOTHING HERE (IMPORTANT)
  // cadPrice already updated via onPriceChanged

  draftData.addAll(step2Key.currentState?.getFormData() ?? {});
  break;

        case 2:
          valid = await step3Key.currentState?.saveData() ?? false;
          if (!valid) return;

          draftData.addAll(step3Key.currentState?.getFormData() ?? {});
          break;

        case 3:
          valid = await step4Key.currentState?.saveData() ?? false;
          if (!valid) return;

          draftData.addAll(step4Key.currentState?.getFormData() ?? {});
          break;

        case 4:
          valid = await variantsKey.currentState?.saveData() ?? false;
          if (!valid) return;

          draftData.addAll(variantsKey.currentState?.getFormData() ?? {});

          showMsg("🎉 Catalog Completed");
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

  /// ================= BOTTOM BUTTON =================
  Widget bottomButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff3F3D6B),
          ),
          onPressed: isSubmitting ? null : handleStepAction,
          child: isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  step == 4
                      ? (isEdit ? "Update" : "Submit")
                      : (isEdit ? "Update & Next" : "Next"),
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("➡️ PASSING TO DISCOUNT: $cadPrice");
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() => step--);
                },
              )
            : null,
        title: Text(
          isEdit ? "Edit Catalog" : "Add Catalog",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff3F3D6B),
      ),
      body: Column(
        children: [
          /// PROGRESS BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: List.generate(5, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    decoration: BoxDecoration(
                      color: index <= step
                          ? const Color(0xff3F3D6B)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }),
            ),
          ),

          Text("${step + 1}/5",
              style: const TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          /// MAIN CONTENT
          Expanded(
            child: IndexedStack(
              index: step,
              children: [
                ProductDetailScreen(
                  key: step1Key,
                  vendorId: vendorId,
                  companyId: widget.company_id,
                  existingData: draftData,
                  onProductCreated: (id) {
                    productId = id;
                  },
                ),

                /// ✅ UPDATED HERE
                ProductInfoStep(
                  key: step2Key,
                  productId: productId.isNotEmpty ? productId : "0",
                  existingData: productId.isNotEmpty
                      ? (isEdit ? productDataLocal : draftData)
                      : {},
                onPriceChanged: (price) {
    print("🔥 CAD PRICE RECEIVED: $price");

    setState(() {        // ✅ VERY IMPORTANT
      cadPrice = price;
    });
  },
                ),

                ImageUploadStep(
                  key: step3Key,
                  productId: productId,
                  existingData: isEdit ? productDataLocal : draftData,
                ),

                /// ✅ PASS CAD PRICE
                DiscountStep(
                  key: step4Key,
  productId: productId,
  salePrice: cadPrice,
                  existingData: isEdit ? productDataLocal : draftData,
                ),

                VariantsStep(
                  key: variantsKey,
                  productId: int.tryParse(productId) ?? 0,
                  vendorId: vendorId,
                  existingVariants: draftData["variants"] ?? [],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomButton(),
    );
  }
}