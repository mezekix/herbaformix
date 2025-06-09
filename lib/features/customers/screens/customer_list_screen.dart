import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/customer_provider.dart';
import './add_edit_customer_screen.dart'; // Yeni ekranı import et
import './customer_detail_screen.dart'; // Yeni ekranı import et

class CustomerListScreen extends StatelessWidget {
  static const String routeName = '/customers';
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final customers = customerProvider.customers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşterilerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Yeni Müşteri Ekle',
            onPressed: () {
              context.goNamed(AddEditCustomerScreen.routeName);
            },
          ),
        ],
      ),
      body: customerProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : customers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Henüz müşteriniz bulunmuyor.',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('İlk Müşterinizi Ekleyin'),
                    onPressed: () {
                      context.goNamed(AddEditCustomerScreen.routeName);
                    },
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 5.0,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        customer.firstName.isNotEmpty
                            ? customer.firstName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(
                      '${customer.firstName} ${customer.lastName}'.trim(),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          customer.phoneNumber ??
                              'İletişim bilgisi yok',
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'İlk Temas: ${DateFormat('dd.MM.yyyy').format(customer.firstContactDate.toDate())}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: 'Düzenle',
                          onPressed: () {
                            context.goNamed(
                              AddEditCustomerScreen.routeName,
                              extra: customer,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          tooltip: 'Sil',
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Müşteriyi Sil'),
                                content: Text(
                                  '"${customer.firstName} ${customer.lastName}" adlı müşteriyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('İptal'),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                  ),
                                  TextButton(
                                    child: const Text(
                                      'Sil',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await customerProvider.deleteCustomer(
                                customer.id,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      // Müşteriye tıklandığında artık düzenleme ekranına değil,
                      // yeni oluşturduğumuz Müşteri Detay Ekranı'na yönlendiriyoruz.
                      // Müşteri verisini `extra` parametresi ile gönderiyoruz.
                      context.goNamed(
                        CustomerDetailScreen.routeName,
                        extra: customer,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
