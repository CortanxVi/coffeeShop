import 'package:flutter/material.dart';

// ข้อมูลจำลองแทน Firebase
final List<Map<String, dynamic>> mockOrders = [
  {
    'docId': 'order001',
    'menuId': 'menu001',
    'customerName': 'คุณสมชาย',
    'tableNo': 1,
    'status': 'pending',
    'note': 'ไม่ใส่น้ำตาล',
    // ข้อมูลจาก menu (จำลองการ join)
    'menuName': 'อเมริกาโน่',
    'price': 65,
  },
  {
    'docId': 'order002',
    'menuId': 'menu002',
    'customerName': 'คุณสมหญิง',
    'tableNo': 3,
    'status': 'pending',
    'note': '',
    'menuName': 'ลาเต้',
    'price': 75,
  },
  {
    'docId': 'order003',
    'menuId': 'menu001',
    'customerName': 'คุณมานี',
    'tableNo': 5,
    'status': 'pending',
    'note': 'หวานน้อย',
    'menuName': 'อเมริกาโน่',
    'price': 65,
  },
];

class MockOrderScreen extends StatefulWidget {
  const MockOrderScreen({super.key});

  @override
  State<MockOrderScreen> createState() => _MockOrderScreenState();
}

class _MockOrderScreenState extends State<MockOrderScreen> {
  bool isGridView = false;

  // จำลอง List ที่เปลี่ยนได้ (แทน Firebase stream)
  List<Map<String, dynamic>> orders = List.from(mockOrders);

  // จำลอง updateOrderStatus → เปลี่ยน status ใน List แทน
  void mockUpdateStatus(String docId) {
    setState(() {
      orders.removeWhere((o) => o['docId'] == docId); // หายออกจากหน้าจอ
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ อัปเดตสถานะ order $docId เป็น ready แล้ว'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mock Test (${orders.length} รายการ)'),
        actions: [
          // ปุ่ม Reset กลับมาทดสอบใหม่
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset ข้อมูล',
            onPressed: () {
              setState(() {
                orders = List.from(mockOrders);
              });
            },
          ),
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => isGridView = !isGridView),
          ),
        ],
      ),
      body: orders.isEmpty
          ? const Center(
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
            )
          : isGridView
          ? _buildGridView()
          : _buildListView(),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.brown[100],
              child: Text(order['tableNo'].toString()),
            ),
            title: Text(
              order['menuName'], // ← ชื่อจาก menu
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'ลูกค้า: ${order['customerName']}  โต๊ะ: ${order['tableNo']}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('฿${order['price']}'),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () =>
                      _showConfirmDialog(order['docId'], order['menuName']),
                  child: const Text(
                    'เสิร์ฟ',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            onTap: () => _showOrderDetail(order),
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return GestureDetector(
          onTap: () => _showOrderDetail(order),
          child: Card(
            color: Colors.brown[50],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'โต๊ะ ${order['tableNo']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order['menuName'],
                  style: const TextStyle(fontSize: 16, color: Colors.brown),
                ),
                Text(
                  '฿${order['price']}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onPressed: () =>
                      _showConfirmDialog(order['docId'], order['menuName']),
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
  }

  void _showConfirmDialog(String docId, String menuName) {
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
              Navigator.pop(context);
              mockUpdateStatus(docId); // ← จำลองการ update
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

  void _showOrderDetail(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('รายละเอียด: ${order['menuName']}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เมนู: ${order['menuName']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('ราคา: ${order['price']} บาท'),
                const Divider(),
                Text('ลูกค้า: ${order['customerName']}'),
                Text('โต๊ะ: ${order['tableNo']}'),
                Text('สถานะ: ${order['status']}'),
                Text(
                  'หมายเหตุ: ${order['note'].isEmpty ? '-' : order['note']}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
