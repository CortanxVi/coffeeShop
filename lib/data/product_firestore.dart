import 'package:cloud_firestore/cloud_firestore.dart';

class Products {
  final String id; // <-- Firestore doc id
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;

  Products({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
  });

  factory Products.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing data for productId: ${doc.id}');
    }

    return Products(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      price: ((data['price'] ?? 0) as num).toDouble(),
      description: (data['description'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      image: (data['image'] ?? '') as String,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'price': price,
    'description': description,
    'category': category,
    'image': image,
  };
}
