import os

h_file = 'lib/features/home/screens/home_screen.dart'
with open(h_file, 'r', encoding='utf-8') as f:
    h_content = f.read()

h_content = h_content.replace("distributorId ??", "consultantId ??")

with open(h_file, 'w', encoding='utf-8') as f:
    f.write(h_content)

c_file = 'lib/features/home/screens/views/consultant_dashboard_view.dart'
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
if "Widget _buildCustomerInitialsAvatar" not in c_content:
    if c_content.rstrip().endswith('}'):
        c_content = c_content.rstrip()[:-1] + missing_avatar
        with open(c_file, 'w', encoding='utf-8') as f:
            f.write(c_content)
    else:
        with open(c_file, 'a', encoding='utf-8') as f:
            f.write(missing_avatar)

print("Fixed final issues.")
