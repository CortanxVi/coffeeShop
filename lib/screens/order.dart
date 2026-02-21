import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  bool isGridView = false;

  // Cache เก็บข้อมูล menu ที่ดึงมาแล้ว เพื่อไม่ให้ query ซ้ำ
  final Map<String, Map<String, dynamic>> _menuCache = {};

  Future<void> updateOrderStatus(String docId) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'status': 'ready',
    });
  }

  // ดึงข้อมูล menu จาก menuId โดยใช้ cache
  Future<Map<String, dynamic>> _getMenuData(String menuId) async {
    if (_menuCache.containsKey(menuId)) {
      return _menuCache[menuId]!; // คืนจาก cache ถ้ามีแล้ว
    }

    final doc = await FirebaseFirestore.instance
        .collection('menu')
        .doc(menuId)
        .get();

    if (doc.exists) {
      _menuCache[menuId] = doc.data()!;
      return doc.data()!;
    }

    return {}; // ถ้าไม่เจอ menu
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการออร์เดอร์ (รอทำ)'),
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => isGridView = !isGridView),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.coffee_maker, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'ไม่มีออร์เดอร์ใหม่ขณะนี้',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return isGridView ? _buildGridView(docs) : _buildListView(docs);
        },
      ),
    );
  }

  // ============================================================
  // LIST VIEW
  // ============================================================
  Widget _buildListView(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final orderData = docs[index].data() as Map<String, dynamic>;
        final docId = docs[index].id;
        final menuId = orderData['menuId'] ?? '';

        // FutureBuilder ดึงข้อมูล menu ของแต่ละ order
        return FutureBuilder<Map<String, dynamic>>(
          future: _getMenuData(menuId),
          builder: (context, menuSnapshot) {
            // ระหว่างโหลด menu ให้แสดง skeleton
            if (menuSnapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text('กำลังโหลด...'),
                  subtitle: Text('-'),
                ),
              );
            }

            final menuData = menuSnapshot.data ?? {};
            // รวมข้อมูลจากทั้งสอง collection
            final menuName = menuData['name'] ?? 'ไม่ระบุเมนู';
            final price = menuData['price'] ?? 0;
            final imageUrl = menuData['imageUrl'];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                // แสดงรูปจาก menu (ถ้ามี) หรือแสดงเลขโต๊ะแทน
                leading: imageUrl != null
                    ? CircleAvatar(backgroundImage: NetworkImage(imageUrl))
                    : CircleAvatar(
                        backgroundColor: Colors.brown[100],
                        child: Text(orderData['tableNo']?.toString() ?? '-'),
                      ),
                title: Text(
                  menuName, // ← ชื่อเมนูจาก collection menu
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'ลูกค้า: ${orderData['customerName'] ?? '-'}  โต๊ะ: ${orderData['tableNo'] ?? '-'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('฿$price'), // ← ราคาจาก collection menu
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () =>
                          _showConfirmDialog(context, docId, menuName),
                      child: const Text(
                        'เสิร์ฟ',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                onTap: () => _showOrderDetail(context, orderData, menuData),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // GRID VIEW
  // ============================================================
  Widget _buildGridView(List<QueryDocumentSnapshot> docs) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final orderData = docs[index].data() as Map<String, dynamic>;
        final docId = docs[index].id;
        final menuId = orderData['menuId'] ?? '';

        return FutureBuilder<Map<String, dynamic>>(
          future: _getMenuData(menuId),
          builder: (context, menuSnapshot) {
            if (menuSnapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final menuData = menuSnapshot.data ?? {};
            final menuName = menuData['name'] ?? 'ไม่ระบุเมนู';
            final price = menuData['price'] ?? 0;

            return GestureDetector(
              onTap: () => _showOrderDetail(context, orderData, menuData),
              child: Card(
                color: Colors.brown[50],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'โต๊ะ ${orderData['tableNo'] ?? '-'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      menuName, // ← ชื่อเมนูจาก collection menu
                      style: const TextStyle(fontSize: 16, color: Colors.brown),
                    ),
                    Text(
                      '฿$price', // ← ราคาจาก collection menu
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onPressed: () =>
                          _showConfirmDialog(context, docId, menuName),
                      child: const Text(
                        'เสิร์ฟ',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DIALOGS
  // ============================================================
  void _showConfirmDialog(BuildContext context, String docId, String menuName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันออร์เดอร์'),
        content: Text('ทำรายการ "$menuName" เสร็จแล้วใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              updateOrderStatus(docId);
              Navigator.pop(context);
            },
            child: const Text(
              'ใช่, พร้อมเสิร์ฟ',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  // รับข้อมูลทั้ง orderData และ menuData แยกกัน
  void _showOrderDetail(
    BuildContext context,
    Map<String, dynamic> orderData,
    Map<String, dynamic> menuData,
  ) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('รายละเอียด: ${menuData['name'] ?? '-'}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ข้อมูลจาก collection menu
                Text(
                  'เมนู: ${menuData['name'] ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('ราคา: ${menuData['price'] ?? 0} บาท'),
                if (menuData['imageUrl'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Image.network(
                      menuData['imageUrl'],
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                const Divider(),
                // ข้อมูลจาก collection orders
                Text('ลูกค้า: ${orderData['customerName'] ?? '-'}'),
                Text('โต๊ะ: ${orderData['tableNo'] ?? '-'}'),
                Text('สถานะ: ${orderData['status'] ?? '-'}'),
                Text('หมายเหตุ: ${orderData['note'] ?? '-'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
