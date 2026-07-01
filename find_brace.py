import os

c_file = 'lib/features/home/screens/views/consultant_dashboard_view.dart'
with open(c_file, 'r', encoding='utf-8') as f:
    c = f.read()

brace_count = 0
in_class = False
class_start = c.find('class _ConsultantDashboardViewState')
for i in range(class_start, len(c)):
    if c[i] == '{':
        brace_count += 1
        in_class = True
    elif c[i] == '}':
        brace_count -= 1
        if in_class and brace_count == 0:
            print(f'Class _ConsultantDashboardViewState ended at index {i}, which is line {c.count(chr(10), 0, i) + 1}')
            break
