import os

c_file = 'lib/features/home/screens/views/consultant_dashboard_view.dart'
with open(c_file, 'r', encoding='utf-8') as f:
    c_content = f.read()

# We know that `Widget _buildCustomerInitialsAvatar` is at the end of the file, outside the class.
# The class probably ends right before it.
# We want to move it inside.
avatar_start = c_content.find("Widget _buildCustomerInitialsAvatar")
if avatar_start != -1:
    # find the brace before it
    brace_idx = c_content.rfind("}", 0, avatar_start)
    if brace_idx != -1:
        # Move the brace to the end of the file
        new_content = c_content[:brace_idx] + c_content[brace_idx+1:]
        if not new_content.rstrip().endswith("}"):
            new_content = new_content.rstrip() + "\n}\n"
        
        with open(c_file, 'w', encoding='utf-8') as f:
            f.write(new_content)

h_file = 'lib/features/home/screens/home_screen.dart'
with open(h_file, 'r', encoding='utf-8') as f:
    h_content = f.read()

h_content = h_content.replace("consultantId ?? 'Bilinmiyor'", "consultantId")

with open(h_file, 'w', encoding='utf-8') as f:
    f.write(h_content)

print("Fixed")
