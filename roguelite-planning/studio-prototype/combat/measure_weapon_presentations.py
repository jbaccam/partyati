"""Measure corrected combat bounds from reviewed GLB vertices, not tilted boxes."""
import json
import math
import struct
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[2] / 'weapon-models' / 'assets'
SPECS = {'06': ('06-baseball-bat', 0, -math.degrees(.66)), '01': ('01-frying-pan', -90, 90), '12': ('12-boomerang', 0, 180),
         '13': ('13-kunais', 0, 180), '26': ('26-shovel', 0, 180-math.degrees(.24)),
         '30': ('30-magic-staff', 90, 39), '32': ('32-excalibur', 0, 48)}

def points(path):
    blob = path.read_bytes()
    length = struct.unpack_from('<I', blob, 12)[0]
    data = json.loads(blob[20:20+length])
    binary = blob[28+length:]
    result = []
    def visit(index, parent):
        node = data['nodes'][index]
        if 'matrix' in node:
            local = np.array(node['matrix']).reshape(4, 4).T
        else:
            x,y,z,w = node.get('rotation', [0,0,0,1])
            local = np.eye(4)
            local[:3,:3] = np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],
                [2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],
                [2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]]) @ np.diag(node.get('scale',[1,1,1]))
            local[:3,3] = node.get('translation',[0,0,0])
        world = parent @ local
        if 'mesh' in node:
            for primitive in data['meshes'][node['mesh']]['primitives']:
                a = data['accessors'][primitive['attributes']['POSITION']]
                assert a['componentType']==5126 and a['type']=='VEC3' and 'sparse' not in a
                v = data['bufferViews'][a['bufferView']]
                xyz = np.ndarray((a['count'],3),dtype='<f4',buffer=binary,
                    offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',12),4))
                result.append(xyz @ world[:3,:3].T + world[:3,3])
        for child in node.get('children',[]): visit(child,world)
    for index in data['scenes'][data.get('scene',0)]['nodes']: visit(index,np.eye(4))
    # GLB is Y-up; native Studio FBX geometry mirrors X and GLB Z.
    return np.concatenate(result) * [-1,1,-1]

def measure():
    result = {}
    for key,(folder,yaw,roll) in SPECS.items():
        p = points(ROOT/folder/'Model.glb')
        lo,hi = p.min(axis=0),p.max(axis=0)
        diagonal = np.linalg.norm(hi-lo)
        p = (p-(lo+hi)/2)/diagonal
        y,z = math.radians(yaw),math.radians(roll)
        ry = np.array([[math.cos(y),0,math.sin(y)],[0,1,0],[-math.sin(y),0,math.cos(y)]])
        rz = np.array([[math.cos(z),-math.sin(z),0],[math.sin(z),math.cos(z),0],[0,0,1]])
        p = p @ (ry@rz).T
        lo,hi = p.min(axis=0),p.max(axis=0)
        result[key] = dict(yaw=yaw,roll=roll,center=((lo+hi)/2).tolist(),size=(hi-lo).tolist(),originalProportions=((points(ROOT/folder/'Model.glb').max(axis=0)-points(ROOT/folder/'Model.glb').min(axis=0))/diagonal).tolist())
    return result

if __name__=='__main__':
    result = measure()
    Path(__file__).with_name('weapon-presentation-bounds.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result))
