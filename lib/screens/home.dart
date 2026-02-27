import 'package:a/screens/menuDetailed.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menu').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];

          // ดึง category จาก Firestore จริง (lowercase + trim เพื่อกัน typo)
          final Set<String> rawCategories = {};
          for (final doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final cat = (data['category'] ?? '').toString().trim();
            if (cat.isNotEmpty) rawCategories.add(cat);
          }
          final categories = ['ทั้งหมด', ...rawCategories.toList()..sort()];

          // กรองโดยเปรียบเทียบแบบ case-insensitive
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
              // แสดงจำนวนรายการที่กรองได้
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
        spacing: 8, // ระยะห่างแนวนอน
        runSpacing: 6, // ระยะห่างแนวตั้ง (ถ้า wrap ขึ้นบรรทัดใหม่)
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat;

          // นับจำนวนต่อ category
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
            // ไอคอนซ้าย
            avatar: Icon(
              _getCategoryIcon(cat),
              size: 16,
              color: isSelected ? Colors.white : Colors.brown,
            ),
            // label รวมจำนวน
            label: Text('$cat  ($count)'),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.brown,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            selected: isSelected,
            // สีเมื่อเลือก
            selectedColor: Colors.brown,
            // สีปกติ
            backgroundColor: Colors.brown[50],
            // ซ่อน checkmark ของ Material 3
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

  // ========== GRID VIEW ==========
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

    return GestureDetector(
      onTap: () => _goToDetail(menuId, data),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
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

  // ========== LIST VIEW ==========
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _goToDetail(menuId, data),
        leading: ClipRRect(
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
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
