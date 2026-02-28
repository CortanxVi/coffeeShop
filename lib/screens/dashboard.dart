import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      // ── FAB เพิ่มสินค้าใหม่ ──
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.brown,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('เพิ่มสินค้า', style: TextStyle(color: Colors.white)),
        onPressed: () => _showAddMenuDialog(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SummarySection(),
            const SizedBox(height: 24),
            const Text(
              '⭐ จัดการป้ายยอดนิยม',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const _PopularMenuSection(),
            const SizedBox(height: 24),
            const Text(
              '📊 เมนูที่สั่งมากสุด',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const _TopMenuSection(),
            const SizedBox(height: 80), // padding ไม่ให้ FAB บัง
          ],
        ),
      ),
    );
  }

  // ── Dialog เพิ่มสินค้า ──
  void _showAddMenuDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _AddMenuDialog(),
    );
  }
}

// ============================================================
// ADD MENU DIALOG
// ============================================================
class _AddMenuDialog extends StatefulWidget {
  const _AddMenuDialog();

  @override
  State<_AddMenuDialog> createState() => _AddMenuDialogState();
}

class _AddMenuDialogState extends State<_AddMenuDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'coffee';
  bool _isPopular = false;
  bool _isSaving = false;

  final List<String> _categories = ['coffee', 'non-coffee', 'food', 'other'];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('menu').add({
        'name': _nameController.text.trim(),
        'price': int.parse(_priceController.text.trim()),
        'category': _selectedCategory,
        'imageUrl': _imageUrlController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isPopular': _isPopular,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ เพิ่ม "${_nameController.text.trim()}" แล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    const Icon(Icons.add_circle, color: Colors.brown, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'เพิ่มสินค้าใหม่',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // ── Preview รูปภาพ ──
                _buildImagePreview(),
                const SizedBox(height: 16),

                // ── ชื่อสินค้า ──
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(
                    label: 'ชื่อสินค้า *',
                    icon: Icons.coffee,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'กรุณากรอกชื่อสินค้า'
                      : null,
                ),
                const SizedBox(height: 12),

                // ── ราคา ──
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    label: 'ราคา (บาท) *',
                    icon: Icons.attach_money,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'กรุณากรอกราคา';
                    if (int.tryParse(v.trim()) == null)
                      return 'กรุณากรอกตัวเลขเท่านั้น';
                    if (int.parse(v.trim()) <= 0) return 'ราคาต้องมากกว่า 0';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ── URL รูปภาพ ──
                TextFormField(
                  controller: _imageUrlController,
                  decoration: _inputDecoration(
                    label: 'URL รูปภาพ (ไม่บังคับ)',
                    icon: Icons.image_outlined,
                  ),
                  onChanged: (_) => setState(() {}), // refresh preview
                ),
                const SizedBox(height: 12),

                // ── คำอธิบาย ──
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: _inputDecoration(
                    label: 'คำอธิบาย (ไม่บังคับ)',
                    icon: Icons.notes,
                  ),
                ),
                const SizedBox(height: 16),

                // ── หมวดหมู่ ──
                const Text(
                  'หมวดหมู่',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: Colors.brown,
                      backgroundColor: Colors.brown[50],
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.brown,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ── Toggle ยอดนิยม ──
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: SwitchListTile(
                    secondary: const Icon(Icons.star, color: Colors.orange),
                    title: const Text(
                      'ติด Badge ยอดนิยม',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'แสดง ⭐ บนหน้าเมนู',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _isPopular,
                    activeColor: Colors.orange,
                    onChanged: (val) => setState(() => _isPopular = val),
                  ),
                ),
                const SizedBox(height: 20),

                // ── ปุ่มบันทึก ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveMenu,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          _isSaving ? 'กำลังบันทึก...' : 'บันทึกสินค้า',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Preview รูปภาพตาม URL ที่กรอก ──
  Widget _buildImagePreview() {
    final url = _imageUrlController.text.trim();
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.brown[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderIcon(),
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                )
              : _placeholderIcon(),
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: Colors.brown[300],
        ),
        const SizedBox(height: 4),
        Text(
          'ใส่ URL รูปภาพ',
          style: TextStyle(fontSize: 10, color: Colors.brown[300]),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.brown),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.brown, width: 2),
      ),
    );
  }
}

// ============================================================
// SUMMARY SECTION
// ============================================================
class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        int pending = 0, ready = 0, paid = 0;
        double totalRevenue = 0;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';
          if (status == 'pending') pending++;
          if (status == 'ready') ready++;
          if (status == 'paid') {
            paid++;
            totalRevenue += (data['price'] ?? 0).toDouble();
          }
        }

        return Column(
          children: [
            Row(
              children: [
                _SummaryCard(
                  label: 'รอทำ',
                  value: '$pending',
                  icon: Icons.pending_outlined,
                  color: Colors.orange,
                ),
                const SizedBox(width: 10),
                _SummaryCard(
                  label: 'พร้อมเสิร์ฟ',
                  value: '$ready',
                  icon: Icons.room_service_outlined,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _SummaryCard(
                  label: 'ชำระแล้ว',
                  value: '$paid',
                  icon: Icons.check_circle_outline,
                  color: Colors.blue,
                ),
                const SizedBox(width: 10),
                _SummaryCard(
                  label: 'รายได้รวม',
                  value: '฿${totalRevenue.toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: color, fontSize: 11)),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// POPULAR MENU SECTION — toggle + edit + delete
// ============================================================
class _PopularMenuSection extends StatelessWidget {
  const _PopularMenuSection();

  Future<void> _togglePopular(String docId, bool current) async {
    await FirebaseFirestore.instance.collection('menu').doc(docId).update({
      'isPopular': !current,
    });
  }

  Future<void> _deleteMenu(
    BuildContext context,
    String docId,
    String name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบ "$name" ออกจากเมนูใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('menu').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ ลบ "$name" แล้ว'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('menu').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.coffee_maker_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'ยังไม่มีสินค้า',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'กดปุ่ม "+ เพิ่มสินค้า" เพื่อเริ่มต้น',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final isPopular = data['isPopular'] ?? false;
            final imageUrl = data['imageUrl'] ?? '';
            final name = data['name'] ?? '-';
            final price = data['price'] ?? 0;
            final category = data['category'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                // รูปภาพ
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),

                // ชื่อ + badge + category
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('⭐', style: TextStyle(fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '฿$price  ·  $category',
                  style: const TextStyle(fontSize: 12),
                ),

                // ปุ่ม Action
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle ยอดนิยม
                    Switch(
                      value: isPopular,
                      activeColor: Colors.orange,
                      onChanged: (_) => _togglePopular(docId, isPopular),
                    ),
                    // ปุ่มแก้ไข
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                      tooltip: 'แก้ไข',
                      onPressed: () => showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            _EditMenuDialog(docId: docId, initialData: data),
                      ),
                    ),
                    // ปุ่มลบ
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: 'ลบ',
                      onPressed: () => _deleteMenu(context, docId, name),
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

  Widget _placeholder() {
    return Container(
      color: Colors.brown[50],
      child: const Center(
        child: Icon(Icons.coffee, color: Colors.brown, size: 28),
      ),
    );
  }
}

// ============================================================
// EDIT MENU DIALOG
// ============================================================
class _EditMenuDialog extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const _EditMenuDialog({required this.docId, required this.initialData});

  @override
  State<_EditMenuDialog> createState() => _EditMenuDialogState();
}

class _EditMenuDialogState extends State<_EditMenuDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _descriptionController;
  late String _selectedCategory;
  late bool _isPopular;
  bool _isSaving = false;

  final List<String> _categories = ['coffee', 'non-coffee', 'food', 'other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialData['name'] ?? '',
    );
    _priceController = TextEditingController(
      text: (widget.initialData['price'] ?? '').toString(),
    );
    _imageUrlController = TextEditingController(
      text: widget.initialData['imageUrl'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialData['description'] ?? '',
    );
    _selectedCategory = widget.initialData['category'] ?? 'coffee';
    _isPopular = widget.initialData['isPopular'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('menu')
          .doc(widget.docId)
          .update({
            'name': _nameController.text.trim(),
            'price': int.parse(_priceController.text.trim()),
            'category': _selectedCategory,
            'imageUrl': _imageUrlController.text.trim(),
            'description': _descriptionController.text.trim(),
            'isPopular': _isPopular,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ แก้ไข "${_nameController.text.trim()}" แล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.blue, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'แก้ไขสินค้า',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Preview รูป
                _buildImagePreview(),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('ชื่อสินค้า *', Icons.coffee),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'กรุณากรอกชื่อสินค้า'
                      : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    'ราคา (บาท) *',
                    Icons.attach_money,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'กรุณากรอกราคา';
                    if (int.tryParse(v.trim()) == null)
                      return 'กรุณากรอกตัวเลข';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _imageUrlController,
                  decoration: _inputDecoration(
                    'URL รูปภาพ',
                    Icons.image_outlined,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: _inputDecoration('คำอธิบาย', Icons.notes),
                ),
                const SizedBox(height: 16),

                const Text(
                  'หมวดหมู่',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: Colors.brown,
                      backgroundColor: Colors.brown[50],
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.brown,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: SwitchListTile(
                    secondary: const Icon(Icons.star, color: Colors.orange),
                    title: const Text(
                      'ติด Badge ยอดนิยม',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: _isPopular,
                    activeColor: Colors.orange,
                    onChanged: (val) => setState(() => _isPopular = val),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveEdit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          _isSaving ? 'กำลังบันทึก...' : 'บันทึกการแก้ไข',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final url = _imageUrlController.text.trim();
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.brown[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderIcon(),
                )
              : _placeholderIcon(),
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: Colors.brown[300],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.brown),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.brown, width: 2),
      ),
    );
  }
}

// ============================================================
// TOP MENU SECTION
// ============================================================
class _TopMenuSection extends StatelessWidget {
  const _TopMenuSection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'paid')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final Map<String, int> menuCount = {};
        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final menuId = data['menuId'] ?? '';
          if (menuId.isNotEmpty) {
            menuCount[menuId] = (menuCount[menuId] ?? 0) + 1;
          }
        }

        if (menuCount.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Text(
              'ยังไม่มีข้อมูลการขาย',
              style: TextStyle(color: Colors.grey[500]),
            ),
          );
        }

        final sorted = menuCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top5 = sorted.take(5).toList();

        return Column(
          children: top5.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final menuId = entry.value.key;
            final count = entry.value.value;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('menu')
                  .doc(menuId)
                  .get(),
              builder: (context, menuSnap) {
                final menuData =
                    menuSnap.data?.data() as Map<String, dynamic>? ?? {};
                final name = menuData['name'] ?? '...';
                final medalColor = rank == 1
                    ? Colors.amber
                    : rank == 2
                    ? Colors.grey.shade400
                    : rank == 3
                    ? Colors.brown.shade300
                    : Colors.brown.shade100;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: medalColor,
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Chip(
                      label: Text('$count ครั้ง'),
                      backgroundColor: Colors.brown[50],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
