extends Node2D
signal interaction(id: String)
signal moved(pos: Vector2)
const BACKGROUNDS = {
	"inn":preload("res://assets/art/inn.webp"),
	"brackenford":preload("res://assets/art/brackenford.webp"),
	"woodland":preload("res://assets/art/woodland.webp")}
const WALK = preload("res://assets/art/party_walk.webp")
const PEOPLE = preload("res://assets/art/characters.webp")
var map_id := "inn"
var foot := Vector2(650,480)
var companion := Vector2(700,500)
var direction := 0
var companion_direction := 0
var clock := 0.0
var walking := false
var enabled := false
var party := false
var motion := true
var path: Array[Vector2] = []
var pending := ""
var spots: Array[Dictionary] = []
var polygon := PackedVector2Array()
var marker := Vector2(-100,-100)
var guide := ""

func setup(id: String, pos: Vector2, characters: Array, joined: bool, objective: String) -> void:
	map_id = id
	spots.assign(characters)
	party = joined
	guide = objective
	match id:
		"inn": polygon = PackedVector2Array([Vector2(360,340),Vector2(785,330),Vector2(1010,380),Vector2(1070,485),Vector2(1140,560),Vector2(1100,650),Vector2(480,650),Vector2(350,545)])
		"brackenford": polygon = PackedVector2Array([Vector2(155,445),Vector2(268,326),Vector2(435,310),Vector2(570,203),Vector2(650,190),Vector2(690,230),Vector2(641,312),Vector2(862,355),Vector2(975,405),Vector2(1043,472),Vector2(1185,488),Vector2(1180,535),Vector2(1040,528),Vector2(949,482),Vector2(856,648),Vector2(273,668),Vector2(130,548)])
		"woodland": polygon = PackedVector2Array([Vector2(446,283),Vector2(566,180),Vector2(677,228),Vector2(844,231),Vector2(1004,293),Vector2(1060,385),Vector2(929,481),Vector2(827,516),Vector2(747,694),Vector2(612,704),Vector2(566,559),Vector2(408,478),Vector2(407,367)])
	foot = closest_walkable(pos)
	companion = closest_walkable(foot + Vector2(55,20))
	path.clear()
	pending = ""
	marker = Vector2(-100,-100)
	queue_redraw()

func closest_walkable(pos: Vector2) -> Vector2:
	if Geometry2D.is_point_in_polygon(pos, polygon):
		return pos
	var nearest := polygon[0]
	var distance := INF
	for i in range(polygon.size()):
		var point := Geometry2D.get_closest_point_to_segment(pos, polygon[i], polygon[(i+1)%polygon.size()])
		if point.distance_squared_to(pos) < distance:
			distance = point.distance_squared_to(pos)
			nearest = point
	# Nudge the point toward the inside to avoid edge ambiguities.
	return nearest.lerp(Vector2(650,460), 0.005)

func visible_segment(a: Vector2, b: Vector2) -> bool:
	var steps := maxi(2, int(a.distance_to(b) / 4.0))
	for i in range(1, steps):
		if not Geometry2D.is_point_in_polygon(a.lerp(b, float(i)/steps), polygon):
			return false
	return true

func route(a: Vector2, b: Vector2) -> Array[Vector2]:
	var end := closest_walkable(b)
	if visible_segment(a, end):
		return [end]
	var graph := AStar2D.new()
	var points: Array[Vector2] = [a, end]
	for vertex in polygon:
		points.append(closest_walkable(vertex))
	for i in range(points.size()):
		graph.add_point(i, points[i])
	for i in range(points.size()):
		for j in range(i+1, points.size()):
			if visible_segment(points[i], points[j]):
				graph.connect_points(i,j)
	var result: Array[Vector2] = []
	for point in graph.get_point_path(0,1):
		result.append(point)
	if not result.is_empty():
		result.remove_at(0)
	return result

func go_to(pos: Vector2, id: String = "") -> void:
	path = route(foot, pos)
	pending = id
	marker = closest_walkable(pos)
	if path.is_empty() and foot.distance_to(marker) < 15:
		finish_move()

func request_interaction(id: String) -> void:
	for spot in spots:
		if spot.id == id:
			go_to(spot.pos + Vector2(0,32), id)
			return

func nearest_spot() -> Dictionary:
	var nearest: Dictionary = {}
	var distance := 135.0
	for spot in spots:
		var d: float = foot.distance_to(spot.pos)
		if d < distance:
			distance = d
			nearest = spot
	return nearest

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		var candidate: Dictionary = {}
		var distance := 90.0
		for spot in spots:
			var d: float = pos.distance_to(spot.pos - Vector2(0,50))
			if d < distance:
				distance = d
				candidate = spot
		if candidate.is_empty():
			go_to(pos)
		else:
			request_interaction(candidate.id)
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and event.keycode in [KEY_E, KEY_SPACE]:
		var spot := nearest_spot()
		if not spot.is_empty():
			request_interaction(spot.id)

func facing(delta: Vector2) -> int:
	if absf(delta.x) > absf(delta.y):
		return 2 if delta.x > 0 else 1
	return 0 if delta.y > 0 else 3

func _process(delta: float) -> void:
	clock += delta
	walking = false
	if enabled:
		var key := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		if key.length() > 0:
			path.clear()
			pending = ""
			var dest := foot + key.normalized() * delta * 230
			if Geometry2D.is_point_in_polygon(dest, polygon):
				foot = dest
				walking = true
				direction = facing(key)
		elif not path.is_empty():
			var diff := path[0] - foot
			direction = facing(diff)
			foot = foot.move_toward(path[0], delta * 230)
			walking = true
			if foot.distance_to(path[0]) < 2:
				path.remove_at(0)
				if path.is_empty():
					finish_move()
		if party and companion.distance_to(foot) > 70:
			companion_direction = facing(foot - companion)
			companion = closest_walkable(companion.move_toward(foot, delta * 210))
		if walking:
			moved.emit(foot)
	queue_redraw()

func finish_move() -> void:
	marker = Vector2(-100,-100)
	if pending != "":
		var id := pending
		pending = ""
		interaction.emit(id)

func sprite(tex: Texture2D, region: Rect2, pos: Vector2, height: float, tint: Color = Color.WHITE) -> void:
	draw_set_transform(pos, 0, Vector2(1,0.30))
	draw_circle(Vector2(0,-8), height * 0.20, Color(0.05,0.08,0.06,0.28))
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect_region(tex, Rect2(pos - Vector2(height/2,height-5),Vector2(height,height)),region,tint)

func _draw() -> void:
	draw_texture_rect(BACKGROUNDS[map_id],Rect2(0,0,1280,720),false)
	if enabled and not path.is_empty():
		draw_arc(marker,12,0,TAU,24,Color(0.96,0.82,0.48,0.8),2,true)
	var entities: Array[Dictionary] = []
	for spot in spots:
		if spot.get("sprite",-1) >= 0:
			entities.append({"pos":spot.pos,"kind":"npc","index":spot.sprite})
	entities.append({"pos":foot,"kind":"rowan"})
	if party:
		entities.append({"pos":companion,"kind":"cael"})
	entities.sort_custom(func(a,b): return a.pos.y < b.pos.y)
	for entity in entities:
		if entity.kind == "npc":
			var index: int = entity.index
			if index == 6:
				sprite(WALK, Rect2(4*256,0,256,256),entity.pos,132)
			else:
				sprite(PEOPLE,Rect2((index%3)*512,(index/3)*512,512,512),entity.pos,140)
		else:
			var frame: int = [0,1,2,1][int(clock*7)%4] if walking and motion else 1
			var row := direction if entity.kind == "rowan" else companion_direction
			var col: int = frame + (3 if entity.kind == "cael" else 0)
			sprite(WALK,Rect2(col*256,row*256,256,256),entity.pos,132)
	for spot in spots:
		var pos: Vector2 = spot.pos - Vector2(0,133 if spot.get("sprite",-1)>=0 else 45)
		var active: bool = spot.id == guide
		var color := Color("f4d58b") if active else Color("f5ebd3")
		draw_circle(pos,15,Color("20363a"))
		draw_arc(pos,15,0,TAU,24,color,1.5,true)
		if active:
			draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-8),pos+Vector2(5,0),pos+Vector2(0,8),pos+Vector2(-5,0)]),color)
		else:
			draw_circle(pos,3,color)
