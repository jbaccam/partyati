"""Serialize the reviewed Studio template manifest for the authoritative Rojo build."""
import json
import xml.etree.ElementTree as E
from pathlib import Path
out=Path(__file__).resolve().parent/'finished'
rows=json.loads((out/'studio-asset-manifest.json').read_text())
root=E.Element('roblox',version='4')
items={}
for row in rows:
    item=E.SubElement(items.get(row.get('parent'),root),'Item',{'class':row['class'],'referent':row['id']})
    items[row['id']]=item
    props=E.SubElement(item,'Properties')
    for name,p in row['properties'].items():
        t,v=p['t'],p.get('v'); name={'Size':'size','MeshSize':'InitialSize'}.get(name,name)
        tag={'CFrame':'CoordinateFrame','Instance':'Ref','EnumItem':'token','boolean':'bool','number':'float'}.get(t,t)
        if name in ('MeshId','TextureID','ColorMap','NormalMap','MetalnessMap','RoughnessMap'):tag='Content'
        n=E.SubElement(props,tag,{'name':name})
        if t in ('Vector3','Color3','CFrame'):
            keys={'Vector3':['X','Y','Z'],'Color3':['R','G','B'],'CFrame':['X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22']}[t]
            for k,x in zip(keys,v):E.SubElement(n,k).text=str(x)
        elif tag=='Content':E.SubElement(n,'url').text=v
        else:n.text=('true' if v else 'false') if t=='boolean' else str(v)
E.indent(root)
E.ElementTree(root).write(out/'HammerBoss_NPC.rbxmx',encoding='utf-8',xml_declaration=True)
print('Packaged',len(rows),'instances')
