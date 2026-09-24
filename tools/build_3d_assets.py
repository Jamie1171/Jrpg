"""Original stylised JRPG meshes, built and rigged in Blender.

Run: blender --background --python tools/build_3d_assets.py
The .blend source and GLB runtime meshes are generated together. No paid services.
All dimensions are metres; Blender -Y becomes the character's Godot +Z front.
"""
import bpy
import math
import random
import json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "game/assets/models"
SOURCE = ROOT / "art/blender"
OUT.mkdir(parents=True, exist_ok=True)
SOURCE.mkdir(parents=True, exist_ok=True)
random.seed(74)
parts = []
stats = {}
mat = None

C = {
    'skin':'e8b18a','skin_shade':'cd876f','hair':'483026','hair_light':'6b4532',
    'cream':'f0e0b6','teal':'2b868a','teal_dark':'205762','gold':'e4b45b',
    'leather':'744632','boot':'42352e','pants':'494a54','white':'fff5d7','ink':'283544',
    'wood':'986443','wood_dark':'593d32','wood_light':'c79358','plaster':'f4dbaa',
    'roof':'3e7281','roof_light':'568fa0','stone':'b2aaa0','stone_dark':'8b827c',
    'leaf':'5c9c4b','leaf_light':'8bb953','leaf_dark':'347556','red':'b95945',
}

def color(hexcode):
    value = C.get(hexcode, hexcode)
    srgb = [int(value[i:i+2], 16) / 255 for i in (0,2,4)]
    return tuple(v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4 for v in srgb) + (1,)

def material():
    global mat
    mat = bpy.data.materials.new('Dawn_VertexPalette')
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Roughness'].default_value = 0.88
    attr = mat.node_tree.nodes.new('ShaderNodeVertexColor')
    attr.layer_name = 'Color'
    mat.node_tree.links.new(attr.outputs['Color'], bsdf.inputs['Base Color'])

def begin():
    global parts
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions): bpy.data.actions.remove(action)
    parts = []
    material()

def finish(obj, shade, bone=None, smooth=False):
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    attr = obj.data.color_attributes.new(name='Color', type='FLOAT_COLOR', domain='CORNER')
    rgb = color(shade)
    # Small face-dependent variation is deliberately vertex colour, not a claim of baked AO.
    for poly in obj.data.polygons:
        factor = 0.96 + 0.04 * max(0, poly.normal.z)
        for loop in poly.loop_indices:
            attr.data[loop].color = (rgb[0]*factor,rgb[1]*factor,rgb[2]*factor,1)
        poly.use_smooth = smooth
    if bone:
        group = obj.vertex_groups.new(name=bone)
        group.add(list(range(len(obj.data.vertices))), 1, 'REPLACE')
    parts.append(obj)
    return obj

def mesh(name, vertices, faces, shade, bone=None, smooth=False):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(obj)
    return finish(obj,shade,bone,smooth)

def cube(name, location, scale, shade, bone=None, bevel=0, rotation=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        modifier = obj.modifiers.new('Soft crafted edges','BEVEL')
        modifier.width = bevel
        modifier.segments = 1
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    if rotation:
        obj.rotation_euler = rotation
    return finish(obj,shade,bone)

def oval(name, location, scale, shade, bone=None, segments=12, rings=8, smooth=True):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1, location=location)
    obj=bpy.context.object
    obj.name=name
    obj.scale=scale
    return finish(obj,shade,bone,smooth)

def ico(name,location,scale,shade,subdiv=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv,radius=1,location=location)
    obj=bpy.context.object
    obj.name=name
    obj.scale=scale
    return finish(obj,shade)

def rod(name,a,b,radius,shade,bone=None,vertices=8,radius2=None):
    a,b=Vector(a),Vector(b)
    bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=radius,radius2=radius if radius2 is None else radius2,depth=(b-a).length,location=(a+b)/2)
    obj=bpy.context.object
    obj.name=name
    obj.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    return finish(obj,shade,bone)

def rings_mesh(name,levels,shade,bone=None,segments=12,smooth=True):
    verts=[]
    for z,rx,ry,cx,cy in levels:
        for i in range(segments):
            angle=math.tau*i/segments
            verts.append((cx+rx*math.cos(angle),cy+ry*math.sin(angle),z))
    faces=[tuple(reversed(range(segments)))]
    for row in range(len(levels)-1):
        for i in range(segments):
            a=row*segments+i;b=row*segments+(i+1)%segments
            faces.append((a,b,b+segments,a+segments))
    faces.append(tuple(range((len(levels)-1)*segments,len(levels)*segments)))
    return mesh(name,verts,faces,shade,bone,smooth)

def combine(name):
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts:p.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join()
    obj=bpy.context.object
    obj.name=name
    bpy.context.scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    # All meshes share the same vertex-colour material: one surface per asset.
    obj.data.materials.clear();obj.data.materials.append(mat)
    for p in obj.data.polygons:p.material_index=0
    obj.data.calc_loop_triangles()
    stats[name]={'triangles':len(obj.data.loop_triangles),'vertices':len(obj.data.vertices),'surfaces':1}
    return obj

def export(name,blend=False):
    if blend:
        bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/(name+'.blend')),compress=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',export_yup=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_frame_range=False,export_skins=True,export_materials='EXPORT',export_cameras=False,export_lights=False)

def character(name,coat,hair,skin='skin',female=False,elder=False,armour=False,hood=False):
    begin()
    shirt='cream' if not armour else 'c6d7da'
    # Five-and-a-half head proportions: readable, stylised adults, not chibi figures.
    rings_mesh('Tunic',[(.87,.16,.105,0,0),(1.05,.175,.11,0,0),(1.29,.225,.115,0,0),(1.40,.205,.105,0,0),(1.45,.085,.08,0,0)],shirt,'spine')
    rod('Neck',(0,0,1.39),(0,0,1.51),.067,skin,'head',12)
    rings_mesh('Face',[(1.45,.055,.063,0,-.018),(1.49,.105,.091,0,-.009),(1.58,.139,.12,0,0),(1.67,.144,.115,0,.006),(1.75,.108,.09,0,.009),(1.785,.02,.02,0,.006)],skin,'head',16)
    for side in [-1,1]:
        oval('Ear',(side*.145,0,1.59),(.031,.025,.051),skin,'head',8,6)
        oval('Eye white',(side*.060,-.109,1.634),(.044,.018,.028),'white','head',12,6)
        oval('Iris',(side*.060,-.127,1.634),(.015,.006,.022),'395563' if name!='Cael' else '536555','head',10,6)
        oval('Pupil',(side*.060,-.132,1.634),(.007,.003,.015),'ink','head',8,6)
        oval('Eye shine',(side*.055,-.135,1.642),(.005,.002,.006),'white','head',6,4)
        rod('Brow',(side*.028,-.122,1.680),(side*.100,-.106,1.683 if side<0 else 1.676),.008,hair,'head',6)
        rod('Upper eyelid',(side*.025,-.122,1.653),(side*.095,-.118,1.656),.004,hair,'head',5)
    mesh('Nose',[(-.023,-.105,1.61),(.023,-.105,1.61),(0,-.163,1.566),(0,-.113,1.55)],[(0,1,2),(0,2,3),(1,3,2)],skin,'head',True)
    rod('Mouth',(-.029,-.100,1.516),(.030,-.101,1.517),.004,'995e58','head',6)
    # A fitted hair cap with individual tapered locks; the face stays unobstructed.
    oval('Hair cap',(0,.015,1.731),(.15,.12,.09),hair,'head',16,8)
    for i in range(11):
        a=math.tau*i/11
        x,y=.117*math.cos(a),.095*math.sin(a)
        z=1.72+(i%3)*.008
        length=.08 if y>0 else .095
        mesh('Hair lock',[(x-.035,y+.008,z+.045),(x+.035,y+.008,z+.04),(x,y-.025,z+.035),(x*.98,y*1.13,z-length)],[(0,1,2),(0,3,1),(1,3,2),(2,3,0)],hair,'head')
    if female or elder:
        for i in range(6):oval('Braided hair',(.085,.104,1.57-i*.07),(.042,.035,.048),hair,'spine',8,5)
    if hood:
        # Open-faced cowl, an arc rather than a sphere covering the face.
        for i in range(9):
            a=math.pi*i/8
            oval('Hood fold',(.178*math.cos(a),.020,1.57+.225*math.sin(a)),(.056,.115,.062),coat,'head',8,6)
    if elder and not female:
        rings_mesh('Beard',[(1.43,.025,.04,0,-.057),(1.48,.081,.061,0,-.061),(1.54,.112,.043,0,-.079)],hair,'head',12)
        oval('Fisher cap',(0,.007,1.757),(.157,.126,.055),'ink','head',12,6)
        cube('Cap brim',(0,-.125,1.72),(.23,.13,.018),'ink','head',.02)
    # Garments and leather details.
    if female:
        rings_mesh('Skirt',[(.20,.29,.20,0,0),(.38,.28,.18,0,0),(.74,.21,.13,0,0),(.91,.16,.10,0,0)],'a96647' if name=='Mira' else coat,'hips',16)
        mesh('Apron',[(-.15,-.12,1.37),(.15,-.12,1.37),(.17,-.128,.9),(.25,-.182,.28),(-.25,-.182,.28),(-.17,-.128,.9)],[(0,1,2,5),(5,2,3,4)],coat,'spine')
    else:
        rings_mesh('Belt',[(.91,.175,.115,0,0),(.965,.18,.118,0,0)],'leather','hips',12)
        cube('Buckle',(0,-.12,.94),(.070,.025,.058),'gold','hips',.009)
    if armour:
        rings_mesh('Cuirass',[(1.0,.17,.119,0,0),(1.25,.229,.134,0,0),(1.39,.20,.12,0,0)],'c6d7da','spine')
        rings_mesh('Scarf',[(1.39,.17,.116,0,-.003),(1.44,.115,.101,0,0)],'red','spine',12)
        mesh('Scarf tail',[(.07,.08,1.40),(.16,.09,1.41),(.24,.17,.98),(.11,.18,1.05)],[(0,1,2,3)],'red','spine')
    elif name in ['Rowan','Ysra']:
        mesh('Cloak',[(-.22,.025,1.42),(.22,.025,1.42),(.25,.145,1.21),(.27,.17,.90),(.10,.20,.85),(-.12,.20,.86),(-.27,.17,.91),(-.25,.145,1.21),(0,.155,1.37)],[(0,1,8),(1,2,8),(2,3,4,8),(4,5,8),(5,6,7,8),(7,0,8)],coat,'spine',True)
        mesh('Cloak collar',[(-.23,-.035,1.4),(-.05,-.122,1.35),(.09,-.115,1.41),(.22,-.01,1.42),(0,.12,1.45)],[(0,1,4),(1,2,4),(2,3,4)],coat,'spine')
        oval('Cloak clasp',(-.07,-.124,1.367),(.019,.010,.019),'gold','spine',8,5)
    elif not female:
        for side in [-1,1]:cube('Waistcoat',(side*.145,-.02,1.2),(.10,.23,.32),coat,'spine',.02)
    # The arms use named vertex groups and real skeleton joints.
    for side,suffix in [(-1,'L'),(1,'R')]:
        shoulder=(side*.222,0,1.365);elbow=(side*.288,0,1.092);wrist=(side*.277,-.023,.862)
        rod('Upper sleeve',shoulder,elbow,.086,shirt,'upper_arm.'+suffix,10,radius2=.063)
        oval('Shoulder',shoulder,(.090,.095,.09),coat if not armour else 'a7b8bf','upper_arm.'+suffix,10,6)
        rod('Forearm',elbow,wrist,.056,skin,'forearm.'+suffix,10,radius2=.046)
        rod('Wrist wrap',(side*.278,-.021,.9),wrist,.052,'leather','forearm.'+suffix,8)
        oval('Hand',(side*.277,-.025,.818),(.048,.04,.06),skin,'forearm.'+suffix,8,6)
        if not female:
            rod('Trouser thigh',(side*.102,0,.90),(side*.112,0,.50),.093,'pants','thigh.'+suffix,10,radius2=.066)
            rod('Trouser shin',(side*.112,0,.50),(side*.11,0,.16),.065,'pants','shin.'+suffix,10,radius2=.052)
        rod('Boot cuff',(side*.11,0,.16),(side*.11,0,.36 if not female else .21),.070,'leather','shin.'+suffix,10)
        cube('Boot',(side*.11,-.06,.095),(.145,.265,.15),'boot','shin.'+suffix,.035)
        cube('Sole',(side*.11,-.065,.029),(.154,.276,.042),'leather','shin.'+suffix,.01)
    if name in ['Rowan','Ysra']:
        cube('Satchel',(.218,-.033,1.012),(.19,.15,.20),'leather','hips',.022)
        cube('Satchel flap',(.218,-.118,1.057),(.194,.016,.13),'wood_light','hips',.012)
        cube('Satchel catch',(.218,-.13,1.025),(.03,.012,.045),'gold','hips',.004)
        rod('Cross-body strap',(-.18,-.13,1.40),(.23,-.137,1.02),.018,'leather','spine',6)
    if name in ['Rowan','Cael']:
        rod('Scabbard',(-.20,.09,.93),(-.29,.11,.37),.031,'teal_dark','hips',6,radius2=.02)
        rod('Sword grip',(-.18,.09,1.10),(-.20,.09,.93),.022,'leather','hips',8)
        rod('Sword guard',(-.28,.09,.96),(-.12,.09,.94),.015,'gold','hips',6)
    body=combine(name+'_Mesh')
    armdata=bpy.data.armatures.new(name+'_Skeleton')
    rig=bpy.data.objects.new(name,armdata)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bones=[('hips',(0,0,.88),(0,0,1.05),None),('spine',(0,0,1.05),(0,0,1.42),'hips'),('head',(0,0,1.42),(0,0,1.76),'spine')]
    for side,suffix in [(-1,'L'),(1,'R')]:
        bones += [('upper_arm.'+suffix,(side*.222,0,1.365),(side*.288,0,1.092),'spine'),('forearm.'+suffix,(side*.288,0,1.092),(side*.277,-.023,.862),'upper_arm.'+suffix),('thigh.'+suffix,(side*.102,0,.90),(side*.112,0,.50),'hips'),('shin.'+suffix,(side*.112,0,.50),(side*.11,0,.10),'thigh.'+suffix)]
    for label,head,tail,parent in bones:
        bone=armdata.edit_bones.new(label);bone.head=head;bone.tail=tail
        if parent:bone.parent=armdata.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    body.parent=rig
    modifier=body.modifiers.new('Dawn rig','ARMATURE');modifier.object=rig
    rig.animation_data_create()
    for action_name in ['idle','walk','attack']:
        action=bpy.data.actions.new(action_name)
        rig.animation_data.action=action
        duration=32 if action_name=='walk' else 60 if action_name=='idle' else 24
        for frame in range(1,duration+2,4):
            phase=(frame-1)/duration*math.tau
            for bone in rig.pose.bones:
                bone.rotation_mode='XYZ';bone.rotation_euler=(0,0,0);bone.location=(0,0,0)
            if action_name=='walk':
                for suffix,sign in [('L',1),('R',-1)]:
                    wave=math.sin(phase)*sign
                    rig.pose.bones['thigh.'+suffix].rotation_euler.x=.47*wave
                    rig.pose.bones['shin.'+suffix].rotation_euler.x=max(0,-wave)*.48
                    rig.pose.bones['upper_arm.'+suffix].rotation_euler.x=-.35*wave
                    rig.pose.bones['forearm.'+suffix].rotation_euler.x=-.12
                rig.pose.bones['hips'].location.y=.024*abs(math.sin(phase))
                rig.pose.bones['spine'].rotation_euler.y=.04*math.sin(phase)
            elif action_name=='idle':
                rig.pose.bones['spine'].rotation_euler.x=.015*math.sin(phase)
                rig.pose.bones['head'].rotation_euler.z=.022*math.sin(phase)
            else:
                strike=math.sin((frame-1)/duration*math.pi)
                rig.pose.bones['upper_arm.R'].rotation_euler.x=-1.0*strike
                rig.pose.bones['forearm.R'].rotation_euler.x=-.4*strike
                rig.pose.bones['spine'].rotation_euler.y=-.32*strike
            for bone in rig.pose.bones:
                bone.keyframe_insert(data_path='rotation_euler',frame=frame)
                bone.keyframe_insert(data_path='location',frame=frame)
        action.use_fake_user=True
    rig.animation_data.action=bpy.data.actions.get('idle')
    bpy.context.scene.frame_set(1)
    stats[name]=stats.pop(name+'_Mesh')
    stats[name]['bones']=len(bones)
    export(name,True)

def build_prop(name,callback):
    global parts
    parts=[]
    callback()
    obj=combine(name)
    return obj

def roof():
    mesh('Roof', [(-1,-1,0),(1,-1,0),(1,1,0),(-1,1,0),(0,-1,.8),(0,1,.8)],[(0,1,4),(3,5,2),(0,4,5,3),(4,1,2,5),(0,3,2,1)],'roof')
    for side in [-1,1]:
        for step in range(1,5):
            x=side*step/5
            rod('Tile course',(x,-1.025,.8*(1-abs(x))+.008),(x,1.025,.8*(1-abs(x))+.008),.018,'roof_light',vertices=5)
    rod('Roof ridge',(0,-1.05,.81),(0,1.05,.81),.04,'roof_light',vertices=6)

def tree():
    rod('Trunk',(0,0,0),(.1,.02,2.8),.23,'wood_dark',vertices=7,radius2=.10)
    for a in [0,2.1,4.2]:rod('Branch',(.05,0,1.8),(.8*math.cos(a),.8*math.sin(a),3.1),.1,'wood',vertices=6,radius2=.045)
    for pos,scale,shade in [((0,0,3.5),(1.35,1.22,1.4),'leaf'),((.7,0,3.02),(1.02,1.04,.90),'leaf_light'),((-.75,.2,2.94),(.95,1.04,.9),'leaf_dark'),((0,-.66,3.25),(1.05,.92,1.06),'leaf'),((-.2,0,4.22),(.76,.78,.9),'leaf_light')]:ico('Leaves',pos,scale,shade,2)

def window():
    cube('Window inset',(0,0,0),(.9,.12,1.2),'wood_dark',bevel=.03)
    cube('Glass',(0,-.075,0),(.70,.02,.98),'87b9b0')
    for x in [-.43,0,.43]:cube('Mullion',(x,-.11,0),(.055,.07,1.24),'wood_light')
    for z in [-.60,0,.60]:cube('Rail',(0,-.11,z),(.94,.07,.055),'wood_light')
    cube('Window sill',(0,-.13,-.66),(1.08,.38,.12),'wood_dark',bevel=.02)
    for side in [-1,1]:cube('Shutter',(side*.64,-.03,0),(.30,.09,1.15),'teal',bevel=.025)

def door():
    cube('Door',(0,0,.98),(1.15,.13,1.96),'wood_dark',bevel=.04)
    for i in range(6):cube('Door boards',(-.46+i*.185,-.076,.98),(.169,.025,1.82),'wood')
    for z in [.23,1.45]:cube('Iron hinge',(0,-.097,z),(1.06,.03,.065),'ink')
    oval('Door handle',(.37,-.15,.88),(.065,.033,.065),'gold',segments=8,rings=5)

def crate():
    cube('Crate core',(0,0,.45),(.90,.90,.90),'wood',bevel=.02)
    for axis in [0,1]:
        for side in [-1,1]:
            for line in [-.35,.35]:
                location=[line,side*.463,.45] if axis==0 else [side*.463,line,.45]
                cube('Crate edge',location,(.07,.07,.9),'wood_light')
    for z in [.08,.82]:
        for side in [-1,1]:cube('Crate rim',(0,side*.46,z),(.9,.06,.09),'wood_light')

def barrel():
    rings_mesh('Staves',[(0,.32,.32,0,0),(.15,.39,.39,0,0),(.5,.43,.43,0,0),(.85,.39,.39,0,0),(1,.32,.32,0,0)],'wood',segments=12,smooth=False)
    for z,r in [(.17,.399),(.8,.409)]:rings_mesh('Hoop',[(z,r,r,0,0),(z+.08,r,r,0,0)],'ink',segments=12,smooth=False)
    cube('Lid',(0,0,1.012),(.55,.55,.04),'wood_light',bevel=.08)

def bench():
    cube('Seat',(0,0,.47),(1.8,.45,.12),'wood_light',bevel=.03)
    for x in [-.65,.65]:cube('Leg',(x,0,.23),(.16,.40,.46),'wood_dark')

def fence():
    for x in [-1,1]:rod('Fence post',(x,0,0),(x,0,1.28),.1,'wood',vertices=5,radius2=.055)
    for z in [.45,.94]:cube('Fence rail',(0,0,z),(2.12,.12,.14),'wood_light',bevel=.02)

def well():
    n=16
    verts=[]
    for z,r in [(0,1.0),(.75,1.0),(.75,.70),(.1,.70)]:
        for i in range(n):verts.append((r*math.cos(i*math.tau/n),r*math.sin(i*math.tau/n),z))
    faces=[]
    for k in range(3):
        for i in range(n):faces.append((k*n+i,k*n+(i+1)%n,(k+1)*n+(i+1)%n,(k+1)*n+i))
    mesh('Well stones',verts,faces,'stone')
    for x in [-.9,.9]:cube('Well post',(x,0,1.45),(.15,.18,2.9),'wood_dark')
    rod('Axle',(-1.13,0,2.35),(1.13,0,2.35),.085,'wood',vertices=8)
    rod('Rope',(0,0,2.32),(0,0,.44),.02,'cream',vertices=6)

def lantern():
    cube('Lantern glass',(0,0,.3),(.28,.28,.42),'ffd584',bevel=.03)
    for x in [-.15,.15]:
        for y in [-.15,.15]:rod('Lantern frame',(x,y,.06),(x,y,.54),.018,'ink',vertices=5)
    cube('Lantern base',(0,0,.06),(.36,.36,.08),'ink',bevel=.025)
    bpy.ops.mesh.primitive_cone_add(vertices=4,radius1=.28,radius2=.08,depth=.18,location=(0,0,.61),rotation=(0,0,math.pi/4))
    finish(bpy.context.object,'ink')

def market(shade):
    for x in [-1.25,1.25]:
        for y in [-.7,.7]:rod('Market post',(x,y,0),(x,y,2.45),.065,'wood_dark',vertices=6)
    cube('Counter',(0,-.4,.82),(2.6,1.1,.20),'wood_light',bevel=.04)
    for i in range(7):
        x=-1.5+i*.43
        mesh('Awning',[(x,-1.1,2.12),(x+.43,-1.1,2.12),(x+.43,.8,2.58),(x,.8,2.58),(x,-1.1,1.95),(x+.43,-1.1,1.95)],[(0,1,2,3),(0,4,5,1)],shade if i%2==0 else 'cream')
    for i in range(9):oval('Produce',(-.9+(i%5)*.4,-.45+(i//5)*.4,1.02),(.15,.14,.14),'red' if i%2 else 'gold',segments=8,rings=5)

def cart():
    cube('Cart bed',(0,0,.60),(1.6,2,.16),'wood',bevel=.035)
    for side in [-1,1]:
        for z in [.78,1.03]:cube('Side slat',(side*.79,0,z),(.10,2.1,.16),'wood_light')
        rod('Shaft',(side*.52,-.5,.52),(side*.52,-2.9,.70),.06,'wood_dark')
        bpy.ops.mesh.primitive_torus_add(major_radius=.45,minor_radius=.055,major_segments=16,minor_segments=6,location=(side*.94,.1,.51),rotation=(0,math.pi/2,0))
        finish(bpy.context.object,'wood_dark')
        for a in [0,math.pi/3,2*math.pi/3]:
            rod('Spoke',(side*.94,.1-math.cos(a)*.43,.51-math.sin(a)*.43),(side*.94,.1+math.cos(a)*.43,.51+math.sin(a)*.43),.025,'wood_light',vertices=5)
    cube('Oil crate',(0,.20,.93),(1.10,1.15,.55),'wood_dark',bevel=.04)
    cube('Delivery cloth',(.05,.05,1.23),(1.17,.80,.04),'red',bevel=.025)

def boar():
    oval('Body',(0,.05,.68),(.52,.73,.48),'66503c',segments=12,rings=8)
    oval('Head',(0,-.64,.60),(.34,.40,.34),'584534',segments=12,rings=8)
    oval('Snout',(0,-.96,.46),(.27,.16,.18),'947261',segments=10,rings=6)
    for side in [-1,1]:
        oval('Nostril',(side*.11,-1.09,.49),(.047,.018,.035),'ink',segments=8,rings=4)
        oval('Eye',(side*.255,-.79,.72),(.038,.039,.038),'gold',segments=8,rings=6)
        oval('Pupil',(side*.26,-.819,.724),(.021,.014,.025),'ink',segments=8,rings=4)
        mesh('Ear',[(side*.22,-.53,.85),(side*.45,-.44,1.1),(side*.43,-.64,.91),(side*.24,-.70,.80)],[(0,1,2),(0,2,3)],'wood_dark')
        rod('Tusk',(side*.20,-.87,.39),(side*.31,-1.01,.70),.057,'cream',vertices=7,radius2=.006)
        for y in [-.43,.50]:
            rod('Leg',(side*.31,y,.48),(side*.35,y,.12),.10,'wood_dark',vertices=8,radius2=.065)
            cube('Hoof',(side*.35,y-.025,.065),(.16,.21,.12),'ink',bevel=.02)
    for x,y,z in [(-.22,0,1.04),(.20,.2,1.08),(0,-.29,1.02),(.05,.52,1.02)]:ico('Moss',(x,y,z),(.27,.33,.14),'leaf',1)

def grass():
    for i in range(7):
        angle=i*2.4
        x,y=math.cos(angle)*.18,math.sin(angle)*.18
        h=.17+(i%3)*.08
        mesh('Grass blade',[(x-.035,y,0),(x+.035,y,0),(x+.07,y+.04,h)],[(0,1,2)],'leaf' if i%2 else 'leaf_light')

def flower():
    rod('Stem',(0,0,0),(0,0,.34),.015,'leaf_dark',vertices=5)
    for a in range(5):
        angle=a*math.tau/5
        oval('Petal',(.065*math.cos(angle),.065*math.sin(angle),.34),(.065,.065,.025),'cream',segments=6,rings=4)
    oval('Pollen',(0,0,.355),(.04,.04,.025),'gold',segments=6,rings=4)

def table():
    for x in [-.80,.80]:
        for y in [-.53,.53]:cube('Table leg',(x,y,.4),(.12,.12,.8),'wood_dark')
    for i in range(5):cube('Table plank',(0,-.60+i*.3,.84),(2,.283,.12),'wood_light',bevel=.02)

def kit():
    begin()
    props=[]
    callbacks={
        'wall':lambda:cube('Plaster',(0,0,.5),(1,1,1),'plaster',bevel=.012),
        'beam':lambda:cube('Beam',(0,0,.5),(1,1,1),'wood_dark',bevel=.01),
        'grass':grass,'flower':flower,'table':table,'hill':lambda:ico('Hill',(0,0,.0),(1,1,1),'leaf_dark',2),
        'roof':roof,'tree':tree,'window':window,'door':door,'crate':crate,'barrel':barrel,
        'bench':bench,'fence':fence,'well':well,'lantern':lantern,'market_red':lambda:market('red'),
        'market_gold':lambda:market('gold'),'cart':cart,'mossback':boar,
        'rock':lambda:ico('Rock',(0,0,.30),(.70,.55,.55),'stone',1),
        'bush':lambda:ico('Bush',(0,0,.45),(.85,.65,.70),'leaf_light',2),
        'paver':lambda:rod('Paver',(0,0,0),(0,0,.055),.49,'stone',vertices=6),
    }
    for name,callback in callbacks.items():props.append(build_prop(name,callback))
    # Each named prop stays separate in the source kit. Runtime batching preserves reuse.
    export('Brackenford_Kit',True)

character('Rowan','teal','hair')
character('Cael','red','c4974f',armour=True)
character('Mira','547849','9b5a36',female=True)
character('Tessa','566b97','b5aea2',female=True,elder=True)
character('Ysra','795875','hair','c99b7d',female=True,hood=True)
character('Orren','a9683f','ded6bc',elder=True)
character('Petra','c87944','hair','c59777',female=True)
kit()
(OUT/'mesh-stats.json').write_text(json.dumps(stats,indent=2)+'\n')
print('DAWN_ASSETS_READY',json.dumps(stats))
