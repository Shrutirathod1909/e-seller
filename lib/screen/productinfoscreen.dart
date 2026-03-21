import 'package:ecolods/api/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductInfoStep extends StatefulWidget {

  final String productId;

  const ProductInfoStep({
    super.key,
    required this.productId
  });

  @override
  State<ProductInfoStep> createState() => ProductInfoStepState();
}

class ProductInfoStepState extends State<ProductInfoStep> {



  // 🔥 IMPORTANT CHANGE
 Future<bool> saveData() async {

  print("STEP2 RECEIVED PRODUCT ID: ${widget.productId}");

  if(!_formKey.currentState!.validate()){
    return false;
  }

  try {
    var url = Uri.parse("${ApiService.baseUrl}/product_info.php");

    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "productid": widget.productId,
        "brand": brand.text,
        "sku": sku.text,
        "barcode": barcode.text,
        "material": material.text,
        "color": color.text,
        "size": size.text,
        "length": length.text,
        "width": width.text,
        "height": height.text,
        "weight": weight.text,
        "manufacturer": manufacturer.text,
        "warranty": warranty.text,
      }),
    );

    print("STEP2 RESPONSE: ${response.body}");

    var data = jsonDecode(response.body);

    if (data["status"] == "success") {
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error Saving Product Info")),
      );
      return false;
    }

  } catch (e) {
    print("ERROR: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Server Error")),
    );

    return false;
  }
}
  final _formKey = GlobalKey<FormState>();

  final brand = TextEditingController();
  final sku = TextEditingController();
  final barcode = TextEditingController();
  final material = TextEditingController();
  final color = TextEditingController();
  final size = TextEditingController();

  final length = TextEditingController();
  final width = TextEditingController();
  final height = TextEditingController();
  final weight = TextEditingController();
  final manufacturer = TextEditingController();
  final warranty = TextEditingController();

  Future saveProduct() async {

    if(!_formKey.currentState!.validate()){
      return;
    }

    var url = Uri.parse("${ApiService.baseUrl}/product_info.php");

    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({

        "productid": widget.productId,

        "brand": brand.text,
        "sku": sku.text,
        "barcode": barcode.text,
        "material": material.text,
        "color": color.text,
        "size": size.text,

        "length": length.text,
        "width": width.text,
        "height": height.text,
        "weight": weight.text,

        "manufacturer": manufacturer.text,
        "warranty": warranty.text,
      }),
    );

    var data = jsonDecode(response.body);

    if (data["status"] == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product Info Updated")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error Saving Product")),
      );
    }
  }

  Widget inputField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isNumber = false,
  }) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: TextFormField(
        controller: controller,

        keyboardType: isNumber ? TextInputType.number : TextInputType.text,

        validator: (value){

          if(value == null || value.trim().isEmpty){
            return "$label is required";
          }

          if(isNumber && double.tryParse(value) == null){
            return "Enter valid number";
          }

          return null;
        },

        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),

          filled: true,
          fillColor: Colors.grey.shade100,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Form(

      key: _formKey,

      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            /// BASIC INFO
            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Basic Product Info",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  inputField("Brand Name", Icons.business, brand),
                  inputField("SKU Code", Icons.qr_code, sku),
                  inputField("Barcode", Icons.qr_code_2, barcode),
                  inputField("Material", Icons.category, material),
                  inputField("Color", Icons.palette, color),

                  inputField(
                    "Size",
                    Icons.straighten,
                    size,
                    isNumber: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// DIMENSION
            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Product Dimensions",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  inputField(
                    "Length (cm)",
                    Icons.height,
                    length,
                    isNumber: true,
                  ),

                  inputField(
                    "Width (cm)",
                    Icons.width_full,
                    width,
                    isNumber: true,
                  ),

                  inputField(
                    "Height (cm)",
                    Icons.height_outlined,
                    height,
                    isNumber: true,
                  ),

                  inputField(
                    "Weight (kg)",
                    Icons.scale,
                    weight,
                    isNumber: true,
                  ),

                  inputField("Manufacturer", Icons.factory, manufacturer),

                  inputField(
                    "Warranty (Months)",
                    Icons.verified,
                    warranty,
                    isNumber: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveProduct,
                child: const Text("Save Product"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}