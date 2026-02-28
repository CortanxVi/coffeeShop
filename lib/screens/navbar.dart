import 'package:flutter/material.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import '../screens/order.dart';
import '../screens/home.dart';
import '../screens/history.dart';
import '../screens/signin.dart';
import '../screens/dashboard.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int selected = 0;
  final PageController controller = PageController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          HomeScreen(tableNo: 1),
          OrderScreen(),
          HistoryScreen(),
          DashboardScreen(),
          SignInScreen(),
        ],
      ),
      bottomNavigationBar: StylishBottomBar(
        option: AnimatedBarOptions(
          iconStyle: IconStyle.animated,
          iconSize: 26,
          opacity: 0.3,
        ),
        items: [
          BottomBarItem(
            icon: const Icon(Icons.house_outlined),
            selectedIcon: const Icon(Icons.house),
            selectedColor: Colors.brown,
            unSelectedColor: Colors.grey,
            title: const Text('Home'),
          ),
          BottomBarItem(
            icon: const Icon(Icons.receipt_outlined),
            selectedIcon: const Icon(Icons.receipt),
            selectedColor: Colors.brown,
            unSelectedColor: Colors.grey,
            title: const Text('Order'),
          ),
          BottomBarItem(
            icon: const Icon(Icons.history),
            selectedColor: Colors.brown,
            unSelectedColor: Colors.grey,
            title: const Text('History'),
          ),
          BottomBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            selectedColor: Colors.brown,
            unSelectedColor: Colors.grey,
            title: const Text('Dashboard'),
          ),
          BottomBarItem(
            icon: const Icon(Icons.person_2_outlined),
            selectedIcon: const Icon(Icons.person),
            selectedColor: Colors.brown,
            unSelectedColor: Colors.grey,
            title: const Text('Profile'),
          ),
        ],
        currentIndex: selected,
        onTap: (index) {
          if (index == selected) return;
          controller.jumpToPage(index);
          setState(() => selected = index);
        },
      ),
    );
  }
}
