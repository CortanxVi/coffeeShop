import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isGridView = false;
  final Map<String, Map<String, dynamic>> _menuCache = {};

  Future<Map<String, dynamic>> _getMenuData(String menuId) async {
    if (_menuCache.containsKey(menuId)) return _menuCache[menuId]!;
    final doc = await FirebaseFirestore.instance
        .collection('menu')
        .doc(menuId)
        .get();
    if (doc.exists) {
      _menuCache[menuId] = doc.data()!;
      return doc.data()!;
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการสั่งซื้อ'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
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
            .where(
              'status',
              isEqualTo: 'paid',
            ) // ← ใช้แค่ where อย่างเดียว ไม่มี orderBy
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
                  Icon(Icons.history, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'ยังไม่มีประวัติการสั่งซื้อ',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Sort ใน client-side แทน orderBy ใน query เพื่อไม่ต้องสร้าง index
          final docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['paidAt'];
            final bTime = bData['paidAt'];
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return (bTime as Timestamp).compareTo(
              aTime as Timestamp,
            ); // ล่าสุดก่อน
          });

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
        final menuId = orderData['menuId'] ?? '';

        return FutureBuilder<Map<String, dynamic>>(
          future: _getMenuData(menuId),
          builder: (context, menuSnapshot) {
            if (menuSnapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(title: Text('กำลังโหลด...')),
              );
            }

            final menuData = menuSnapshot.data ?? {};
            final menuName = menuData['name'] ?? 'ไม่ระบุเมนู';
            final price = menuData['price'] ?? 0;
            final imageUrl = menuData['imageUrl'];
            final paidAt = orderData['paidAt'] as Timestamp?;
            final paidDate = paidAt != null
                ? _formatDate(paidAt.toDate())
                : '-';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: imageUrl != null
                    ? CircleAvatar(backgroundImage: NetworkImage(imageUrl))
                    : CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: const Icon(Icons.check, color: Colors.green),
                      ),
                title: Text(
                  menuName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'โต๊ะ: ${orderData['tableNo'] ?? '-'}  |  ลูกค้า: ${orderData['customerName'] ?? '-'}',
                    ),
                    Text(
                      paidDate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: Text(
                  '฿$price',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
                onTap: () => _showHistoryDetail(context, orderData, menuData),
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
        childAspectRatio: 0.85, // ← ลดลงให้ card สูงขึ้น
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final orderData = docs[index].data() as Map<String, dynamic>;
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
            final paidAt = orderData['paidAt'] as Timestamp?;
            final paidDate = paidAt != null
                ? _formatDate(paidAt.toDate())
                : '-';

            return GestureDetector(
              onTap: () => _showHistoryDetail(context, orderData, menuData),
              child: Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // ← สำคัญมาก
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'โต๊ะ ${orderData['tableNo'] ?? '-'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        menuName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.brown,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '฿$price',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        paidDate,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DIALOG รายละเอียด
  // ============================================================
  void _showHistoryDetail(
    BuildContext context,
    Map<String, dynamic> orderData,
    Map<String, dynamic> menuData,
  ) {
    final paidAt = orderData['paidAt'] as Timestamp?;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          // ← กำหนดขนาดสูงสุด
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: SingleChildScrollView(
            // ← ให้ scroll ได้ถ้าเนื้อหายาว
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // ← สำคัญมาก
                children: [
                  Text(
                    menuData['name'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('ราคา: ${menuData['price'] ?? 0} บาท'),
                  if (menuData['imageUrl'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          menuData['imageUrl'],
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const Divider(),
                  Text('ลูกค้า: ${orderData['customerName'] ?? '-'}'),
                  Text('โต๊ะ: ${orderData['tableNo'] ?? '-'}'),
                  Text('หมายเหตุ: ${orderData['note'] ?? '-'}'),
                  const Divider(),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ชำระเงินเมื่อ: ${paidAt != null ? _formatDate(paidAt.toDate()) : '-'}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ปิด'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
