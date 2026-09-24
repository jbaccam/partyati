from PIL import Image
from pathlib import Path
p=Path('roguelite-planning/weapon-models/studio-import/textures')
a=Image.open(p/'W20_Cinder_Blocks_Texture0.png').convert('RGB')
# PNG rows are top-down; UV dark tile occupies column 1, bottom row.
concrete=a.getpixel((224,160))
a.paste(concrete,(64,256,128,320));a.save(p/'Cinder_Corrected.png')
b=Image.open(p/'W22_Bowling_Ball_Texture0.png').convert('RGB')
# Uniform black albedo: no painted socket shadows or gray body tile.
b.paste((17,17,17),(0,0,*b.size));b.save(p/'Bowling_Charcoal_Corrected.png')
print('concrete',concrete)

