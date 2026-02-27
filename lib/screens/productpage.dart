import 'package:flutter/material.dart';
import '../service/firestore_service.dart';
import '../data/product_firestore.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: StreamBuilder<List<Products>>(
        stream: streamProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (_, i) {
              final p = products[i];
              return ListTile(
                leading: p.image.isNotEmpty
                    ? Image.network(
                        p.image,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image),
                title: Text(p.title),
                subtitle: Text(p.category),
                trailing: Text('฿${p.price.toStringAsFixed(0)}'),
              );
            },
          );
        },
      ),
    );
  }
}
