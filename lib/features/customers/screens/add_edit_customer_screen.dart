import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Timestamp için
import '../providers/customer_provider.dart';
import '../../../models/customer_model.dart';
import '../../auth/providers/auth_provider.dart'; // userId için

class AddEditCustomerScreen extends StatefulWidget {
  static const String routeName = 'add-edit-customer'; // Ana rota /customers altında olacak
  final CustomerModel? customer; // Düzenleme için opsiyonel müşteri

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  bool _isLoading = false;
  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name);
    _phoneController = TextEditingController(text: widget.customer?.phone);
    _emailController = TextEditingController(text: widget.customer?.email);
    _addressController = TextEditingController(text: widget.customer?.address);
    _notesController = TextEditingController(text: widget.customer?.notes);
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save(); // Formdaki onSave metotlarını çalıştırır (varsa)

    setState(() { _isLoading = true; });

    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.firebaseUser?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı. Lütfen tekrar giriş yapın.')),
      );
      setState(() { _isLoading = false; });
      return;
    }

    final customerData = CustomerModel(
      id: _isEditing ? widget.customer!.id : '', // Düzenlemede ID korunur, eklemede boş
      userId: currentUserId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      createdAt: _isEditing ? widget.customer!.createdAt : Timestamp.now(), // Eklemede şimdi, düzenlemede korunur
    );

    bool success;
    if (_isEditing) {
      success = await customerProvider.updateCustomer(customerData);
    } else {
      success = await customerProvider.addCustomer(customerData);
    }

    if (mounted) {
      setState(() { _isLoading = false; });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Müşteri başarıyla ${_isEditing ? "güncellendi" : "eklendi"}!')),
        );
        context.pop(); // Bir önceki ekrana (Müşteri Listesi) dön
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Müşteri ${_isEditing ? "güncellenirken" : "eklenirken"} bir hata oluştu.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Müşteriyi Düzenle' : 'Yeni Müşteri Ekle'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Müşteriyi Sil',
              onPressed: () async {
                 final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Müşteriyi Sil'),
                      content: Text('"${widget.customer!.name}" adlı müşteriyi silmek istediğinizden emin misiniz?'),
                      actions: [
                        TextButton(child: const Text('İptal'), onPressed: () => Navigator.of(ctx).pop(false)),
                        TextButton(child: const Text('Sil', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(ctx).pop(true)),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    setState(() { _isLoading = true; });
                    final success = await Provider.of<CustomerProvider>(context, listen: false).deleteCustomer(widget.customer!.id);
                     if (mounted) {
                        setState(() { _isLoading = false; });
                        if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Müşteri silindi.')));
                            context.pop();
                        } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Müşteri silinirken hata oluştu.')));
                        }
                     }
                  }
              },
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Adı Soyadı*', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Müşteri adı zorunludur.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Telefon Numarası', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined)),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'E-posta Adresi', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                      keyboardType: TextInputType.emailAddress,
                       validator: (value) {
                        if (value != null && value.trim().isNotEmpty && !value.contains('@')) {
                          return 'Geçerli bir e-posta adresi girin.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Adres', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined)),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notlar', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note_alt_outlined)),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: Icon(_isEditing ? Icons.save_alt_outlined : Icons.add_circle_outline),
                      label: Text(_isEditing ? 'Değişiklikleri Kaydet' : 'Müşteriyi Ekle'),
                      onPressed: _saveCustomer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 16)
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}