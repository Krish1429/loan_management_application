import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantProductPage extends StatefulWidget {
  const MerchantProductPage({Key? key}) : super(key: key);

  @override
  State<MerchantProductPage> createState() => _MerchantProductPageState();
}

class _MerchantProductPageState extends State<MerchantProductPage> {
  final supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final List data = await supabase
          .from('products')
          .select()
          .eq('user_id', userId);

      setState(() {
        products = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    }
  }

  Future<void> addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final userId = supabase.auth.currentUser!.id;

      final productData = {
        'user_id': userId,
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': double.tryParse(priceController.text.trim()) ?? 0,
      };

      await supabase.from('products').insert(productData);

      nameController.clear();
      descriptionController.clear();
      priceController.clear();

      await fetchProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => isSaving = false);
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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('My Products'),
        backgroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField('Product Name', nameController),
                        const SizedBox(height: 10),
                        _buildTextField('Description', descriptionController, maxLines: 2),
                        const SizedBox(height: 10),
                        _buildTextField('Price', priceController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : addProduct,
                            child: isSaving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Add Product'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 32, thickness: 1),
                  const Text('Your Products',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: products.isEmpty
                        ? const Center(
                            child: Text('No products yet.',
                                style: TextStyle(color: Colors.white54)),
                          )
                        : ListView.builder(
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return Card(
                                color: Colors.grey[850],
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title: Text(product['name'] ?? '',
                                      style: const TextStyle(color: Colors.white)),
                                  subtitle: Text(product['description'] ?? '',
                                      style: const TextStyle(color: Colors.white70)),
                                  trailing: Text(
                                    '₹${product['price'] ?? 0}',
                                    style: const TextStyle(color: Colors.amber),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.amber),
        ),
      ),
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? 'This field is required' : null,
    );
  }
}


