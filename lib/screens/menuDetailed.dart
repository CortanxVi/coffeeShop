import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/cartService.dart';

class MenuDetailScreen extends StatefulWidget {
  final String menuId;
  final Map<String, dynamic> menuData;
  final int tableNo;

  const MenuDetailScreen({
    super.key,
    required this.menuId,
    required this.menuData,
    required this.tableNo,
  });

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  final _noteController = TextEditingController();
  int _quantity = 1;

  String _customerName = '';
  String _customerEmail = '';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// ดึงชื่อจาก Firestore users → fallback displayName → fallback email prefix
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _customerName = 'ลูกค้า';
        _isLoadingUser = false;
      });
      return;
    }

    _customerEmail = user.email ?? '';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String name = '';
      if (doc.exists) {
        final data = doc.data()!;
        name = (data['displayName'] ?? data['name'] ?? '').toString().trim();
      }

      if (name.isEmpty) name = user.displayName?.trim() ?? '';
      if (name.isEmpty && user.email != null) {
        name = user.email!.split('@').first;
      }
      if (name.isEmpty) name = 'ลูกค้า';

      setState(() {
        _customerName = name;
        _isLoadingUser = false;
      });
    } catch (_) {
      setState(() {
        _customerName = user.displayName?.trim().isNotEmpty == true
            ? user.displayName!
            : (user.email?.split('@').first ?? 'ลูกค้า');
        _isLoadingUser = false;
      });
    }
  }

  double get _totalPrice {
    final price = widget.menuData['price'] ?? 0;
    return price.toDouble() * _quantity;
  }

  void _addToCart() {
    CartService.instance.addToCart({
      'menuId': widget.menuId,
      'name': widget.menuData['name'] ?? 'ไม่ระบุ',
      'price': widget.menuData['price'] ?? 0,
      'imageUrl': widget.menuData['imageUrl'] ?? '',
      'quantity': _quantity,
      'customerName': _customerName,
      'note': _noteController.text.trim(),
      'tableNo': widget.tableNo,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'เพิ่ม ${_quantity}x ${widget.menuData['name']} ลงตะกร้าแล้ว!',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.menuData['name'] ?? 'ไม่ระบุ';
    final price = widget.menuData['price'] ?? 0;
    final imageUrl = widget.menuData['imageUrl'] ?? '';
    final category = widget.menuData['category'] ?? '';
    final description = widget.menuData['description'] ?? '';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(name),
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageHeader(imageUrl),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อและราคา
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '฿$price',
                          style: const TextStyle(
                            fontSize: 26,
                            color: Colors.brown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // หมวดหมู่
                    Chip(
                      label: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.brown,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.brown[50],
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                    ],

                    const Divider(height: 40),

                    // ── ข้อมูลผู้สั่ง (ดึงจาก Auth อัตโนมัติ) ──
                    const Text(
                      'ผู้สั่ง',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildUserInfoCard(),

                    const SizedBox(height: 24),

                    // จำนวน
                    const Text(
                      'จำนวนที่ต้องการ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuantitySelector(),

                    const SizedBox(height: 24),

                    // หมายเหตุ
                    const Text(
                      'หมายเหตุ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'เช่น หวานน้อย, ไม่ใส่น้ำแข็ง, ไม่ใส่กาแฟ',
                        prefixIcon: const Icon(Icons.edit_note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildAddToCartButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    if (_isLoadingUser) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.brown[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown.shade200),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('กำลังโหลดข้อมูลผู้ใช้...'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.brown,
            radius: 22,
            child: Text(
              _customerName.isNotEmpty ? _customerName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (_customerEmail.isNotEmpty)
                  Text(
                    _customerEmail,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, color: Colors.green, size: 13),
                SizedBox(width: 4),
                Text(
                  'เข้าสู่ระบบแล้ว',
                  style: TextStyle(color: Colors.green, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHeader(String url) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.brown[50],
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        _quantityBtn(Icons.remove, () {
          if (_quantity > 1) setState(() => _quantity--);
        }),
        Container(
          width: 60,
          alignment: Alignment.center,
          child: Text(
            '$_quantity',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        _quantityBtn(Icons.add, () => setState(() => _quantity++)),
        const SizedBox(width: 16),
        Text(
          'รวม ฿${_totalPrice.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 15,
            color: Colors.brown,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _quantityBtn(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.brown),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.brown, size: 20),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoadingUser
              ? Colors.brown.withOpacity(0.5)
              : Colors.brown,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
        ),
        onPressed: _isLoadingUser ? null : _addToCart,
        child: _isLoadingUser
            ? const Text(
                'กำลังโหลด...',
                style: TextStyle(fontSize: 18, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_shopping_cart, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'เพิ่มใส่ตะกร้า • ฿${_totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(Icons.restaurant_menu, size: 80, color: Colors.brown),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
