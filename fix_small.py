import os

c_file = 'lib/features/home/screens/views/consultant_dashboard_view.dart'
with open(c_file, 'r', encoding='utf-8') as f:
    c_content = f.read()

c_content = c_content.rstrip() + '\n}\n'
c_content = c_content.replace("import '../distributor_product_usage_screen.dart';\n", '')

with open(c_file, 'w', encoding='utf-8') as f:
    f.write(c_content)

h_file = 'lib/features/home/screens/home_screen.dart'
with open(h_file, 'r', encoding='utf-8') as f:
    h_content = f.read()

h_content = h_content.replace("final orderProvider = context.watch<OrderProvider>();\n", '')
h_content = h_content.replace("final productProvider = context.watch<ProductProvider>();\n", '')
h_content = h_content.replace("    final orderProvider = context.watch<OrderProvider>();\n", '')
h_content = h_content.replace("    final productProvider = context.watch<ProductProvider>();\n", '')

with open(h_file, 'w', encoding='utf-8') as f:
    f.write(h_content)
    
print("Fixed small issues!")
