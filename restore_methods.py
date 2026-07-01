import os

c_file = 'lib/features/home/screens/views/consultant_dashboard_view.dart'
h_file = 'lib/features/home/screens/home_screen.dart'

with open(h_file, 'r', encoding='utf-8') as f:
    h_content = f.read()

missing_home_methods = """
  void _showRecentActivationSheet(BuildContext context, List<CustomerModel> recentActivations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Yeni Aktivasyonlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: recentActivations.length,
                separatorBuilder: (ctx, i) => const Divider(height: 24),
                itemBuilder: (ctx, i) {
                  final customer = recentActivations[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        customer.firstName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text('${customer.firstName} ${customer.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('ID: ${customer.distributorId ?? 'Bilinmiyor'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: () {
                        Navigator.pop(ctx);
                        // Navigate to detail
                      },
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

  void _showQuickAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.person_add, color: Colors.white)),
              title: const Text('Yeni Müşteri Ekle'),
              onTap: () {
                Navigator.pop(ctx);
                // logic
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.secondary, child: Icon(Icons.shopping_cart, color: Colors.white)),
              title: const Text('Yeni Sipariş Oluştur'),
              onTap: () {
                Navigator.pop(ctx);
                // logic
              },
            ),
          ],
        ),
      ),
    );
  }
}
"""
if not h_content.rstrip().endswith('}'):
    with open(h_file, 'a', encoding='utf-8') as f:
        f.write(missing_home_methods)
else:
    with open(h_file, 'w', encoding='utf-8') as f:
        f.write(h_content.rstrip()[:-1] + missing_home_methods)

# Add _buildCustomerInitialsAvatar to consultant_dashboard_view.dart
with open(c_file, 'r', encoding='utf-8') as f:
    c_content = f.read()

missing_avatar = """
  Widget _buildCustomerInitialsAvatar(
    String firstName,
    String lastName,
    String customerId,
  ) {
    final fullName = '$firstName $lastName'.trim();
    final initials = fullName.split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final bgColor = AvatarColorHelper.forUser(customerId);
    final textColor = AvatarColorHelper.textColorFor(bgColor);

    return CircleAvatar(
      radius: 24,
      backgroundColor: bgColor,
      child: Text(
        initials.isNotEmpty ? initials : '?',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
"""
if "_buildCustomerInitialsAvatar" not in c_content:
    if c_content.rstrip().endswith('}'):
        c_content = c_content.rstrip()[:-1] + missing_avatar
        with open(c_file, 'w', encoding='utf-8') as f:
            f.write(c_content)
    else:
        with open(c_file, 'a', encoding='utf-8') as f:
            f.write(missing_avatar)

print("Appended methods.")
