import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../models/product_model.dart';
import '../providers/product_provider.dart';

class AddEditProductScreen extends StatefulWidget {
  static const String routeName = 'add-product';
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _vpController;
  late TextEditingController _priceController;
  late TextEditingController _overviewController;
  late TextEditingController _imageUrlController;

  bool _isLoading = false;
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _vpController = TextEditingController(
      text: widget.product?.vp.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?.price?.toString() ?? '',
    );
    _overviewController = TextEditingController(
      text: widget.product?.overview ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.product?.imageUrl ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _vpController.dispose();
    _priceController.dispose();
    _overviewController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final newProduct = ProductModel(
        id: widget.product?.id ?? '', // Firestore will generate if empty
        name: _nameController.text.trim(),
        vp: double.tryParse(_vpController.text) ?? 0.0,
        price: double.tryParse(_priceController.text),
        overview: _overviewController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
      );

      final provider = context.read<ProductProvider>();
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);

      try {
        if (_isEditing) {
          await provider.updateProduct(newProduct);
          if (!mounted) return; // Widget hala ağaçta mı kontrol et
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Ürün başarıyla güncellendi!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          await provider.addProduct(newProduct);
          if (!mounted) return; // Widget hala ağaçta mı kontrol et
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Ürün başarıyla eklendi!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (router.canPop()) {
          router.pop();
        }
      } catch (e) {
        if (!mounted) return; // Widget hala ağaçta mı kontrol et
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Ürünü Düzenle' : 'Yeni Ürün Ekle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveForm,
            tooltip: 'Kaydet',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Ürün Adı'),
                      validator: (value) =>
                          value!.isEmpty ? 'Lütfen ürün adı girin.' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vpController,
                      decoration: const InputDecoration(
                        labelText: 'Volume Puanı (VP)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) =>
                          value!.isEmpty ? 'Lütfen VP değeri girin.' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Fiyat (TL)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      // Fiyat zorunlu değil
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _overviewController,
                      decoration: const InputDecoration(
                        labelText: 'Genel Bakış',
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: 'Resim URL'),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveForm,
                      icon: const Icon(Icons.save),
                      label: const Text('Ürünü Kaydet'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
