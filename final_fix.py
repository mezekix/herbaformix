import os

# Fix ConsultantDashboardView
c_file = 'lib/features/home/screens/views/consultant_dashboard_view.dart'
with open(c_file, 'r', encoding='utf-8') as f:
    c_content = f.read()

# Add _riskCountFuture and didChangeDependencies if not present
if "Future<int>? _riskCountFuture;" not in c_content:
    search_str = "Widget build(BuildContext context) {"
    if search_str in c_content:
        # find the @override before it
        idx = c_content.rfind("@override", 0, c_content.find(search_str))
        if idx != -1:
            did_change = """
  Future<int>? _riskCountFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.userProfile != null && _riskCountFuture == null) {
      _riskCountFuture = context
          .read<FirestoreService>()
          .getAtRiskCustomerCount(widget.userProfile!.id);
    }
  }

  """
            c_content = c_content[:idx] + did_change + c_content[idx:]
        else:
            print("Couldn't find @override for build method in consultant_dashboard_view")
    else:
        print("Couldn't find build method in consultant_dashboard_view")

# Add missing _buildCustomerInitialsAvatar if not present
if "_buildCustomerInitialsAvatar" not in c_content:
    avatar_code = """
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
    if c_content.endswith("}"):
        c_content = c_content[:-1] + avatar_code
    else:
        print("Consultant file didn't end with }")

with open(c_file, 'w', encoding='utf-8') as f:
    f.write(c_content)

# Fix HomeScreen
h_file = 'lib/features/home/screens/home_screen.dart'
with open(h_file, 'r', encoding='utf-8') as f:
    h_content = f.read()

if "Future<int>? _riskCountFuture;" not in h_content:
    print("HomeScreen didn't have _riskCountFuture, maybe it was removed incorrectly.")

# Since HomeScreen might have had _riskCountFuture removed and might have lost other methods like _showRecentActivationSheet,
# I will just write a python script to check if they are missing and print to console instead of guessing what's broken in home_screen.dart.
print("HomeScreen len: ", len(h_content))
