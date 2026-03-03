import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/cartService.dart';

class CartScreen extends StatefulWidget {
  final int tableNo;
  const CartScreen({super.key, required this.tableNo});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool isSubmitting = false;

  Future<void> _submitOrder() async {
    final cartItems = CartService.instance.cartItems.value;
    if (cartItems.isEmpty) return;

    setState(() => isSubmitting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
      final batch = FirebaseFirestore.instance.batch();

      for (var item in cartItems) {
        final qty = (item['quantity'] ?? 1) as int;
        final price = (item['price'] ?? 0).toDouble();

        // สร้าง order แยกตาม quantity (หรือเก็บ quantity ใน 1 document)
        final orderRef = FirebaseFirestore.instance.collection('orders').doc();
        batch.set(orderRef, {
          'menuId': item['menuId'],
          'menuName': item['name'],
          'tableNo': widget.tableNo,
          'userId': userId,
          'customerName': item['customerName'] ?? 'ลูกค้า',
          'status': 'pending',
          'notified': false,
          'timestamp': FieldValue.serverTimestamp(),
          'price': price,
          'quantity': qty,
          'totalPrice': price * qty,
          'note': item['note'] ?? '',
          'imageUrl': item['imageUrl'] ?? '',
        });
      }

      await batch.commit();
      CartService.instance.clearCart();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('ส่งคำสั่งซื้อ ${cartItems.length} รายการเรียบร้อยแล้ว!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตะกร้าสินค้า'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          // ปุ่มล้างตะกร้า
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: CartService.instance.cartItems,
            builder: (context, cart, _) {
              if (cart.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'ล้างตะกร้า',
                onPressed: () => _showClearCartDialog(),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: CartService.instance.cartItems,
        builder: (context, cart, child) {
          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ยังไม่มีรายการในตะกร้า',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'เลือกเมนูที่ต้องการแล้วกด "เพิ่มใส่ตะกร้า"',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // ─── รายการสินค้า ───
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    return _buildCartItem(item, index);
                  },
                ),
              ),

              // ─── สรุปยอดและปุ่มยืนยัน ───
              _buildOrderSummary(cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    final qty = (item['quantity'] ?? 1) as int;
    final price = (item['price'] ?? 0).toDouble();
    final note = (item['note'] ?? '').toString();
    final customerName = (item['customerName'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รูปภาพ
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child:
                    item['imageUrl'] != null &&
                        item['imageUrl'].toString().isNotEmpty
                    ? Image.network(
                        item['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder(),
                      )
                    : _imgPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),

            // ข้อมูลรายการ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'ไม่ระบุชื่อ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (customerName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '👤 $customerName',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  if (note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '📝 $note',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),

                  // ราคา + ควบคุม quantity
                  Row(
                    children: [
                      Text(
                        '฿${(price * qty).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.brown,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (qty > 1)
                        Text(
                          ' (฿${price.toStringAsFixed(0)} x $qty)',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      const Spacer(),

                      // ─── ปุ่ม qty ───
                      _qtyButton(
                        Icons.remove,
                        () =>
                            CartService.instance.updateQuantity(index, qty - 1),
                      ),
                      Container(
                        width: 36,
                        alignment: Alignment.center,
                        child: Text(
                          '$qty',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _qtyButton(
                        Icons.add,
                        () =>
                            CartService.instance.updateQuantity(index, qty + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ปุ่มลบ
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.red),
              onPressed: () => CartService.instance.removeFromCart(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.brown.shade200),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: Colors.brown),
      ),
    );
  }

  Widget _buildOrderSummary(List<Map<String, dynamic>> cart) {
    final totalItems = CartService.instance.getTotalItemCount();
    final totalPrice = CartService.instance.getTotalPrice();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // แถวสรุป
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalItems รายการ (${cart.length} เมนู)',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Row(
                children: [
                  const Text(
                    'ยอดรวม: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '฿${totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ปุ่มยืนยัน
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              onPressed: isSubmitting ? null : _submitOrder,
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ยืนยันการสั่งซื้อ $totalItems รายการ',
                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      color: Colors.brown[50],
      child: const Center(
        child: Icon(Icons.fastfood, color: Colors.brown, size: 28),
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ล้างตะกร้า'),
        content: const Text('ต้องการลบรายการทั้งหมดในตะกร้าใช่หรือไม่?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              CartService.instance.clearCart();
              Navigator.pop(context);
            },
            child: const Text(
              'ล้างตะกร้า',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
