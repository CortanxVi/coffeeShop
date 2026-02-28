import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'menuDetailed.dart';

class HomeScreen extends StatefulWidget {
  final int tableNo;
  const HomeScreen({super.key, required this.tableNo});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'ทั้งหมด';
  bool isGridView = true;

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase().trim()) {
      case 'coffee':
        return Icons.coffee;
      case 'non-coffee':
        return Icons.local_drink;
      case 'food':
        return Icons.restaurant;
      case 'ทั้งหมด':
        return Icons.apps;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เมนู - โต๊ะ ${widget.tableNo}'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => isGridView = !isGridView),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── เนื้อหาหลัก ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('menu').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDocs = snapshot.data?.docs ?? [];

              // ดึง category จาก Firestore จริง
              final Set<String> rawCategories = {};
              for (final doc in allDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final cat = (data['category'] ?? '').toString().trim();
                if (cat.isNotEmpty) rawCategories.add(cat);
              }
              final categories = ['ทั้งหมด', ...rawCategories.toList()..sort()];

              // กรองตาม category
              final filteredDocs = selectedCategory == 'ทั้งหมด'
                  ? allDocs
                  : allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final cat = (data['category'] ?? '')
                          .toString()
                          .trim()
                          .toLowerCase();
                      return cat == selectedCategory.toLowerCase();
                    }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChoiceChips(categories, allDocs),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Text(
                      'แสดง ${filteredDocs.length} รายการ',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: filteredDocs.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'ไม่มีเมนูในหมวดนี้',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : isGridView
                        ? _buildGrid(filteredDocs)
                        : _buildList(filteredDocs),
                  ),
                ],
              );
            },
          ),

          // ── Notification Listener (ไม่แสดง UI แต่ฟัง Firestore) ──
          _OrderNotificationListener(tableNo: widget.tableNo),
        ],
      ),
    );
  }

  // ============================================================
  // CHOICE CHIPS
  // ============================================================
  Widget _buildChoiceChips(
    List<String> categories,
    List<QueryDocumentSnapshot> allDocs,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat;
          final count = cat == 'ทั้งหมด'
              ? allDocs.length
              : allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final docCat = (data['category'] ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();
                  return docCat == cat.toLowerCase();
                }).length;

          return ChoiceChip(
            avatar: Icon(
              _getCategoryIcon(cat),
              size: 16,
              color: isSelected ? Colors.white : Colors.brown,
            ),
            label: Text('$cat ($count)'),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.brown,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            selected: isSelected,
            selectedColor: Colors.brown,
            backgroundColor: Colors.brown[50],
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? Colors.brown : Colors.brown.shade200,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            onSelected: (_) => setState(() => selectedCategory = cat),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // GRID VIEW
  // ============================================================
  Widget _buildGrid(List<QueryDocumentSnapshot> menuList) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: menuList.length,
      itemBuilder: (context, index) {
        final data = menuList[index].data() as Map<String, dynamic>;
        final menuId = menuList[index].id;
        return _buildGridCard(menuId, data);
      },
    );
  }

  Widget _buildGridCard(String menuId, Map<String, dynamic> data) {
    final imageUrl = data['imageUrl'] ?? '';
    final name = data['name'] ?? 'ไม่ระบุ';
    final price = data['price'] ?? 0;
    final category = (data['category'] ?? '').toString().trim();
    final isPopular = data['isPopular'] == true;

    return GestureDetector(
      onTap: () => _goToDetail(menuId, data),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รูปภาพ + badge ยอดนิยม
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  // ── Badge ยอดนิยม ──
                  if (isPopular)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '⭐ ยอดนิยม',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ข้อมูลด้านล่าง
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '฿$price',
                        style: const TextStyle(
                          color: Colors.brown,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.brown[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.brown,
                          ),
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
    );
  }

  // ============================================================
  // LIST VIEW
  // ============================================================
  Widget _buildList(List<QueryDocumentSnapshot> menuList) {
    return ListView.builder(
      itemCount: menuList.length,
      itemBuilder: (context, index) {
        final data = menuList[index].data() as Map<String, dynamic>;
        final menuId = menuList[index].id;
        return _buildListCard(menuId, data);
      },
    );
  }

  Widget _buildListCard(String menuId, Map<String, dynamic> data) {
    final imageUrl = data['imageUrl'] ?? '';
    final name = data['name'] ?? 'ไม่ระบุ';
    final price = data['price'] ?? 0;
    final category = (data['category'] ?? '').toString().trim();
    final isPopular = data['isPopular'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _goToDetail(menuId, data),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            // ── Badge ยอดนิยม (มุมบนขวาของรูป) ──
            if (isPopular)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('⭐', style: TextStyle(fontSize: 10)),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isPopular)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ยอดนิยม',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Text(
          category,
          style: const TextStyle(color: Colors.brown, fontSize: 12),
        ),
        trailing: Text(
          '฿$price',
          style: const TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPER
  // ============================================================
  Widget _placeholder() {
    return Container(
      color: Colors.brown[50],
      child: const Center(
        child: Icon(Icons.coffee, size: 40, color: Colors.brown),
      ),
    );
  }

  void _goToDetail(String menuId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuDetailScreen(
          menuId: menuId,
          menuData: data,
          tableNo: widget.tableNo,
        ),
      ),
    );
  }
}

// ============================================================
// ORDER NOTIFICATION LISTENER
// วางไว้ใน Stack ของ HomeScreen — ฟัง Firestore แบบ real-time
// เมื่อ order ของ user นี้เปลี่ยนเป็น 'ready' → popup แจ้งเตือน
// ============================================================
class _OrderNotificationListener extends StatefulWidget {
  final int tableNo;
  const _OrderNotificationListener({required this.tableNo});

  @override
  State<_OrderNotificationListener> createState() =>
      _OrderNotificationListenerState();
}

class _OrderNotificationListenerState
    extends State<_OrderNotificationListener> {
  // เก็บ docId ที่แจ้งเตือนไปแล้ว ป้องกัน popup ซ้ำ
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
          .where('notified', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          for (final doc in snapshot.data!.docs) {
            final docId = doc.id;
            if (!_notifiedIds.contains(docId)) {
              _notifiedIds.add(docId);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showReadyDialog(doc);
              });
            }
          }
        }
        // widget นี้ไม่แสดง UI ใดๆ
        return const SizedBox.shrink();
      },
    );
  }

  void _showReadyDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // ดึงชื่อเมนูจาก cache หรือ Firestore
    FirebaseFirestore.instance
        .collection('menu')
        .doc(data['menuId'] ?? '')
        .get()
        .then((menuDoc) {
          final menuName =
              (menuDoc.data() as Map<String, dynamic>?)?['name'] ??
              'อาหารของคุณ';

          if (!mounted) return;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.room_service, color: Colors.green, size: 28),
                  SizedBox(width: 8),
                  Text('พร้อมเสิร์ฟแล้ว!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 72),
                  const SizedBox(height: 12),
                  Text(
                    menuName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'โต๊ะ ${data['tableNo'] ?? widget.tableNo}',
                    style: const TextStyle(fontSize: 16, color: Colors.brown),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'อาหารของคุณพร้อมรับได้แล้วครับ/ค่ะ',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // mark notified = true → ป้องกัน popup ซ้ำ
                      FirebaseFirestore.instance
                          .collection('orders')
                          .doc(doc.id)
                          .update({'notified': true});
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'รับทราบ ขอบคุณครับ/ค่ะ',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }
}
