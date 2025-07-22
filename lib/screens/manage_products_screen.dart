import 'package:flutter/material.dart';
import '../supabase_client.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController(); // ✅ Added price controller

  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final userId = supabase.auth.currentUser?.id;
    final response = await supabase
        .from('products')
        .select()
        .eq('user_id', userId ?? '');

    setState(() {
      products = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> addProduct() async {
    final userId = supabase.auth.currentUser?.id;

    await supabase.from('products').insert({
      'user_id': userId,
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'price': double.tryParse(priceController.text.trim()) ?? 0.0,
    });

    nameController.clear();
    descriptionController.clear();
    priceController.clear();
    fetchProducts();
  }

  Future<void> deleteProduct(String productId) async {
    await supabase.from('products').delete().eq('product_id', productId);
    fetchProducts();
  }

  Future<void> editProduct(String productId, String currentName, String currentDesc, double currentPrice) async {
    final newName = await _showEditDialog('Edit Name', currentName);
    final newDesc = await _showEditDialog('Edit Description', currentDesc);
    final newPriceStr = await _showEditDialog('Edit Price', currentPrice.toString());
    final newPrice = double.tryParse(newPriceStr ?? '') ?? currentPrice;

    if (newName != null && newDesc != null) {
      await supabase.from('products').update({
        'name': newName,
        'description': newDesc,
        'price': newPrice,
      }).eq('product_id', productId);
      fetchProducts();
    }
  }

  Future<String?> _showEditDialog(String title, String initialValue) async {
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            ElevatedButton(onPressed: addProduct, child: const Text('Add Product')),
            const Divider(),
            const Text('My Products', style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return Card(
                    child: ListTile(
                      title: Text(p['name']),
                      subtitle: Text('${p['description']}\nPrice: ₹${p['price'] ?? 0}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => editProduct(
                              p['product_id'],
                              p['name'],
                              p['description'],
                              (p['price'] as num?)?.toDouble() ?? 0.0,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteProduct(p['product_id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}