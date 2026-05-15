from PIL import Image
import numpy as np

img = Image.open('assets/logo/new_logo.png').convert('RGBA')
data = np.array(img)

# Siyah pikselleri beyaza çevir
r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]
black_mask = (r < 30) & (g < 30) & (b < 30) & (a > 10)
data[black_mask] = [255, 255, 255, 255]

result = Image.fromarray(data)
arr = np.array(result)

# Logo içeriğini bul
non_white = ~((arr[:,:,0] > 240) & (arr[:,:,1] > 240) & (arr[:,:,2] > 240))
non_transparent = arr[:,:,3] > 10
content = non_white & non_transparent

rows = np.any(content, axis=1)
cols = np.any(content, axis=0)
rmin, rmax = np.where(rows)[0][[0, -1]]
cmin, cmax = np.where(cols)[0][[0, -1]]

# %18 padding ekle (önceki %10'dan daha fazla boşluk)
pad = int((rmax - rmin) * 0.18)
rmin = max(0, rmin - pad)
rmax = min(arr.shape[0], rmax + pad)
cmin = max(0, cmin - pad)
cmax = min(arr.shape[1], cmax + pad)

cropped = result.crop((cmin, rmin, cmax, rmax))

# Kare yap ve beyaz arka plana yerleştir
size = max(cropped.size)
square = Image.new('RGBA', (size, size), (255, 255, 255, 255))
offset = ((size - cropped.width) // 2, (size - cropped.height) // 2)
square.paste(cropped, offset, cropped)

# 1024x1024 kaydet
final = square.resize((1024, 1024), Image.LANCZOS)
final.save('assets/logo/new_logo_white.png')
print(f"Done: padding={pad}px, crop=({cmin},{rmin})-({cmax},{rmax})")
