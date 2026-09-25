"""Blender 4.3: --background --python art/blender-ore-trial/generate.py
Original procedural geometry/materials; Meshy asset imported ONLY for comparison.
"""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[1]
random.seed(28)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32

def material(name, colours, scale):
 m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes;l=m.node_tree.links
 b=n.get('Principled BSDF');b.inputs['Roughness'].default_value=.88
 t=n.new('ShaderNodeTexNoise');t.inputs['Scale'].default_value=scale;t.inputs['Detail'].default_value=3;t.inputs['Roughness'].default_value=.7
 ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements.remove(ramp.color_ramp.elements[1])
 for i,(pos,col) in enumerate(colours):
  e=ramp.color_ramp.elements[0] if i==0 else ramp.color_ramp.elements.new(pos);e.position=pos;e.color=(*col,1)
 l.new(t.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs[0],b.inputs['Base Color'])
 return m
stone=material('Slate — mottled mineral',[(.18,(.035,.055,.067)),(.48,(.09,.125,.145)),(.8,(.20,.25,.27))],8)
edge=material('Weathered bevels',[(.2,(.09,.12,.13)),(.8,(.25,.30,.31))],14)
ore=material('Rust iron seams',[(.15,(.12,.035,.012)),(.46,(.34,.09,.018)),(.73,(.64,.24,.045)),(.9,(.30,.075,.012))],10)
parts=[]
def chunk(loc,size,mat,seed):
 rng=random.Random(seed)
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=loc)
 o=bpy.context.object
 for v in o.data.vertices:
  v.co*=rng.uniform(.87,1.12)
  v.co.z=max(v.co.z,-.76)
 o.scale=size;o.rotation_euler=(rng.uniform(-.15,.15),rng.uniform(-.2,.2),rng.uniform(-.6,.6))
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(mat);o.data.materials.append(edge if mat==stone else ore)
 bevel=o.modifiers.new('Soft chipped edges','BEVEL');bevel.width=.012;bevel.segments=1;bevel.affect='EDGES';bevel.limit_method='ANGLE';bevel.angle_limit=.65;bevel.material=1
 bpy.ops.object.modifier_apply(modifier=bevel.name)
 parts.append(o)
# Overlapping orange cores show through channels between the slate plates.
chunk((0,.02,.57),(.35,.25,.64),ore,7)
chunk((.20,-.03,.40),(.33,.25,.39),ore,11)
for i,(loc,size) in enumerate([
 ((-.15,.03,.88),(.30,.29,.48)),((.29,.07,.68),(.25,.27,.44)),
 ((-.32,-.13,.46),(.23,.26,.35)),((.11,-.28,.37),(.24,.18,.30)),
 ((-.04,-.23,.73),(.24,.20,.34)),((.36,-.12,.25),(.20,.23,.23)),
 ((-.31,.18,.22),(.25,.23,.25)),((.12,.28,.45),(.27,.20,.34)),
 ((-.16,-.33,.17),(.23,.17,.20)),((.03,.05,1.12),(.24,.23,.23))]):chunk(loc,size,stone,50+i)
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();model=bpy.context.object;model.name='BlenderIronOre'
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
lo=min(v.co.z for v in model.data.vertices);hi=max(v.co.z for v in model.data.vertices)
for v in model.data.vertices:v.co.z-=lo;v.co*=1.25/(hi-lo)
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.025);bpy.ops.object.mode_set(mode='OBJECT')
# Bake base colour only: no fixed directional light or runtime procedural shader.
img=bpy.data.images.new('BlenderOre_Colour',width=1024,height=1024)
for m in set(model.data.materials):
 n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=img;m.node_tree.nodes.active=n
scene.render.bake.use_pass_direct=False;scene.render.bake.use_pass_indirect=False;scene.render.bake.use_pass_color=True;scene.render.bake.margin=12
bpy.ops.object.bake(type='DIFFUSE')
mat=bpy.data.materials.new('Baked slate and iron');mat.use_nodes=True
n=mat.node_tree.nodes.new('ShaderNodeTexImage');n.image=img;mat.node_tree.links.new(n.outputs['Color'],mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color']);mat.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.9
model.data.materials.clear();model.data.materials.append(mat)
for p in model.data.polygons:p.material_index=0
bpy.ops.export_scene.gltf(filepath=str(OUT/'BlenderIronOre.glb'),export_format='GLB',use_selection=True,export_image_format='JPEG',export_jpeg_quality=90)
tri=sum(len(p.vertices)-2 for p in model.data.polygons)
(OUT/'stats.json').write_text(json.dumps({'triangles':tri,'glb_bytes':(OUT/'BlenderIronOre.glb').stat().st_size,'texture':[1024,1024],'height_metres':1.25,'method':'Original scripted meshes and noise materials, baked colour. No generative AI asset input.'},indent=2))
# Save editable native asset before bringing in the comparison asset.
img.pack();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'BlenderIronOre.blend'))
bpy.ops.import_scene.gltf(filepath=str(ROOT/'game/assets/models/ore/IronOre.glb'))
others=[o for o in scene.objects if o.type=='MESH' and o!=model]
# Normalize imported comparison geometry to the same measured height and floor.
coords=[o.matrix_world @ v.co for o in others for v in o.data.vertices]
lo=Vector(tuple(min(v[k] for v in coords) for k in range(3)))
hi=Vector(tuple(max(v[k] for v in coords) for k in range(3)))
centre=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
for o in others:
 world=o.matrix_world.copy()
 for v in o.data.vertices:v.co=(world @ v.co-centre)*(1.25/(hi.z-lo.z))
 o.matrix_world.identity()
scene.world=bpy.data.worlds.new('Studio');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.45,.45,.45,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
for loc,power,size in [((3,-4,6),350,5),((-3,1,3),160,4)]:
 bpy.ops.object.light_add(type='AREA',location=loc);light=bpy.context.object;light.data.energy=power;light.data.shape='DISK';light.data.size=size;light.rotation_euler=(Vector((0,0,.6))-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=1.95;scene.camera=cam
scene.render.resolution_x=640;scene.render.resolution_y=640;scene.render.resolution_percentage=100
for side,angle in [('front',-math.pi/2+.45),('back',math.pi/2+.45)]:
 cam.location=(3*math.cos(angle),3*math.sin(angle),1.9);cam.rotation_euler=(Vector((0,0,.65))-cam.location).to_track_quat('-Z','Y').to_euler()
 for label in ['blender','meshy']:
  model.hide_render=label!='blender'
  for o in others:o.hide_render=label!='meshy'
  scene.render.filepath=str(OUT/f'{label}-{side}.png');bpy.ops.render.render(write_still=True)
print('COMPLETE',tri)
