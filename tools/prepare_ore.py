"""Run with Blender 4.3.2 --background --python tools/prepare_ore.py -- SOURCE.glb.
Preserves the source; creates a mobile candidate and repeatable comparison renders.
"""
import bpy, sys, json, math
from pathlib import Path
from mathutils import Vector
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
source=Path(sys.argv[sys.argv.index('--')+1]).resolve()
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in meshes:o.select_set(True)
bpy.context.view_layer.objects.active=meshes[0]
bpy.ops.object.join(); original=bpy.context.object; original.name='IronOre_Source'
bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
# Blender uses Z up. Centre horizontally and put the lowest point on the ground.
coords=[original.matrix_world @ Vector(c) for c in original.bound_box]
lo=Vector(tuple(min(c[k] for c in coords) for k in range(3)));hi=Vector(tuple(max(c[k] for c in coords) for k in range(3)))
original.location-=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
original.scale*=1.25/(hi.z-lo.z)
bpy.ops.object.transform_apply(location=True,rotation=False,scale=True)
original_tri=sum(len(p.vertices)-2 for p in original.data.polygons)
model=original.copy();model.data=original.data.copy();bpy.context.collection.objects.link(model);model.name='IronOre'
model.data.materials.clear()
mat=original.data.materials[0].copy();model.data.materials.append(mat)
node=next(n for n in mat.node_tree.nodes if n.type=='TEX_IMAGE')
img=node.image.copy();node.image=img;img.name='IronOre_Colour'
pix=np.array(img.pixels[:],dtype=np.float32).reshape(img.size[1],img.size[0],4)
rgb=pix[:,:,:3]; mx=rgb.max(2);mn=rgb.min(2)
# A soft mask confines the correction to pale neutral/cool markings, protecting orange ore.
cool=np.clip((rgb[:,:,2]-rgb[:,:,0]+.015)/.06,0,1)
bright=np.clip((mx-.28)/.24,0,1)
neutral=np.clip((.28-(mx-mn))/.18,0,1)
mask=cool*bright*neutral
rgb*=1-.25*mask[:,:,None]
img.pixels.foreach_set(pix.ravel());img.update();img.scale(1024,1024)
bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
bsdf.inputs['Metallic'].default_value=0;bsdf.inputs['Roughness'].default_value=.95
bpy.ops.object.select_all(action='DESELECT');model.select_set(True);bpy.context.view_layer.objects.active=model
# Weld coincident import vertices before reduction so UV seams do not open as cracks.
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.remove_doubles(threshold=0.00001);bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
mod=model.modifiers.new('Mobile silhouette reduction','DECIMATE');mod.ratio=6000/original_tri;mod.use_collapse_triangulate=True
bpy.ops.object.modifier_apply(modifier=mod.name)
tri=sum(len(p.vertices)-2 for p in model.data.polygons)
# Keep the imported surface normals/smoothing policy; never smooth the silhouette away.
out=ROOT/'game/assets/models/ore/IronOre.glb'
bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',use_selection=True,export_image_format='JPEG',export_jpeg_quality=90,export_yup=True)
stats={'source':source.name,'source_bytes':source.stat().st_size,'source_triangles':original_tri,'output_bytes':out.stat().st_size,'output_triangles':tri,'texture_size':[1024,1024],'height_metres':1.25,'texture_change':'Soft 25% maximum attenuation of bright neutral/cool markings; orange protected. No claim of repaired UV stretch.'}
(ROOT/'art/ore-study/stats.json').write_text(json.dumps(stats,indent=2)+'\n');print('ORE_STATS',json.dumps(stats),flush=True)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24
scene.render.resolution_x=640;scene.render.resolution_y=640;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Studio');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.45,.45,.45,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
scene.view_settings.view_transform='Standard';scene.view_settings.look='Medium High Contrast' if 'Medium High Contrast' in [] else 'None'
for loc,power,size in [((3,-4,6),350,5),((-3,1,3),160,4)]:
 bpy.ops.object.light_add(type='AREA',location=loc);light=bpy.context.object;light.data.energy=power;light.data.shape='DISK';light.data.size=size;light.rotation_euler=(Vector((0,0,.6))-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=1.95;scene.camera=cam
for side,angle in [('front',-math.pi/2+.45),('back',math.pi/2+.45)]:
 cam.location=(3*math.cos(angle),3*math.sin(angle),1.9);cam.rotation_euler=(Vector((0,0,.65))-cam.location).to_track_quat('-Z','Y').to_euler()
 for label,show in [('original',original),('prepared',model)]:
  original.hide_render=show!=original;model.hide_render=show!=model
  scene.render.filepath=str(ROOT/'docs/preview/ore'/f'{label}-{side}.png');bpy.ops.render.render(write_still=True)
original.hide_render=True;model.hide_render=False
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/ore-study/IronOre-study.blend'))
