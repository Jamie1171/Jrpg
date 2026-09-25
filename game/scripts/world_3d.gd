extends Node3D
## Metres, genuine perspective geometry, collision and independent multi-touch controls.
signal interaction(id: String)
signal moved(pos: Vector2)
const IRON_ORE = preload("res://assets/models/ore/IronOre.glb")
const KIT = preload("res://assets/models/Brackenford_Kit.glb")
const ACTORS = {
	"Rowan":preload("res://assets/models/Rowan.glb"), "Cael":preload("res://assets/models/Cael.glb"),
	"Mira":preload("res://assets/models/Mira.glb"), "Tessa":preload("res://assets/models/Tessa.glb"),
	"Ysra":preload("res://assets/models/Ysra.glb"), "Orren":preload("res://assets/models/Orren.glb"),
	"Petra":preload("res://assets/models/Petra.glb")}
const LOCATIONS = {
	"inn":{"mira":Vector2(0,-3.2),"tessa":Vector2(-4,0),"parcel":Vector2(2,-3.2),"ysra":Vector2(4,0),"exit_inn":Vector2(0,7.6)},
	"brackenford":{"inn":Vector2(-13,-2.5),"orren":Vector2(21,8),"fish":Vector2(24,9),"north":Vector2(0,-26),"petra":Vector2(9,-2),"cael":Vector2(1,-17)},
	"woodland":{"south":Vector2(0,20),"cart":Vector2(6,-8),"waymark":Vector2(-6,-10)}}
var enabled := false:
	set(value):
		enabled = value
		if not value:
			reset_input()
			if not battle_mode:
				if is_instance_valid(player): animate(player,"idle")
				if is_instance_valid(follower): animate(follower,"idle")
var motion := true
var map_id := "brackenford"
var party := false
var guide := ""
var spots: Array[Dictionary] = []
var player: CharacterBody3D
var follower: CharacterBody3D
var scene: Node3D
var pivot: Node3D
var arm: SpringArm3D
var camera: Camera3D
var light: DirectionalLight3D
var environment: WorldEnvironment
var material: ShaderMaterial
var meshes: Dictionary = {}
var batches: Dictionary = {}
var portraits: Dictionary = {}
var yaw := 0.0
var pitch := -0.32
var look_idle := 0.0
var move_touch := -1
var look_touch := -1
var mouse_look := false
var stick := Vector2.ZERO
var stick_origin := Vector2(150,552)
var controls: Control
var battle_mode := false
var battle_enemies: Array[Node3D] = []
var saved_foot := Vector2.ZERO
var saved_yaw := 0.0
var trail: Array[Vector3] = []
var foot: Vector2:
	get:
		return Vector2(player.position.x,player.position.z) if is_instance_valid(player) else Vector2.ZERO
	set(value):
		if is_instance_valid(player):
			player.position = Vector3(value.x,0.1,value.y)
			player.velocity = Vector3.ZERO
			if is_instance_valid(pivot): pivot.position = player.position + Vector3(0,1.35,0)

func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/palette_toon.gdshader")
	var kit: Node = KIT.instantiate()
	for node in kit.find_children("*","MeshInstance3D",true,false): meshes[String(node.name)] = node.mesh
	kit.free()
	environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("589bd0")
	sky_mat.sky_horizon_color = Color("d2e7dd")
	sky_mat.ground_horizon_color = Color("d2e7dd")
	sky_mat.ground_bottom_color = Color("859475")
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c5d9ec")
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = env
	add_child(environment)
	light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-47,-32,0)
	light.light_color = Color("fff2df")
	light.light_energy = 0.75
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 45
	add_child(light)
	pivot = Node3D.new()
	add_child(pivot)
	arm = SpringArm3D.new()
	arm.spring_length = 6.5
	arm.margin = 0.22
	arm.collision_mask = 5
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 58
	camera.near = 0.08
	camera.far = 180
	arm.add_child(camera)
	camera.current = true
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	controls = Control.new()
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(controls)
	controls.draw.connect(draw_controls)

func setup(id: String, pos: Vector2, characters: Array, joined: bool, objective: String) -> void:
	reset_input()
	battle_mode = false
	battle_enemies.clear()
	if is_instance_valid(scene):
		remove_child(scene)
		scene.free()
	scene = Node3D.new()
	add_child(scene)
	map_id = id
	party = joined
	guide = objective
	spots.assign(characters.duplicate(true))
	batches.clear()
	trail.clear()
	match id:
		"inn": build_inn()
		"brackenford": build_village()
		"woodland": build_forest()
	flush_batches()
	for spot in spots:
		spot.pos = LOCATIONS[id][spot.id]
		var actor_name: String = {"mira":"Mira","tessa":"Tessa","ysra":"Ysra","orren":"Orren","petra":"Petra","cael":"Cael"}.get(spot.id,"")
		if actor_name != "":
			var actor := make_actor(actor_name,Vector3(spot.pos.x,0,spot.pos.y))
			actor.rotation.y = -0.5 if spot.id=="orren" else 0
		add_marker(spot,actor_name)
	player = make_actor("Rowan",Vector3.ZERO)
	player.collision_mask = 3
	if absf(pos.x)>100 or absf(pos.y)>100: pos = {"inn":Vector2(0,4),"brackenford":Vector2(-12,1),"woodland":Vector2(0,16)}[id]
	foot = pos
	player.rotation.y = PI
	follower = make_actor("Cael",player.position+Vector3(1.2,0,1.3)) if joined else null
	if is_instance_valid(follower): follower.collision_layer = 0
	yaw = 0
	pitch = -0.32
	arm.spring_length = 5.1 if id=="inn" else 6.5
	pivot.rotation = Vector3(pitch,yaw,0)
	environment.environment.ambient_light_energy = 0.45 if id=="inn" else 0.35
	moved.emit(foot)

func make_actor(who: String, pos: Vector3) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = who
	body.position = pos
	body.collision_layer = 2
	body.collision_mask = 1
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.72
	capsule.radius = 0.28
	collision.shape = capsule
	collision.position.y = 0.87
	body.add_child(collision)
	var model: Node3D = ACTORS[who].instantiate()
	model.name = "Model"
	body.add_child(model)
	for mesh_node in model.find_children("*","MeshInstance3D",true,false): mesh_node.material_override = material
	scene.add_child(body)
	animate(body,"idle")
	return body

func animate(body: Node, action: String) -> void:
	var players := body.find_children("*","AnimationPlayer",true,false)
	if players.is_empty(): return
	var animation: AnimationPlayer = players[0]
	for key in animation.get_animation_list():
		if action in key:
			var clip := animation.get_animation(key)
			clip.loop_mode = Animation.LOOP_NONE if action=="attack" else Animation.LOOP_LINEAR
			if animation.current_animation != key: animation.play(key,0.16)
			animation.speed_scale = 1.5 if action=="walk" else 1.0
			return

func solid(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cube_shape := BoxShape3D.new()
	cube_shape.size = size
	shape.shape = cube_shape
	body.position = pos
	body.add_child(shape)
	scene.add_child(body)

func prop(kind: String, pos: Vector3, size: Vector3 = Vector3.ONE, angle: float = 0) -> void:
	if not meshes.has(kind): push_error("Missing kit mesh: " + kind); return
	var transform := Transform3D(Basis(Vector3.UP,angle).scaled(size),pos)
	# Spatial chunks preserve frustum culling; one palette material for each batch.
	var key := "%d_%d" % [floori(pos.x/12),floori(pos.z/12)]
	if not batches.has(key): batches[key] = SurfaceTool.new(); batches[key].begin(Mesh.PRIMITIVE_TRIANGLES)
	batches[key].append_from(meshes[kind],0,transform)

func flush_batches() -> void:
	for key in batches:
		var node := MeshInstance3D.new()
		node.mesh = batches[key].commit()
		node.material_override = material
		scene.add_child(node)
	batches.clear()

func block(pos: Vector3, size: Vector3, color_value: Color, collision: bool = false) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var m := StandardMaterial3D.new()
	m.albedo_color = color_value
	m.roughness = 1
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = m
	node.position = pos
	scene.add_child(node)
	if collision: solid(pos,size)

func floor_patch(center: Vector2, size: Vector2, color_value: Color, y: float = -0.08, collision: bool = false) -> void:
	block(Vector3(center.x,y,center.y),Vector3(size.x,0.15,size.y),color_value,collision)

func house(pos: Vector2, width: float, depth: float, height: float = 3.6) -> void:
	prop("wall",Vector3(pos.x,0,pos.y),Vector3(width,height,depth))
	solid(Vector3(pos.x,height/2,pos.y),Vector3(width,height,depth))
	prop("roof",Vector3(pos.x,height,pos.y),Vector3(width/2+0.5,2.1,depth/2+0.5))
	for x in [-width/2+0.09,width/2-0.09]:
		for z in [-depth/2-0.03,depth/2+0.03]: prop("beam",Vector3(pos.x+x,0,pos.y+z),Vector3(.18,height,.18))
	for y in [0.15,2.65,height-.05]: prop("beam",Vector3(pos.x,y,pos.y+depth/2+.05),Vector3(width,.16,.18))
	prop("door",Vector3(pos.x,0,pos.y+depth/2+.09))
	for x in [-width*.31,width*.31]:
		prop("window",Vector3(pos.x+x,1.62,pos.y+depth/2+.08))
		prop("crate",Vector3(pos.x+x,.7,pos.y+depth/2+.35),Vector3(1.2,.3,.4))
		for offset in [-.35,0,.35]: prop("flower",Vector3(pos.x+x+offset,1,pos.y+depth/2+.35))
	prop("beam",Vector3(pos.x-width*.27,height,pos.y-depth*.2),Vector3(.65,1.8,.6))
	prop("lantern",Vector3(pos.x+.9,2.0,pos.y+depth/2+.3),Vector3.ONE*.65)
	prop("barrel",Vector3(pos.x+width/2+.7,0,pos.y+depth/2-.4))

func add_tree(pos: Vector2, scale_value: float = 1) -> void:
	prop("tree",Vector3(pos.x,0,pos.y),Vector3.ONE*scale_value,pos.x*.8)
	solid(Vector3(pos.x,1.2,pos.y),Vector3(.5,2.4,.5))
	var crown := StaticBody3D.new()
	crown.collision_layer = 4
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.35*scale_value
	shape.shape=sphere
	crown.add_child(shape)
	crown.position=Vector3(pos.x,3.5*scale_value,pos.y)
	scene.add_child(crown)

func build_village() -> void:
	add_iron_outcrop(Vector3(-8,0,3))
	terrain(Vector2(-7,0),Vector2(50,64),false)
	floor_patch(Vector2(22,0),Vector2(8,90),Color("478f99"),-.3)
	floor_patch(Vector2(38,0),Vector2(24,90),Color("699356"),-.08)
	# Invisible bank wall prevents walking onto water; the dock is a separate solid bridge.
	solid(Vector3(18.25,.7,-13),Vector3(.4,1.4,39))
	solid(Vector3(18.25,.7,23),Vector3(.4,1.4,22))
	floor_patch(Vector2(21,9),Vector2(8,4),Color("977253"),-.02,true)
	for x in range(18,26):
		prop("beam",Vector3(x,.055,9),Vector3(.065,.06,4))
	for z in [6.7,11.3]:
		for x in [18,20,22,24]: prop("fence",Vector3(x,0,z))
		solid(Vector3(21,.6,z),Vector3(8,1.2,.2))
	solid(Vector3(25.1,.6,9),Vector3(.2,1.2,4))
	house(Vector2(-13,-7),8,7,3.8)
	house(Vector2(-14,13),7,6)
	house(Vector2(11,17),6,6)
	house(Vector2(-14,-23),6,7)
	house(Vector2(11,-22),6,6)
	prop("well",Vector3(0,0,-3),Vector3.ONE*.85)
	solid(Vector3(0,1,-3),Vector3(1.8,2,1.8))
	prop("market_red",Vector3(10,0,-5))
	solid(Vector3(10,1,-5),Vector3(2.6,2,1.4))
	prop("market_gold",Vector3(14,0,-4))
	solid(Vector3(14,1,-4),Vector3(2.6,2,1.4))
	for p in [Vector2(-7,5),Vector2(5,10)]: prop("bench",Vector3(p.x,0,p.y))
	for p in [Vector2(7,-6),Vector2(14,-2),Vector2(-9,-2)]: prop("crate",Vector3(p.x,0,p.y))
	for x in range(-26,18,5):
		add_tree(Vector2(x,28),1.2)
		if abs(x)>4: add_tree(Vector2(x,-30),1.1)
	for z in range(-26,29,6): add_tree(Vector2(-28,z),1.4)
	for z in range(-32,37,7): add_tree(Vector2(30,z),1.5)
	for p in [Vector2(-6,-12),Vector2(6,-13),Vector2(-5,17),Vector2(14,9)]:
		add_tree(p,1.1)
		prop("bush",Vector3(p.x+1,0,p.y+1),Vector3.ONE*1.2)
	for z in range(-26,28,2):
		for x in [-5.2,5.3]:
			if abs(z-4)>4: prop("grass",Vector3(x+sin(z)*.6,0,z),Vector3.ONE*1.5)
	for i in range(30):
		var x := -24+fmod(i*7.13,39)
		var z := 11+fmod(i*3.27,15)
		if absf(x)>5: prop("grass",Vector3(x,0,z),Vector3.ONE*1.6)
	for z in range(-24,26,2):
		for x in [-2,0,2]: prop("paver",Vector3(x+sin(z)*.15,.10,z),Vector3(.8,.3,.7))
	for x in range(-10,17,2): prop("paver",Vector3(x,.11,4),Vector3(.8,.3,.7))
	# Distant rolling silhouettes are mesh geometry, not a painted sky backdrop.
	for i in range(9): prop("hill",Vector3(-60+i*16,-3,-62),Vector3(15,10+i%3*4,13))
	solid(Vector3(-31,1,0),Vector3(.3,2,64))
	for z in [-32,32]: solid(Vector3(-6.5,1,z),Vector3(49,2,.3))
	label_3d("THE HEARTH & HERON",Vector3(-13,2.7,-3.25),32,.010)
	label_3d("NORTH WOOD",Vector3(0,2.3,-26),30,.011)

func boundary(a: Vector2,b: Vector2) -> void:
	for x in [a.x,b.x]: solid(Vector3(x,1,(a.y+b.y)/2),Vector3(.3,2,b.y-a.y))
	for z in [a.y,b.y]: solid(Vector3((a.x+b.x)/2,1,z),Vector3(b.x-a.x,2,.3))

func build_inn() -> void:
	floor_patch(Vector2.ZERO,Vector2(14,18),Color("98714e"),-.08,true)
	for z in range(-8,9): prop("beam",Vector3(0,.008,z),Vector3(14,.015,.035))
	block(Vector3(0,2,-9),Vector3(14,4,.3),Color("d5bc8d"),true)
	for x in [-7,7]:
		block(Vector3(x,2,0),Vector3(.3,4,18),Color("d5bc8d"),true)
		for z in [-8,-3,3,8]: prop("beam",Vector3(x-.17*sign(x),0,z),Vector3(.26,4,.26))
	for x in [-5,5]: prop("window",Vector3(x,2.1,-8.8),Vector3.ONE*1.3)
	prop("beam",Vector3(0,0,-4.5),Vector3(6,1.05,1.2))
	solid(Vector3(0,.52,-4.5),Vector3(6,1.05,1.2))
	for x in [-4,4]:
		prop("table",Vector3(x,0,3))
		solid(Vector3(x,.4,3),Vector3(2,.8,1.5))
		for z in [1.8,4.2]: prop("bench",Vector3(x,0,z))
	for x in [-3,-1,1,3]: prop("barrel",Vector3(x,0,-7.5))
	prop("crate",Vector3(2,1.08,-4.5),Vector3.ONE*.42)
	prop("door",Vector3(0,0,8.7),Vector3.ONE,PI)
	boundary(Vector2(-7,-9),Vector2(7,9))
	for x in [-5,5]: prop("lantern",Vector3(x,2.7,-5),Vector3.ONE*.8)

func build_forest() -> void:
	add_iron_outcrop(Vector3(3,0,12))
	terrain(Vector2.ZERO,Vector2(38,48),true)
	prop("cart",Vector3(7,0,-10),Vector3.ONE,-.4)
	solid(Vector3(7,1,-10),Vector3(2.6,2,3.5))
	prop("beam",Vector3(-6,0,-10),Vector3(.2,2,.2))
	prop("crate",Vector3(-6,1.7,-10),Vector3(1.3,.45,.12))
	for z in range(-22,24,5):
		for x in [-17,-12,13,18]: add_tree(Vector2(x+sin(z),z),1.25+abs(sin(z))*.4)
	for x in range(-16,19,4): add_tree(Vector2(x,-22),1.4)
	for p in [Vector2(-7,-3),Vector2(9,3),Vector2(-8,13),Vector2(7,15)]:
		prop("rock",Vector3(p.x,0,p.y),Vector3(1.4,1.0,1.1))
		solid(Vector3(p.x,.5,p.y),Vector3(1.5,1,1.5))
		prop("bush",Vector3(p.x+1.2,0,p.y-1))
	for z in range(-19,22,2):
		for x in [-4.0,9.5]: prop("grass",Vector3(x+sin(z)*.9,0,z),Vector3.ONE*2)
	boundary(Vector2(-19,-24),Vector2(19,24))

func add_iron_outcrop(pos: Vector3) -> void:
	var ore: Node3D = IRON_ORE.instantiate()
	ore.name = "IronOutcrop"
	ore.position = pos
	scene.add_child(ore)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = .64
	cylinder.height = 1.18
	shape.shape = cylinder
	shape.position.y = .59
	body.add_child(shape)
	ore.add_child(body)

func label_3d(value: String,pos: Vector3,font_size_value: int = 36,pixel: float = .008) -> Label3D:
	var label := Label3D.new()
	label.text = value
	label.position = pos
	label.font_size = font_size_value
	label.pixel_size = pixel
	label.modulate = Color("fff0ca")
	label.outline_modulate = Color("253d36")
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visibility_range_end = 18
	label.visibility_range_end_margin = 3
	scene.add_child(label)
	return label

func add_marker(spot: Dictionary,actor_name: String) -> void:
	var pos := Vector3(spot.pos.x,2.25,spot.pos.y)
	if actor_name != "": label_3d(actor_name,pos)
	if spot.id == guide:
		var icon := label_3d("◆",pos+Vector3(0,.42,0),52,.010)
		icon.modulate = Color("ffce69")
	elif actor_name == "": label_3d(spot.label,pos,28,.009)

func nearest_spot() -> Dictionary:
	var nearest: Dictionary = {}
	var distance := 2.6
	for spot in spots:
		var d := foot.distance_to(spot.pos)
		if d < distance: nearest=spot; distance=d
	return nearest

func is_near(id: String) -> bool:
	for spot in spots:
		if spot.id==id: return foot.distance_to(spot.pos)<2.6
	return false

func request_interaction(id: String) -> void:
	if enabled and is_near(id): interaction.emit(id)

func reset_input() -> void:
	stick = Vector2.ZERO
	move_touch = -1
	look_touch = -1
	mouse_look = false

func _unhandled_input(event: InputEvent) -> void:
	if not enabled: return
	if event is InputEventScreenTouch and event.pressed:
		if event.position.x<370 and event.position.y>330 and move_touch==-1:
			move_touch=event.index
			stick_origin=Vector2(clampf(event.position.x,85,280),clampf(event.position.y,420,610))
		elif event.position.x>440 and event.position.y>100 and event.position.y<620 and look_touch==-1:
			look_touch=event.index
	elif event is InputEventMouseButton and event.device != -1 and event.button_index==MOUSE_BUTTON_RIGHT:
		mouse_look=event.pressed
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_E:
		var spot := nearest_spot()
		if not spot.is_empty(): request_interaction(spot.id)

func _input(event: InputEvent) -> void:
	if not enabled: return
	if event is InputEventScreenDrag:
		if event.index==move_touch: stick=((event.position-stick_origin)/72).limit_length()
		elif event.index==look_touch: orbit(event.relative)
	elif event is InputEventScreenTouch and not event.pressed:
		if event.index==move_touch: move_touch=-1; stick=Vector2.ZERO
		if event.index==look_touch: look_touch=-1
	elif event is InputEventMouseMotion and mouse_look: orbit(event.relative)
	elif event is InputEventMouseButton and not event.pressed and event.button_index==MOUSE_BUTTON_RIGHT: mouse_look=false

func orbit(relative: Vector2) -> void:
	yaw -= relative.x*.005
	pitch = clampf(pitch-relative.y*.004,-.85,-.10)
	look_idle=0

func draw_controls() -> void:
	if not enabled: return
	if Pad.active:
		controls.draw_style_box(controller_panel(),Rect2(22,493,274,174))
		var lines := ["LS  Move     RS  Camera","A  Interact     B  Back","X  Satchel     Y  Journal","Menu  Pause"]
		for i in range(lines.size()): controls.draw_string(ThemeDB.fallback_font,Vector2(39,522+i*37),lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("f5e9d2"))
		return
	var center := stick_origin if move_touch>=0 else Vector2(150,552)
	controls.draw_circle(center,75,Color(.06,.15,.17,.42))
	controls.draw_arc(center,75,0,TAU,48,Color(.95,.87,.65,.65),2,true)
	controls.draw_circle(center+stick*53,30,Color(.94,.86,.67,.55))
	controls.draw_string(ThemeDB.fallback_font,Vector2(110,655),"MOVE",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("213a38"))
	controls.draw_string(ThemeDB.fallback_font,Vector2(985,573),"SWIPE TO LOOK",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(.12,.23,.22,.8))

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return
	controls.queue_redraw()
	if not enabled or battle_mode or not Pad.focused: return
	var input := (stick + Pad.movement()).limit_length()
	var camera_input: Vector2 = Pad.look()
	if camera_input != Vector2.ZERO:
		yaw -= camera_input.x*2.3*delta
		pitch = clampf(pitch-camera_input.y*1.6*delta,-.85,-.10)
		look_idle=0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input.y-=1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input.y+=1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input.x-=1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input.x+=1
	input=input.limit_length()
	var forward := -camera.global_basis.z
	forward.y=0
	forward=forward.normalized()
	var right := camera.global_basis.x
	right.y=0
	var direction := right.normalized()*input.x-forward*input.y
	player.velocity.x=direction.x*4.2
	player.velocity.z=direction.z*4.2
	player.velocity.y-=18*delta
	player.move_and_slide()
	if direction.length_squared()>.02:
		player.rotation.y=lerp_angle(player.rotation.y,atan2(direction.x,direction.z),minf(1,delta*12))
		moved.emit(foot)
		if trail.is_empty() or trail[-1].distance_to(player.position)>.25: trail.append(player.position)
		while trail.size()>14: trail.pop_front()
	animate(player,"walk" if motion and direction.length_squared()>.02 else "idle")
	if is_instance_valid(follower):
		var destination: Vector3 = trail[maxi(0,trail.size()-8)] if not trail.is_empty() else player.position+Vector3(1,0,1)
		var difference := destination-follower.position
		difference.y=0
		var moving := difference.length()>.6 and follower.position.distance_to(player.position)>1.5
		var follow_direction := difference.normalized() if moving else Vector3.ZERO
		follower.velocity=Vector3(follow_direction.x*4.6,follower.velocity.y-18*delta,follow_direction.z*4.6)
		follower.move_and_slide()
		if moving: follower.rotation.y=lerp_angle(follower.rotation.y,atan2(follow_direction.x,follow_direction.z),delta*10)
		animate(follower,"walk" if moving and motion else "idle")
	look_idle+=delta
	if look_idle>2 and input.y<-.4 and absf(input.x)<.25:
		yaw=lerp_angle(yaw,player.rotation.y+PI,delta*.6)
	pivot.position=pivot.position.lerp(player.position+Vector3(0,1.35,0),minf(1,delta*12))
	pivot.rotation=Vector3(pitch,yaw,0)
	if player.position.y < -5: foot={"inn":Vector2(0,4),"brackenford":Vector2(-12,1),"woodland":Vector2(0,16)}[map_id]

func get_portrait(who: String) -> Texture2D:
	if not ACTORS.has(who): who="Rowan"
	if portraits.has(who): return portraits[who]
	var viewport := SubViewport.new()
	viewport.size=Vector2i(256,256)
	viewport.own_world_3d=true
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	add_child(viewport)
	var model: Node3D=ACTORS[who].instantiate()
	viewport.add_child(model)
	for mesh_node in model.find_children("*","MeshInstance3D",true,false): mesh_node.material_override=material
	var portrait_environment := WorldEnvironment.new()
	portrait_environment.environment=environment.environment.duplicate()
	viewport.add_child(portrait_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-25,-35,0)
	sun.light_energy=0.7
	viewport.add_child(sun)
	var lens := Camera3D.new()
	lens.projection=Camera3D.PROJECTION_ORTHOGONAL
	lens.size=.62
	lens.position=Vector3(.07,1.60,1.6)
	viewport.add_child(lens)
	lens.look_at(Vector3(0,1.52,0))
	portraits[who]=viewport.get_texture()
	return portraits[who]

func enter_battle() -> void:
	if not battle_mode:
		saved_foot=foot
		saved_yaw=yaw
	else:
		for enemy in battle_enemies: enemy.queue_free()
	battle_enemies.clear()
	battle_mode=true
	enabled=false
	animate(player,"idle")
	if is_instance_valid(follower): animate(follower,"idle")
	player.position=Vector3(-1.8,.05,0)
	player.rotation.y=PI*.65
	if is_instance_valid(follower): follower.position=Vector3(.2,.05,1.7); follower.rotation.y=PI*.65
	for i in range(2):
		var enemy := MeshInstance3D.new()
		enemy.mesh=meshes["mossback"]
		enemy.material_override=material
		enemy.position=Vector3(3.2+i*2.4,.05,-2.8+i*1.7)
		enemy.scale=Vector3.ONE*(1.3 if i==0 else .85)
		enemy.rotation.y=-.8
		scene.add_child(enemy)
		battle_enemies.append(enemy)
	pivot.position=Vector3(1.2,1.0,-.3)
	pivot.rotation=Vector3(-.32,.45,0)
	arm.spring_length=10

func battle_feedback(actor: int, enemies: Array) -> void:
	animate(player if actor==0 else follower,"attack")
	for i in range(2): battle_enemies[i].visible=enemies[i].hp>0
	get_tree().create_timer(1.1).timeout.connect(func():
		if is_instance_valid(player): animate(player,"idle")
		if is_instance_valid(follower): animate(follower,"idle"))

func exit_battle() -> void:
	if not battle_mode: return
	battle_mode=false
	for enemy in battle_enemies: enemy.queue_free()
	battle_enemies.clear()
	foot=saved_foot
	yaw=saved_yaw
	arm.spring_length=6.5
	if is_instance_valid(follower): follower.position=player.position+Vector3(1,0,1)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: reset_input()

func terrain(center: Vector2,size: Vector2,forest: bool) -> void:
	var node := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size=size
	node.mesh=mesh
	node.position=Vector3(center.x,0,center.y)
	var ground_material := ShaderMaterial.new()
	ground_material.shader=preload("res://shaders/ground.gdshader")
	ground_material.set_shader_parameter("forest",forest)
	node.material_override=ground_material
	scene.add_child(node)
	solid(Vector3(center.x,-.1,center.y),Vector3(size.x,.2,size.y))

func controller_panel() -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color=Color(.06,.14,.16,.88)
	panel.set_corner_radius_all(12)
	return panel
