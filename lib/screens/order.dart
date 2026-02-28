import 'package:a/service/paymentdialog.dart';
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

  Future<void> updateOrderStatus(String docId) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'status': 'ready',
    });
  }

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
            final price = (menuData['price'] ?? 0).toDouble();
            final imageUrl = menuData['imageUrl'];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: status == 'ready' ? Colors.green[50] : Colors.white,
              child: ListTile(
                leading: imageUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(imageUrl),
                        onBackgroundImageError: (_, __) {},
                      )
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
                    const SizedBox(height: 4),
                    _StatusChip(status: status),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '฿${price.toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
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
            final price = (menuData['price'] ?? 0).toDouble();

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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        menuName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.brown,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '฿${price.toInt()}',
                      style: const TextStyle(color: Colors.grey),
                    ),
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

  // Dialog QR Payment (จำลอง)
  void _showPaymentDialog(
    BuildContext context,
    String docId,
    String menuName,
    double price,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OmisePaymentDialog(
        docId: docId,
        menuName: menuName,
        price: price,
        onPaymentConfirmed: () => markAsPaid(docId),
      ),
    );
  }

  // Dialog รายละเอียด order
  void _showOrderDetail(
    BuildContext context,
    Map<String, dynamic> orderData,
    Map<String, dynamic> menuData,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                decoration: BoxDecoration(
                  color: Colors.brown,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        menuData['name'] ?? '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // ── Content ──
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // รูปภาพ (ถ้ามี)
                      if (menuData['imageUrl'] != null &&
                          menuData['imageUrl'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            menuData['imageUrl'],
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 80,
                              color: Colors.brown[50],
                              child: const Center(
                                child: Icon(
                                  Icons.coffee,
                                  color: Colors.brown,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (menuData['imageUrl'] != null &&
                          menuData['imageUrl'].toString().isNotEmpty)
                        const SizedBox(height: 14),

                      // ── ข้อมูลเมนู ──
                      _detailSection(
                        icon: Icons.coffee,
                        color: Colors.brown,
                        title: 'ข้อมูลเมนู',
                        children: [
                          _detailRow('ชื่อเมนู', menuData['name'] ?? '-'),
                          _detailRow(
                            'ราคา',
                            '฿${menuData['price'] ?? 0}',
                            valueColor: Colors.brown,
                            bold: true,
                          ),
                          if (menuData['category'] != null)
                            _detailRow('หมวดหมู่', menuData['category'] ?? '-'),
                          if (menuData['description'] != null &&
                              menuData['description'].toString().isNotEmpty)
                            _detailRow(
                              'คำอธิบาย',
                              menuData['description'] ?? '-',
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── ข้อมูลออร์เดอร์ ──
                      _detailSection(
                        icon: Icons.person,
                        color: Colors.blue,
                        title: 'ข้อมูลการสั่ง',
                        children: [
                          _detailRow(
                            'ลูกค้า',
                            orderData['customerName'] ?? '-',
                          ),
                          _detailRow('โต๊ะ', '${orderData['tableNo'] ?? '-'}'),
                          _detailRow(
                            'สถานะ',
                            _statusLabel(orderData['status'] ?? ''),
                            valueColor: _statusColor(orderData['status'] ?? ''),
                            bold: true,
                          ),
                          if (orderData['note'] != null &&
                              orderData['note'].toString().isNotEmpty)
                            _detailRow('หมายเหตุ', orderData['note'] ?? '-'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Footer ปุ่มปิด ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'ปิด',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper: กล่อง Section ──
  Widget _detailSection({
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  // ── Helper: แถวข้อมูล ──
  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? Colors.black87,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: แปลง status เป็นข้อความ ──
  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return '🕐 รอทำ';
      case 'ready':
        return '✅ พร้อมเสิร์ฟ';
      case 'paid':
        return '💳 ชำระแล้ว';
      default:
        return status;
    }
  }

  // ── Helper: สีตาม status ──
  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      case 'paid':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// ============================================================
// PAYMENT DIALOG — QR จำลอง
// ============================================================
class _PaymentDialog extends StatefulWidget {
  final String docId;
  final String menuName;
  final double price;
  final Future<void> Function() onPaymentConfirmed;

  const _PaymentDialog({
    required this.docId,
    required this.menuName,
    required this.price,
    required this.onPaymentConfirmed,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  bool _isPaying = false;
  bool _isPaid = false;

  // QR Data จำลอง — ใส่ข้อมูลร้านและ order ให้ดูสมจริง
  String get _mockQrData {
    final ref = 'REF${DateTime.now().millisecondsSinceEpoch}';
    return 'STORE=WanWanCafe|ITEM=${widget.menuName}|AMT=${widget.price.toStringAsFixed(2)}|CCY=THB|$ref';
  }

  Future<void> _confirmPayment() async {
    setState(() => _isPaying = true);
    await widget.onPaymentConfirmed();
    if (mounted) {
      setState(() {
        _isPaying = false;
        _isPaid = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      title: Row(
        children: [
          Icon(
            _isPaid ? Icons.check_circle : Icons.qr_code_2,
            color: _isPaid ? Colors.green : Colors.brown,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(_isPaid ? 'ชำระเงินสำเร็จ' : 'ชำระเงิน'),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: _isPaid ? _buildSuccessView() : _buildQRView(),
      ),
      actions: _isPaid
          ? [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'ปิด',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ]
          : [
              TextButton(
                onPressed: _isPaying ? null : () => Navigator.pop(context),
                child: const Text(
                  'ยกเลิก',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                        'ยืนยันรับเงินแล้ว',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
    );
  }

  // ── QR View ──
  Widget _buildQRView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ชื่อเมนูและราคา
          Text(
            widget.menuName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '฿${widget.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),

          // QR Code กล่อง
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Logo ร้านบน QR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.coffee, color: Colors.brown, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'WanWan Cafe',
                      style: TextStyle(
                        color: Colors.brown[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // QR Code
                QrImageView(
                  data: _mockQrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                  errorStateBuilder: (context, error) => const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: Text(
                        'ไม่สามารถสร้าง QR ได้',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  'สแกนเพื่อชำระเงิน',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Badge Demo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 13, color: Colors.orange),
                SizedBox(width: 5),
                Text(
                  'Demo Mode — QR จำลอง',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'กด "ยืนยันรับเงินแล้ว" เพื่อจบรายการ',
            style: TextStyle(color: Colors.grey, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Success View ──
  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated check
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 72,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ชำระเงินสำเร็จ!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.menuName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '฿${widget.price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'รายการถูกย้ายไปยัง History แล้ว',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STATUS CHIP
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
        ? '🕐 รอทำ'
        : status == 'ready'
        ? '✅ พร้อมเสิร์ฟ'
        : '💳 ชำระแล้ว';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
