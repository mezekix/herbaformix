import 'package:cloud_firestore/cloud_firestore.dart'; // Timestamp için
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/customer_model.dart';
import '../../auth/providers/auth_provider.dart'; // userId için
import '../providers/customer_provider.dart';

class AddEditCustomerScreen extends StatefulWidget {
  const AddEditCustomerScreen({super.key, this.customer});

  static const String routeName =
      'add-edit-customer'; // Ana rota /customers altında olacak

  final CustomerModel? customer; // Düzenleme için opsiyonel müşteri

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  final _formKey = GlobalKey<FormState>();
  bool _isActive = true;
  bool _isLoading = false;
  late TextEditingController _lastNameController;
  late TextEditingController _notesController;
  late TextEditingController _phoneNumberController;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.customer?.firstName,
    );
    _lastNameController = TextEditingController(
      text: widget.customer?.lastName,
    );
    _phoneNumberController = TextEditingController(
      text: widget.customer?.phoneNumber,
    );
    _emailController = TextEditingController(text: widget.customer?.email);
    _addressController = TextEditingController(text: widget.customer?.address);
    _notesController = TextEditingController(text: widget.customer?.notes);
    _isActive = widget.customer?.isActive ?? true;
  }

  bool get _isEditing => widget.customer != null;

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!
        .save(); // Formdaki onSave metotlarını çalıştırır (varsa)

    setState(() {
      _isLoading = true;
    });

    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.firebaseUser?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kullanıcı bilgisi bulunamadı. Lütfen tekrar giriş yapın.',
          ),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final customerData = CustomerModel(
      id: _isEditing ? widget.customer!.id : '',
      consultantId: _isEditing ? widget.customer!.consultantId : currentUserId,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      firstContactDate: _isEditing
          ? widget.customer!.firstContactDate
          : Timestamp.now(),
      isActive: _isActive,
    );

    bool success;
    if (_isEditing) {
      success = await customerProvider.updateCustomer(customerData);
    } else {
      success = await customerProvider.addCustomer(customerData);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Müşteri başarıyla ${_isEditing ? "güncellendi" : "eklendi"}!',
            ),
          ),
        );
        context.pop(); // Bir önceki ekrana (Müşteri Listesi) dön
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Müşteri ${_isEditing ? "güncellenirken" : "eklenirken"} bir hata oluştu.',
            ),
          ),
        );
      }
    }
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
                final customerProvider =
                    Provider.of<CustomerProvider>(context, listen: false);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Müşteriyi Sil'),
                    content: Text(
                      '"${widget.customer!.firstName} ${widget.customer!.lastName}" adlı müşteriyi silmek istediğinizden emin misiniz?',
                    ),
                    actions: [
                      TextButton(
                        child: const Text('İptal'),
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                      TextButton(
                        child: const Text(
                          'Sil',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  setState(() {
                    _isLoading = true;
                  });
                  final success = await customerProvider
                      .deleteCustomer(widget.customer!.id);

                  if (!mounted) return;

                  setState(() {
                    _isLoading = false;
                  });
                  if (success) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Müşteri silindi.')),
                    );
                    navigator.pop();
                  } else {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Müşteri silinirken hata oluştu.'),
                      ),
                    );
                  }
                }
              },
            ),
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
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Adı*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Müşteri adı zorunludur.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Soyadı*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Müşteri soyadı zorunludur.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon Numarası*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Telefon numarası zorunludur.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-posta Adresi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            !value.contains('@')) {
                          return 'Geçerli bir e-posta adresi girin.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adres',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notlar',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Müşteri Aktif'),
                      subtitle: const Text('Müşteri takibi devam ediyor mu?'),
                      value: _isActive,
                      onChanged: (bool value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      secondary: const Icon(Icons.track_changes_outlined),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: Icon(
                        _isEditing
                            ? Icons.save_alt_outlined
                            : Icons.add_circle_outline,
                      ),
                      label: Text(
                        _isEditing ? 'Değişiklikleri Kaydet' : 'Müşteriyi Ekle',
                      ),
                      onPressed: _saveCustomer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
