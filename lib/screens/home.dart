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

  final List<String> categories = ['ทั้งหมด', 'coffee', 'non-coffee', 'food'];

  Stream<QuerySnapshot> get _menuStream {
    final ref = FirebaseFirestore.instance.collection('menu');
    if (selectedCategory == 'ทั้งหมด') return ref.snapshots();
    return ref.where('category', isEqualTo: selectedCategory).snapshots();
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
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _menuStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.coffee, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          'ไม่มีเมนูในหมวดนี้',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final menuList = snapshot.data!.docs;
                return isGridView ? _buildGrid(menuList) : _buildList(menuList);
              },
            ),
          ),
        ],
      ),
    );
  }

  // แถบ Category
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.brown : Colors.brown[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.brown,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
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
    final category = data['category'] ?? '';

    return GestureDetector(
      onTap: () => _goToDetail(menuId, data),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รูปภาพ
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
            // ข้อมูล
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
    final category = data['category'] ?? '';

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

  // ไปหน้ารายละเอียด
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
