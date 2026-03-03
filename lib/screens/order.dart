import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:a/service/paymentdialog.dart';

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

  /// คืนค่าราคาต่อหน่วยจาก orderData ก่อน ถ้าไม่มีค่อย fallback จาก menuData
  double _unitPrice(
    Map<String, dynamic> orderData,
    Map<String, dynamic> menuData,
  ) {
    if (orderData['price'] != null) {
      return (orderData['price'] as num).toDouble();
    }
    return (menuData['price'] ?? 0 as num).toDouble();
  }

  /// คืนจำนวนสินค้า (quantity) จาก orderData
  int _qty(Map<String, dynamic> orderData) =>
      (orderData['quantity'] ?? 1) as int;

  /// คืนยอดรวมของออเดอร์นี้
  double _totalPrice(
    Map<String, dynamic> orderData,
    Map<String, dynamic> menuData,
  ) {
    if (orderData['totalPrice'] != null) {
      return (orderData['totalPrice'] as num).toDouble();
    }
    return _unitPrice(orderData, menuData) * _qty(orderData);
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: ListTile(
                  title: Text('กำลังโหลด...'),
                  leading: CircleAvatar(child: CircularProgressIndicator()),
                ),
              );
            }
            final menuData = menuSnapshot.data ?? {};
            // ชื่อเมนู: ดึงจาก orderData ก่อน (บันทึกตอนสั่ง) → fallback menuData
            final menuName =
                (orderData['menuName']?.toString().isNotEmpty == true
                    ? orderData['menuName']
                    : menuData['name']) ??
                'ไม่ระบุเมนู';
            final imageUrl =
                orderData['imageUrl']?.toString().isNotEmpty == true
                ? orderData['imageUrl']
                : menuData['imageUrl'];
            final qty = _qty(orderData);
            final unitP = _unitPrice(orderData, menuData);
            final totalP = _totalPrice(orderData, menuData);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: status == 'ready' ? Colors.green[50] : Colors.white,
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showOrderDetail(context, orderData, menuData),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // รูปภาพ
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child:
                              imageUrl != null && imageUrl.toString().isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _imgPlaceholder(
                                    orderData['tableNo']?.toString() ?? '-',
                                  ),
                                )
                              : _imgPlaceholder(
                                  orderData['tableNo']?.toString() ?? '-',
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ข้อมูลออเดอร์
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ชื่อเมนู + qty badge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    menuName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                // ── qty badge ──
                                if (qty > 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.brown[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'x$qty',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.brown,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // ลูกค้า + โต๊ะ
                            Text(
                              '👤 ${orderData['customerName'] ?? '-'}  •  🪑 โต๊ะ ${orderData['tableNo'] ?? '-'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),

                            // หมายเหตุ
                            if (orderData['note'] != null &&
                                orderData['note'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '📝 ${orderData['note']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 6),

                            // สถานะ + ราคา + ปุ่ม
                            Row(
                              children: [
                                _StatusChip(status: status),
                                const Spacer(),

                                // ราคา
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '฿${totalP.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.brown,
                                      ),
                                    ),
                                    if (qty > 1)
                                      Text(
                                        '฿${unitP.toStringAsFixed(0)} x $qty',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 8),

                                // ปุ่ม action
                                if (status == 'pending')
                                  _ActionButton(
                                    label: 'เสิร์ฟ',
                                    color: Colors.orange,
                                    onPressed: () => _showConfirmServeDialog(
                                      context,
                                      docId,
                                      menuName,
                                    ),
                                  )
                                else if (status == 'ready')
                                  _ActionButton(
                                    label: 'ชำระเงิน',
                                    color: Colors.green,
                                    onPressed: () => _showPaymentDialog(
                                      context,
                                      docId,
                                      menuName,
                                      totalP,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
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
  // GRID VIEW
  // ============================================================
  Widget _buildGridView(List<QueryDocumentSnapshot> docs) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
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
            final menuName =
                (orderData['menuName']?.toString().isNotEmpty == true
                    ? orderData['menuName']
                    : menuData['name']) ??
                'ไม่ระบุเมนู';
            final qty = _qty(orderData);
            final totalP = _totalPrice(orderData, menuData);

            return GestureDetector(
              onTap: () => _showOrderDetail(context, orderData, menuData),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: status == 'ready' ? Colors.green[50] : Colors.brown[50],
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // โต๊ะ + qty
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'โต๊ะ ${orderData['tableNo'] ?? '-'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (qty > 1) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.brown,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'x$qty',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // ชื่อเมนู
                      Text(
                        menuName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.brown,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // ชื่อลูกค้า
                      Text(
                        orderData['customerName'] ?? '-',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // ราคา
                      Text(
                        '฿${totalP.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.brown,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),

                      _StatusChip(status: status),
                      const SizedBox(height: 8),

                      if (status == 'pending')
                        _ActionButton(
                          label: 'เสิร์ฟ',
                          color: Colors.orange,
                          onPressed: () =>
                              _showConfirmServeDialog(context, docId, menuName),
                        )
                      else if (status == 'ready')
                        _ActionButton(
                          label: 'ชำระเงิน',
                          color: Colors.green,
                          onPressed: () => _showPaymentDialog(
                            context,
                            docId,
                            menuName,
                            totalP,
                          ),
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
  // DIALOGS
  // ============================================================
  void _showConfirmServeDialog(
    BuildContext context,
    String docId,
    String menuName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  void _showOrderDetail(
    BuildContext context,
    Map<String, dynamic> orderData,
    Map<String, dynamic> menuData,
  ) {
    final qty = _qty(orderData);
    final unitP = _unitPrice(orderData, menuData);
    final totalP = _totalPrice(orderData, menuData);
    final menuName =
        (orderData['menuName']?.toString().isNotEmpty == true
            ? orderData['menuName']
            : menuData['name']) ??
        '-';
    final imageUrl = orderData['imageUrl']?.toString().isNotEmpty == true
        ? orderData['imageUrl']
        : menuData['imageUrl'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                decoration: const BoxDecoration(
                  color: Colors.brown,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                        menuName,
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

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // รูปภาพ
                      if (imageUrl != null && imageUrl.toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrl,
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
                      if (imageUrl != null && imageUrl.toString().isNotEmpty)
                        const SizedBox(height: 14),

                      // ── ข้อมูลเมนู ──
                      _detailSection(
                        icon: Icons.coffee,
                        color: Colors.brown,
                        title: 'ข้อมูลเมนู',
                        children: [
                          _detailRow('ชื่อเมนู', menuName),
                          _detailRow(
                            'ราคา/ชิ้น',
                            '฿${unitP.toStringAsFixed(0)}',
                            valueColor: Colors.brown,
                          ),
                          _detailRow(
                            'จำนวน',
                            '$qty ชิ้น',
                            valueColor: Colors.brown,
                            bold: true,
                          ),
                          _detailRow(
                            'ยอดรวม',
                            '฿${totalP.toStringAsFixed(0)}',
                            valueColor: Colors.green[700],
                            bold: true,
                          ),
                          if (menuData['category'] != null)
                            _detailRow('หมวดหมู่', menuData['category'] ?? '-'),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── ข้อมูลออเดอร์ ──
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

              // Footer
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

  // ── Helpers ──
  Widget _imgPlaceholder(String tableText) {
    return Container(
      color: Colors.brown[100],
      child: Center(
        child: Text(
          tableText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
      ),
    );
  }

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

// ============================================================
// ACTION BUTTON (เสิร์ฟ / ชำระเงิน)
// ============================================================
class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
