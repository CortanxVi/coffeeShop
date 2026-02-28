import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Widget นี้ฟัง Firestore แบบ real-time
// เมื่อ order ของ user นี้เปลี่ยนเป็น 'ready' → แสดง popup แจ้งเตือน
class _OrderNotificationListener extends StatefulWidget {
  final int tableNo;
  const _OrderNotificationListener({required this.tableNo});

  @override
  State<_OrderNotificationListener> createState() =>
      _OrderNotificationListenerState();
}

class _OrderNotificationListenerState
    extends State<_OrderNotificationListener> {
  // เก็บ docId ที่แจ้งเตือนไปแล้ว ไม่ให้ popup ซ้ำ
  final Set<String> _notifiedIds = {};

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'ready')
          .where('notified', isEqualTo: false) // ← ยังไม่ได้แจ้ง
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          for (final doc in snapshot.data!.docs) {
            final docId = doc.id;
            if (!_notifiedIds.contains(docId)) {
              _notifiedIds.add(docId);
              // delay เล็กน้อยให้ widget build เสร็จก่อน
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showReadyDialog(doc);
              });
            }
          }
        }
        return const SizedBox.shrink(); // widget นี้ไม่แสดง UI
      },
    );
  }

  void _showReadyDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.room_service, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('อาหารพร้อมเสิร์ฟ!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 12),
            Text(
              'โต๊ะ ${data['tableNo'] ?? '-'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'ออร์เดอร์ของคุณพร้อมรับแล้ว!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              // mark notified = true ใน Firestore ไม่ให้ popup ซ้ำ
              FirebaseFirestore.instance
                  .collection('orders')
                  .doc(doc.id)
                  .update({'notified': true});
              Navigator.pop(context);
            },
            child: const Text('รับทราบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
