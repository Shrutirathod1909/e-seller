import 'dart:convert';
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
  bool loading = true;
  static const currency = "\u20B9";

  @override
  void initState() {
    super.initState();
    getInvoice();
  }

  Future getInvoice() async {
    final url = Uri.parse("${ApiService.baseUrl}invoice.php?invoice_no=${widget.invoiceNo}");
    final response = await http.get(url);
    var data = jsonDecode(response.body);

    if (data["status"] == "success") {
      setState(() {
        bill = data["bill"] ?? {};
        items = data["items"] ?? [];
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  String value(v) {
    if (v == null || v.toString() == "null") return "0";
    return v.toString();
  }

  String getCompanyName() {
    if (items.isNotEmpty) {
      return value(items[0]["company_name"]);
    }
    return "Company";
  }

  double getFinalAmount() {
    double subtotal = double.tryParse(value(bill["total_amount"])) ?? 0;
    double gst = double.tryParse(value(bill["totalgst"])) ?? 0;
    double shipping = double.tryParse(value(bill["shipping_charges"])) ?? 0;
    double discount = double.tryParse(value(bill["total_discount"])) ?? 0;
    return subtotal + gst + shipping - discount;
  }

  // ✅ ADDRESS FORMAT (2 LINE)
  String formatAddress(String address) {
    return address.replaceAll(",", "\n");
  }

  // ================= PDF =================
  Future printInvoice() async {
    try {
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [

                pw.Text(getCompanyName(),
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),

                pw.SizedBox(height: 5),

                pw.Text(
                  formatAddress(value(bill["customer_address"])),
                  textAlign: pw.TextAlign.center,
                ),

                pw.Text("Phone: ${value(bill["contact_no"])}"),
                pw.Text("Email: ${value(bill["email_id"])}"),

                pw.SizedBox(height: 15),

                pw.Text("INVOICE",
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),

                pw.Text("Invoice No: ${value(bill["invoice_no"])}"),
                pw.Text("Date: ${value(bill["created_on"])}"),
                pw.Text("Customer: ${value(bill["customer_name"])}"),

                pw.SizedBox(height: 20),

                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [

                    pw.TableRow(children: [
                      cell("Product", bold: true),
                      cell("Qty", bold: true),
                      cell("Price", bold: true),
                      cell("Total", bold: true),
                    ]),

                    ...items.map((item) => pw.TableRow(children: [
                      cell(value(item["product_name"])),
                      cell("x${value(item["qty"])}"),
                      cell("$currency${value(item["sale_price"])}"),
                      cell("$currency${value(item["total_price"])}"),
                    ])),
                  ],
                ),

                pw.SizedBox(height: 20),

                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    priceRowPdf("Subtotal", value(bill["total_amount"])),
                    priceRowPdf("GST", value(bill["totalgst"])),
                    priceRowPdf("Shipping", value(bill["shipping_charges"])),
                    priceRowPdf("Discount", value(bill["total_discount"])),
                    pw.Divider(),
                    priceRowPdf("Total", getFinalAmount().toStringAsFixed(2), bold: true),
                  ],
                ),

                pw.SizedBox(height: 20),

                pw.Text("Thank you for shopping!",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      print("PDF Error: $e");
    }
  }

  pw.Widget cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget priceRowPdf(String title, String price, {bool bold = false}) {
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
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF3B3F6B),
                Color(0xFF3C67A0),
              ],
            ),
          ),
        ),
        title: const Text("Invoice",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Text(getCompanyName(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            Text(
              formatAddress(value(bill["customer_address"])),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text("Phone: ${value(bill["contact_no"])}"),
            Text("Email: ${value(bill["email_id"])}"),

            const Divider(height: 30),

            Text("Invoice No: ${value(bill["invoice_no"])}"),
            Text("Date: ${value(bill["created_on"])}"),
            Text("Customer: ${value(bill["customer_name"])}"),

            const SizedBox(height: 20),

            ...items.map((item) => ListTile(
              title: Text(value(item["product_name"])),
              subtitle: Text("Qty: ${value(item["qty"])}"),
              trailing: Text("₹${value(item["total_price"])}"),
            )),

            const Divider(),

            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Subtotal: ₹${value(bill["total_amount"])}"),
                  Text("GST: ₹${value(bill["totalgst"])}"),
                  Text("Shipping: ₹${value(bill["shipping_charges"])}"),
                  Text("Discount: ₹${value(bill["total_discount"])}"),
                  const Divider(),
                  Text(
                    "Total: ₹${getFinalAmount().toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: printInvoice,
              child: const Text("Print / Download PDF"),
            ),
          ],
        ),
      ),
    );
  }
}