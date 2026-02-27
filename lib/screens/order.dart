import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  bool isGridView = false;
  final Map<String, Map<String, dynamic>> _menuCache = {};

  // เปลี่ยน status → ready (กดเสิร์ฟ)
  Future<void> updateOrderStatus(String docId) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'status': 'ready',
    });
  }

  // เปลี่ยน status → paid และบันทึก timestamp
  Future<void> markAsPaid(String docId) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

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
        title: const Text('รายการออร์เดอร์'),
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
        // แสดงทั้ง pending และ ready
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', whereIn: ['pending', 'ready'])
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
                    'ไม่มีออร์เดอร์ขณะนี้',
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
        final status = orderData['status'] ?? 'pending';

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

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              // แสดงสีต่างกันตาม status
              color: status == 'ready' ? Colors.green[50] : Colors.white,
              child: ListTile(
                leading: imageUrl != null
                    ? CircleAvatar(backgroundImage: NetworkImage(imageUrl))
                    : CircleAvatar(
                        backgroundColor: Colors.brown[100],
                        child: Text(orderData['tableNo']?.toString() ?? '-'),
                      ),
                title: Text(
                  menuName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ลูกค้า: ${orderData['customerName'] ?? '-'}  โต๊ะ: ${orderData['tableNo'] ?? '-'}',
                    ),
                    _StatusChip(status: status),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('฿$price'),
                    const SizedBox(width: 8),
                    // แสดงปุ่มตาม status
                    if (status == 'pending')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: () =>
                            _showConfirmServeDialog(context, docId, menuName),
                        child: const Text(
                          'เสิร์ฟ',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    else if (status == 'ready')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () =>
                            _showPaymentDialog(context, docId, menuName, price),
                        child: const Text(
                          'ชำระเงิน',
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
        childAspectRatio: 0.95,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final orderData = docs[index].data() as Map<String, dynamic>;
        final docId = docs[index].id;
        final menuId = orderData['menuId'] ?? '';
        final status = orderData['status'] ?? 'pending';

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
                color: status == 'ready' ? Colors.green[50] : Colors.brown[50],
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
                      menuName,
                      style: const TextStyle(fontSize: 14, color: Colors.brown),
                      textAlign: TextAlign.center,
                    ),
                    Text('฿$price', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    _StatusChip(status: status),
                    const SizedBox(height: 8),
                    if (status == 'pending')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () =>
                            _showConfirmServeDialog(context, docId, menuName),
                        child: const Text(
                          'เสิร์ฟ',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    else if (status == 'ready')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () =>
                            _showPaymentDialog(context, docId, menuName, price),
                        child: const Text(
                          'ชำระเงิน',
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

  // Dialog ยืนยันเสิร์ฟ
  void _showConfirmServeDialog(
    BuildContext context,
    String docId,
    String menuName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการเสิร์ฟ'),
        content: Text('เสิร์ฟ "$menuName" เรียบร้อยแล้วใช่หรือไม่?'),
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
              'ใช่, เสิร์ฟแล้ว',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog QR Payment
  void _showPaymentDialog(
    BuildContext context,
    String docId,
    String menuName,
    dynamic price,
  ) {
    // สร้าง payload สำหรับ PromptPay QR (หรือใส่ลิงก์ payment gateway)
    // ตัวอย่างใช้ PromptPay format: พร้อมเพย์หมายเลขโทรศัพท์
    const promptPayId = '0812345678'; // ← เปลี่ยนเป็นหมายเลขพร้อมเพย์ของร้าน
    final qrData =
        'promptpay:$promptPayId?amount=$price'; // หรือใช้ format PromptPay EMVCo จริง

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PaymentDialog(
        docId: docId,
        menuName: menuName,
        price: price,
        qrData: qrData,
        onPaymentConfirmed: () async {
          await markAsPaid(docId);
        },
      ),
    );
  }

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

// ============================================================
// Payment Dialog Widget
// ============================================================
class _PaymentDialog extends StatefulWidget {
  final String docId;
  final String menuName;
  final dynamic price;
  final String qrData;
  final Future<void> Function() onPaymentConfirmed;

  const _PaymentDialog({
    required this.docId,
    required this.menuName,
    required this.price,
    required this.qrData,
    required this.onPaymentConfirmed,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  bool _isPaying = false;
  bool _isPaid = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.qr_code, color: Colors.green),
          const SizedBox(width: 8),
          const Text('ชำระเงิน'),
        ],
      ),
      content: SizedBox(
        width: 280,
        child: _isPaid ? _buildSuccessView() : _buildQRView(),
      ),
      actions: _isPaid
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ปิด'),
              ),
            ]
          : [
              TextButton(
                onPressed: _isPaying ? null : () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _isPaying ? null : _confirmPayment,
                child: _isPaying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'ยืนยันชำระแล้ว',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
    );
  }

  Widget _buildQRView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.menuName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          '฿${widget.price}',
          style: const TextStyle(
            fontSize: 24,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // QR Code
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: QrImageView(
            data: widget.qrData,
            version: QrVersions.auto,
            size: 200,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'สแกน QR Code เพื่อชำระเงิน',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const Text(
          '(PromptPay)',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.check_circle, color: Colors.green, size: 80),
        SizedBox(height: 12),
        Text(
          'ชำระเงินสำเร็จ!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'รายการถูกย้ายไปยัง History แล้ว',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _confirmPayment() async {
    setState(() => _isPaying = true);
    await widget.onPaymentConfirmed();
    setState(() {
      _isPaying = false;
      _isPaid = true;
    });
  }
}

// ============================================================
// Status Chip
// ============================================================
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'pending'
        ? Colors.orange
        : status == 'ready'
        ? Colors.green
        : Colors.blue;
    final label = status == 'pending'
        ? 'รอทำ'
        : status == 'ready'
        ? 'พร้อมเสิร์ฟ'
        : 'ชำระแล้ว';
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
