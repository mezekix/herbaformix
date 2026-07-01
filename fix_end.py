import os

c_file = 'lib/features/home/screens/views/consultant_dashboard_view.dart'
with open(c_file, 'r', encoding='utf-8') as f:
    c_content = f.read()

# Trim everything from the first "Widget _buildCustomerInitialsAvatar" downwards
idx = c_content.find("Widget _buildCustomerInitialsAvatar")
if idx != -1:
    c_content = c_content[:idx]

# Ensure the last method (_buildMiniActionButton) closes properly.
# We know it ends with "    );\n\n\n" or similar.
while c_content.rstrip().endswith(';'):
    c_content = c_content.rstrip()
    
# Wait, let's just make sure it closes the method properly.
# Actually, if we just append "  }\n" to close _buildMiniActionButton, 
# and then add _buildCustomerInitialsAvatar and then close the class with "}\n".

clean_end = """
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

c_content = c_content.rstrip()
if c_content.endswith(");"):
    c_content = c_content + "\n  }\n\n" + clean_end
else:
    c_content = c_content + "\n" + clean_end

with open(c_file, 'w', encoding='utf-8') as f:
    f.write(c_content)
print("File fixed")
