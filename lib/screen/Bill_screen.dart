import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ecolods/api/api_service.dart';

class InvoiceScreen extends StatefulWidget {
  final String invoiceNo;
  const InvoiceScreen({super.key, required this.invoiceNo});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  Map bill = {};
  List items = [];
  Map company = {};
  bool loading = true;
  static const currency = "\u20B9";

  @override
  void initState() {
    super.initState();
    getInvoice();
  }

  // ================= FETCH INVOICE =================
  Future getInvoice() async {
    try {
      final url = Uri.parse("${ApiService.baseUrl}invoice.php");
      final response = await http.post(
        url,
        body: {"invoice_no": widget.invoiceNo},
      );

      var data = jsonDecode(response.body);
      if (data["status"] == "success") {
        setState(() {
          bill = data["bill"] ?? {};
          items = data["items"] ?? [];
          company = data["company"] ?? {};
          loading = false;
        });
      } else {
        setState(() => loading = false);
        print("Invoice API Error: ${data["message"]}");
      }
    } catch (e) {
      print("API Error: $e");
      setState(() => loading = false);
    }
  }

  // ================= HELPERS =================
  String value(dynamic v) => (v == null || v.toString() == "null") ? "0" : v.toString();
  String getCompanyName() => value(company["site_name"] ?? "Orozone");

  double getFinalAmount() {
    double subtotal = double.tryParse(value(bill["total_amount"])) ?? 0;
    double gst = double.tryParse(value(bill["totalgst"])) ?? 0;
    double shipping = double.tryParse(value(bill["shipping_charges"])) ?? 0;
    double discount = double.tryParse(value(bill["total_discount"])) ?? 0;
    return subtotal + gst + shipping - discount;
  }

  String formatAddress(String address) {
    if (address.isEmpty || address.toLowerCase() == "null") return "-";
    return address.replaceAll(",", "\n");
  }

  Future<Uint8List?> networkImageBytes(String url) async {
    try {
      if (url.startsWith("http")) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) return response.bodyBytes;
      } else {
        final data = await rootBundle.load(url);
        return data.buffer.asUint8List();
      }
    } catch (e) {
      print("Image load error: $e");
    }
    return null;
  }

  // ================= PDF GENERATION =================
  Future printInvoice() async {
    try {
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);
      final pdf = pw.Document();

      Uint8List? companyLogoBytes = await networkImageBytes(company["site_logo"] ?? "");

      Map<String, Uint8List?> productImages = {};
      for (var item in items) {
        productImages[item["product_name"]] = await networkImageBytes(value(item["image"]));
      }

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (companyLogoBytes != null)
                        pw.Image(pw.MemoryImage(companyLogoBytes), width: 80),
                      pw.SizedBox(height: 5),
                      pw.Text(getCompanyName(),
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Container(
                        width: 200, // fix width for wrapping
                        child: pw.Text(
                          formatAddress(value(company["address"] ?? "Company Address")),
                          style: pw.TextStyle(fontSize: 10),
                          softWrap: true,
                        ),
                      ),
                      pw.Text("Phone: ${value(company["contact_phone"] ?? '0000000000')}"),
                      pw.Text("Email: ${value(company["contact_email"] ?? 'info@company.com')}"),
                      pw.Text("GST: ${value(company["gst_no"] ?? '-')}")
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Invoice No: ${value(bill["invoice_no"])}"),
                      pw.Text("Date: ${value(bill["created_on"])}"),
                      pw.Text("Customer: ${value(bill["customer_name"])}"),
                      pw.SizedBox(height: 5),
                      pw.Text("Shipping Address:"),
                      pw.Container(
                        width: 200, // fix width for wrapping
                        child: pw.Text(
                          formatAddress(value(bill["customer_address"])),
                          style: pw.TextStyle(fontSize: 10),
                          softWrap: true,
                        ),
                      ),
                      pw.Text("Email: ${value(bill["email_id"])}"),
                      pw.Text("Contact: ${value(bill["contact_no"])}"),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Product Table
              pw.Table(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
                columnWidths: {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                  4: pw.FlexColumnWidth(2),
                  5: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      tableCell("Product", bold: true),
                      tableCell("Image", bold: true),
                      tableCell("SKU", bold: true),
                      tableCell("Qty", bold: true),
                      tableCell("Sale Price", bold: true),
                      tableCell("Total", bold: true),
                    ],
                  ),
                  ...items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final imageBytes = productImages[item["product_name"]];
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                          color: i % 2 == 0 ? PdfColors.grey200 : PdfColors.white),
                      children: [
                        tableCell(value(item["product_name"])),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: imageBytes != null
                              ? pw.Image(pw.MemoryImage(imageBytes), width: 50, height: 50)
                              : pw.Text("-"),
                        ),
                        tableCell(value(item["sku_code"])),
                        tableCell(value(item["qty"]), alignRight: true),
                        tableCell("$currency${value(item["sale_price"])}", alignRight: true),
                        tableCell("$currency${value(item["total_price"])}", alignRight: true),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),

              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    priceRow("Subtotal", value(bill["total_amount"])),
                    priceRow("GST", value(bill["totalgst"])),
                    priceRow("Shipping", value(bill["shipping_charges"])),
                    priceRow("Discount", value(bill["total_discount"])),
                    pw.Divider(),
                    priceRow("Grand Total", getFinalAmount().toStringAsFixed(2), bold: true),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Container(
                alignment: pw.Alignment.center,
                color: PdfColors.grey200,
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text("Thank you for shopping with ${getCompanyName()}!"),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      print("PDF Error: $e");
    }
  }

  pw.Widget tableCell(String text, {bool bold = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Align(
        alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(text,
            style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ),
    );
  }

  pw.Widget priceRow(String title, String price, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text("$currency$price",
            style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
                foregroundColor: Colors.white,

        elevation: 5,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B3F6B), Color(0xFF3C67A0)],
            ),
          ),
        ),
        title: const Text("Invoice",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company & Invoice Info
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: screenWidth * 0.45,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (company["site_logo"] != null)
                          Image.network(company["site_logo"], width: 80),
                        const SizedBox(height: 5),
                        Text(getCompanyName(),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(value(company["address"] ?? "Company Address")),
                        Text("Phone: ${value(company["contact_phone"] ?? '0000000000')}"),
                        Text("Email: ${value(company["contact_email"] ?? 'info@company.com')}"),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: screenWidth * 0.45,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Invoice No: ${value(bill["invoice_no"])}"),
                        Text("Date: ${value(bill["created_on"])}"),
                        Text("Customer: ${value(bill["customer_name"])}"),
                        const SizedBox(height: 5),
                        Text("Shipping Address:"),
                        Text(formatAddress(value(bill["customer_address"]))),
                        Text("Email: ${value(bill["email_id"])}"),
                        Text("Contact: ${value(bill["contact_no"])}"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Product Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Product")),
                  DataColumn(label: Text("Image")),
                  DataColumn(label: Text("SKU")),
                  DataColumn(label: Text("Qty")),
                  DataColumn(label: Text("Sale Price")),
                  DataColumn(label: Text("Total")),
                ],
                rows: items
                    .map((item) => DataRow(cells: [
                          DataCell(Text(value(item["product_name"]))),
                          DataCell(item["image"] != null
                              ? Image.network(item["image"], width: 50, height: 50)
                              : const Text("-")),
                          DataCell(Text(value(item["sku_code"]))),
                          DataCell(Text(value(item["qty"]))),
                          DataCell(Text("$currency${value(item["sale_price"])}")),
                          DataCell(Text("$currency${value(item["total_price"])}")),
                        ]))
                    .toList(),
              ),
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Subtotal: $currency${value(bill["total_amount"])}"),
                  Text("GST: $currency${value(bill["totalgst"])}"),
                  Text("Shipping: $currency${value(bill["shipping_charges"])}"),
                  Text("Discount: $currency${value(bill["total_discount"])}"),
                  const Divider(),
                  Text("Grand Total: $currency${getFinalAmount().toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: printInvoice,
                child: const Text("Print / Download PDF"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}