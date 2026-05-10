import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user_profile_model.dart';
import '../../../services/firestore_service.dart';

/// Müşterinin bağlı olduğu distribütörün bilgilerini salt okunur kart içinde gösterir.
///
/// - [assignedDistributorId] doluysa Firestore'dan distribütör adı ve telefonunu yükler.
/// - [assignedDistributorId] boşsa "Henüz bir distribütöre bağlı değilsiniz." mesajı gösterir.
/// - Yükleme sırasında [CircularProgressIndicator] gösterir.
/// - Hata durumunda "Distribütör bilgisi yüklenemedi." mesajı gösterir.
class DistributorInfoCard extends StatelessWidget {
  final String? assignedDistributorId;

  const DistributorInfoCard({
    super.key,
    required this.assignedDistributorId,
  });

  @override
  Widget build(BuildContext context) {
    // assignedDistributorId boşsa bilgi mesajı göster
    if (assignedDistributorId == null || assignedDistributorId!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distribütörüm',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const Text('Henüz bir distribütöre bağlı değilsiniz.'),
            ],
          ),
        ),
      );
    }

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return FutureBuilder<UserProfileModel?>(
      future: firestoreService.getDistributorProfile(assignedDistributorId!),
      builder: (context, snapshot) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribütörüm',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildContent(context, snapshot),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<UserProfileModel?> snapshot,
  ) {
    // Yükleme durumu
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Hata durumu
    if (snapshot.hasError) {
      return const Text('Distribütör bilgisi yüklenemedi.');
    }

    // Distribütör bulunamadı
    final distributor = snapshot.data;
    if (distributor == null) {
      return const Text('Distribütör bilgisi yüklenemedi.');
    }

    // Distribütör bilgilerini salt okunur olarak göster
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReadOnlyField(
          label: 'Ad Soyad',
          value: distributor.name ?? '-',
        ),
        const SizedBox(height: 8),
        _ReadOnlyField(
          label: 'Telefon',
          value: distributor.phoneNumber ?? '-',
        ),
      ],
    );
  }
}

/// Salt okunur etiket + değer çifti widget'ı.
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
