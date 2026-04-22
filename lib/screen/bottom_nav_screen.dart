import 'package:flutter/material.dart';
import 'package:ecolods/screen/product_screen.dart';
import 'package:ecolods/screen/profile_screen.dart';
import 'package:ecolods/screen/Catalog_upload.dart';
import 'package:ecolods/screen/dashboard_screen.dart';
import 'package:ecolods/screen/orders_screen.dart';

class BottomNavScreen extends StatefulWidget {
  final int vendorId;
  final String companyName;
   final int companyId;

  const BottomNavScreen({
    super.key,
    required this.vendorId,
    required this.companyName,
    required this.companyId
  });

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    // Screens list with dynamic company name and vendorId
    final screens = [
      DashboardScreen(
        companyName: widget.companyName,
        vendorId: widget.vendorId,
      ),
      OrdersScreen(),
      ProfileScreen(),
      SellerProductScreen(),
    ];

    double navHeight = 60; // Responsive height
    double iconSize = 18; // Icon size
    double circleSize = 35; // Circle background size

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: screens,
      ),

      /// FAB
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B3F6B),
        child: const Icon(Icons.upload, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CatalogUploadMenu(vendorId: widget.vendorId,company_id: widget.companyId,),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      /// Bottom Navigation
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: const Color(0xFF3B3F6B),
        child: SizedBox(
          height: navHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              circleNavItem(Icons.dashboard, "Dashboard", 0, circleSize, iconSize),
              circleNavItem(Icons.shopping_bag, "Orders", 1, circleSize, iconSize),
              const SizedBox(width: 40), // space for FAB
              circleNavItem(Icons.receipt_long, "Profile", 2, circleSize, iconSize),
              circleNavItem(Icons.inventory, "Inventory", 3, circleSize, iconSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget circleNavItem(
      IconData icon, String name, int i, double circleSize, double iconSize) {
    bool selected = index == i;

    return GestureDetector(
      onTap: () {
        setState(() {
          index = i;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? circleSize : iconSize + 16,
            height: selected ? circleSize : iconSize + 16,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: selected
                  ? [
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: selected ? const Color(0xFF3B3F6B) : Colors.white70,
              size: iconSize,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.white : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}