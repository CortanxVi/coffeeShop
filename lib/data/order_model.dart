enum OrderStatus { pending, ready, served }

class OrderItem {
  final String id;
  final String menuName;
  final String customerName;
  final double price;
  final DateTime timestamp;
  OrderStatus status;

  OrderItem({
    required this.id,
    required this.menuName,
    required this.customerName,
    required this.price,
    required this.timestamp,
    this.status = OrderStatus.pending,
  });
}
