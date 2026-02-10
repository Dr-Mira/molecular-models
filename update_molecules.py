import json
import os
import glob
import zipfile
import xml.etree.ElementTree as ET
import warnings

# Suppress warnings
warnings.filterwarnings("ignore")

# --- Volume Calculation Logic ---
NS = {'m': 'http://schemas.microsoft.com/3dmanufacturing/core/2015/02'}
objects = {}

def get_volume_scale(transform_str):
    if not transform_str: return 1.0
    try:
        t = [float(x) for x in transform_str.split()]
        if len(t) != 12: return 1.0
        m00, m10, m20 = t[0], t[1], t[2]
        m01, m11, m21 = t[3], t[4], t[5]
        m02, m12, m22 = t[6], t[7], t[8]
        det = m00*(m11*m22 - m12*m21) - m01*(m10*m22 - m12*m20) + m02*(m10*m21 - m11*m20)
        return abs(det)
    except:
        return 1.0

def calc_tetrahedron_volume(p1, p2, p3):
    cx = p2[1]*p3[2] - p2[2]*p3[1]
    cy = p2[2]*p3[0] - p2[0]*p3[2]
    cz = p2[0]*p3[1] - p2[1]*p3[0]
    return (p1[0]*cx + p1[1]*cy + p1[2]*cz) / 6.0

def parse_mesh_volume(mesh_node):
    vertices = []
    verts_node = mesh_node.find('m:vertices', NS)
    if verts_node is None: return 0.0
    
    for v in verts_node.findall('m:vertex', NS):
        vertices.append((float(v.get('x')), float(v.get('y')), float(v.get('z'))))
        
    tris_node = mesh_node.find('m:triangles', NS)
    if tris_node is None: return 0.0
    
    vol = 0.0
    for t in tris_node.findall('m:triangle', NS):
        v1 = int(t.get('v1'))
        v2 = int(t.get('v2'))
        v3 = int(t.get('v3'))
        if v1 < len(vertices) and v2 < len(vertices) and v3 < len(vertices):
            vol += calc_tetrahedron_volume(vertices[v1], vertices[v2], vertices[v3])
            
    return abs(vol)

def process_file_content(z, filename):
    try:
        with z.open(filename) as f:
            try:
                tree = ET.parse(f)
                root = tree.getroot()
                
                # Check namespace
                if 'schemas.microsoft.com/3dmanufacturing/core' not in root.tag:
                    # Fallback or different namespace? Assume standard for now.
                    pass
                
                resources = root.find('m:resources', NS)
                if resources is not None:
                    for obj in resources.findall('m:object', NS):
                        oid = obj.get('id')
                        mesh = obj.find('m:mesh', NS)
                        if mesh is not None:
                            vol = parse_mesh_volume(mesh)
                            objects[oid] = {'type': 'mesh', 'vol': vol}
                        else:
                            comps_node = obj.find('m:components', NS)
                            if comps_node is not None:
                                comps = []
                                for c in comps_node.findall('m:component', NS):
                                    comps.append({
                                        'ref': c.get('objectid'),
                                        'trans': c.get('transform')
                                    })
                                objects[oid] = {'type': 'comp', 'children': comps}
            except ET.ParseError:
                pass
    except:
        pass

def get_base_volume(oid):
    if oid not in objects: return 0.0
    obj = objects[oid]
    if obj['type'] == 'mesh':
        return obj['vol']
    elif obj['type'] == 'comp':
        vol = 0.0
        for child in obj['children']:
            s = get_volume_scale(child['trans'])
            v = get_base_volume(child['ref'])
            vol += v * s
        return vol
    return 0.0

def calculate_weight(file_path):
    global objects
    objects = {} # Reset global objects per file
    build_items = []
    
    try:
        with zipfile.ZipFile(file_path, 'r') as z:
            model_files = [n for n in z.namelist() if n.endswith('.model')]
            for mf in model_files:
                process_file_content(z, mf)
            
            # Find build items in root model
            try:
                with z.open('3D/3dmodel.model') as f:
                    tree = ET.parse(f)
                    root = tree.getroot()
                    build = root.find('m:build', NS)
                    if build is not None:
                        for item in build.findall('m:item', NS):
                            build_items.append({
                                'ref': item.get('objectid'),
                                'trans': item.get('transform')
                            })
            except:
                pass
                
        total_mm3 = 0.0
        for item in build_items:
            s = get_volume_scale(item.get('trans'))
            v = get_base_volume(item.get('ref'))
            total_mm3 += v * s
            
        vol_cm3 = total_mm3 / 1000.0
        weight = vol_cm3 * 1.24 # PLA density
        return weight
    except Exception as e:
        # print(f"Error processing {file_path}: {e}")
        return None

# --- Main Update Logic ---

JSON_PATH = "c:\\MyDrive\\python\\molecular-models\\molecules.json"
BACKUP_DIR = "D:\\makerworld_backup\\molecules"

with open(JSON_PATH, 'r') as f:
    data = json.load(f)

print(f"Loaded {len(data['value'])} molecules.")

count = 0
updated = 0

for item in data['value']:
    name = item.get('name')
    pack = item.get('pack') # e.g. pack_01_alkanes
    
    # Try to find file
    # Pattern: D:\makerworld_backup\molecules\<pack>\<name>\*.3mf
    # But names match exactly?
    # User said: "molecules are named same as in the json"
    
    search_path = os.path.join(BACKUP_DIR, pack, name, "*.3mf")
    files = glob.glob(search_path)
    
    if not files:
        # Try checking just name folder
        # Maybe pack name is different?
        # But user said structure matches.
        # Check subfolders
        pass
    
    if files:
        # Pick the one that looks like a project file (not backup)
        # Prefers ones starting with number or _, avoids backups if possible?
        # Just pick the first one or the largest one.
        # inspect_3mf showed `1_butane.3mf` and `_1_cyclohexane.3mf`.
        # Just pick the first one.
        target_file = files[0]
        
        weight = calculate_weight(target_file)
        
        if weight is not None and weight > 0:
            formatted_weight = "{:.1f} g".format(weight)
            print(f"Updated {name}: {formatted_weight}")
            item['weight'] = formatted_weight
            updated += 1
        else:
            print(f"Failed to calculate weight for {name}")
    else:
        print(f"No 3mf file found for {name} in {search_path}")
    
    count += 1
    # if count > 5: break # Verification run

print(f"Updated {updated} molecules.")

# Save JSON
with open(JSON_PATH, 'w') as f:
    json.dump(data, f, indent=4)
print("Saved molecules.json")
