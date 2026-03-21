import 'package:ecolods/screen/add_single_catalog_screen.dart';
import 'package:ecolods/screen/appbarscreen.dart';
import 'package:ecolods/screen/view_catalog_screen.dart';
import 'package:flutter/material.dart';

class CatalogUploadMenu extends StatefulWidget {
  const CatalogUploadMenu({super.key});

  @override
  State<CatalogUploadMenu> createState() => _CatalogUploadMenuState();
}

class _CatalogUploadMenuState extends State<CatalogUploadMenu> {
  /// Menu card builder
  Widget menuCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  /// Refresh or fetch products after adding catalog
  void refreshProducts() {
    // Implement your product refresh logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Product list refreshed!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: const Color(0xfff5f5f5),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // View Catalog
            menuCard(
              context,
              Icons.visibility,
              "View Catalog",
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewCatalogScreen()),
                );
              },
            ),

            // Add Single Catalog
            menuCard(
  context,
  Icons.add_box,
  "Add Single Catalog",
  Colors.green,
  () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddSingleCatalogScreen()),
    );

    if (result == true) {
      refreshProducts();
    }
  },

            ),
          ],
        ),
      ),
    );
  }
}