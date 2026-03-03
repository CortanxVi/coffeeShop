import 'package:flutter/material.dart';

class CartService {
  static final CartService instance = CartService._internal();
  CartService._internal();

  final ValueNotifier<List<Map<String, dynamic>>> cartItems = ValueNotifier([]);

  // เพิ่มลงตะกร้า — ถ้า menuId + note ซ้ำ ให้เพิ่ม quantity แทน
  void addToCart(Map<String, dynamic> item) {
    final currentList = List<Map<String, dynamic>>.from(cartItems.value);
    final menuId = item['menuId'];
    final note = (item['note'] ?? '').toString();

    final existingIndex = currentList.indexWhere(
      (e) => e['menuId'] == menuId && (e['note'] ?? '').toString() == note,
    );

    if (existingIndex != -1) {
      // เพิ่ม quantity รายการเดิม
      final existing = Map<String, dynamic>.from(currentList[existingIndex]);
      existing['quantity'] =
          (existing['quantity'] ?? 1) + (item['quantity'] ?? 1);
      currentList[existingIndex] = existing;
    } else {
      currentList.add(Map<String, dynamic>.from(item));
    }

    cartItems.value = currentList;
  }

  // ลบออกจากตะกร้า
  void removeFromCart(int index) {
    final currentList = List<Map<String, dynamic>>.from(cartItems.value);
    currentList.removeAt(index);
    cartItems.value = currentList;
  }

  // อัปเดต quantity ของรายการที่ index
  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeFromCart(index);
      return;
    }
    final currentList = List<Map<String, dynamic>>.from(cartItems.value);
    final item = Map<String, dynamic>.from(currentList[index]);
    item['quantity'] = quantity;
    currentList[index] = item;
    cartItems.value = currentList;
  }

  // ล้างตะกร้า
  void clearCart() {
    cartItems.value = [];
  }

  // จำนวนรายการทั้งหมด (นับแต่ละ qty)
  int getTotalItemCount() {
    int total = 0;
    for (var item in cartItems.value) {
      total += (item['quantity'] ?? 1) as int;
    }
    return total;
  }

  // คำนวณยอดรวม
  double getTotalPrice() {
    double total = 0;
    for (var item in cartItems.value) {
      final price = (item['price'] ?? 0).toDouble();
      final qty = (item['quantity'] ?? 1) as int;
      total += price * qty;
    }
    return total;
  }
}
