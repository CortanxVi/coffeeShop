class CartItem {
  final String menuId;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;
  String? note;

  CartItem({
    required this.menuId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    this.note,
  });
}

// สร้างตัวแปร Global แบบง่ายๆ สำหรับเก็บข้อมูล (หรือใช้ Provider แทนได้)
List<CartItem> globalCart = [];
