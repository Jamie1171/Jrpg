extends Control
const World = preload("res://scripts/world_view.gd")
const Battle = preload("res://scripts/battle_model.gd")
const Fishing = preload("res://scripts/fishing_model.gd")
const PORTRAITS = preload("res://assets/art/portraits.webp")
const PEOPLE = preload("res://assets/art/characters.webp")
const SERIF = preload("res://assets/fonts/DejaVuSerif.ttf")
const INK = Color("172d33")
const PAPER = Color("f5e9d2")
const GOLD = Color("e3be75")
const MUTED = Color("bdd0c9")
var world: Node2D
var hud: Control
var overlay: Control
var status: Label
var hint: Button
var quest_label: Label
var music: AudioStreamPlayer
var dialogue_data: Dictionary
var dialogue_lines: Array = []
var dialogue_index := 0
var dialogue_done: Callable
var mode := "title"
var battle: RefCounted
var fishing: RefCounted
var selected_enemy := 0
var auto_save := 0.0
var toast_time := 0.0
var toast_label: Label
var qa := false
var modal_back: Callable

func _ready() -> void:
	get_tree().auto_accept_quit = false
	qa = "--qa" in OS.get_cmdline_user_args()
	if qa:
		GameState.saving_enabled = false
	dialogue_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var skin := Theme.new()
	skin.default_font_size = 23
	skin.set_color("font_color", "Label", PAPER)
	skin.set_color("font_color", "Button", PAPER)
	skin.set_color("font_hover_color", "Button", Color.WHITE)
	skin.set_color("font_pressed_color", "Button", GOLD)
	skin.set_color("font_disabled_color", "Button", Color("788b89"))
	skin.set_stylebox("normal", "Button", style(Color("213f45"),Color("56716a"),10))
	skin.set_stylebox("hover", "Button", style(Color("31565a"),GOLD,10))
	skin.set_stylebox("pressed", "Button", style(Color("10282d"),GOLD,10))
	skin.set_stylebox("disabled", "Button", style(Color("243435"),Color("41524e"),10))
	skin.set_stylebox("focus", "Button", style(Color(0,0,0,0),GOLD,10,2))
	theme = skin
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	world = World.new()
	add_child(world)
	world.interaction.connect(interact)
	world.moved.connect(func(pos): GameState.data.position = [pos.x,pos.y])
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	music = AudioStreamPlayer.new()
	if not qa:
		music.stream = load("res://assets/audio/brackenford.ogg")
	music.volume_db = -15
	add_child(music)
	music.finished.connect(func(): music.play())
	show_title()
	if qa:
		run_qa.call_deferred()

func style(fill: Color, border: Color, radius: int = 12, width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func box(parent: Node, rect: Rect2, fill: Color = INK, border: Color = Color("6b7970")) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", style(fill,border))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func text_at(parent: Node, value: String, rect: Rect2, font_size: int = 24, color: Color = PAPER, serif: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	if serif:
		label.add_theme_font_override("font",SERIF)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func button(parent: Node, value: String, rect: Rect2, action: Callable) -> Button:
	var result := Button.new()
	result.text = value
	result.position = rect.position
	result.size = rect.size
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.pressed.connect(action)
	parent.add_child(result)
	return result

func picture(parent: Node, texture: Texture2D, rect: Rect2, region: Rect2 = Rect2()) -> TextureRect:
	var node := TextureRect.new()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if region.size != Vector2.ZERO:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = region
		node.texture = atlas
	else:
		node.texture = texture
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func portrait(parent: Node, name_value: String, rect: Rect2) -> void:
	var index: int = {"Rowan":0,"Cael":1,"Mira":2,"Tessa":3,"Ysra":4,"Orren":5}.get(name_value,0)
	picture(parent,PORTRAITS,rect,Rect2((index%3)*512,(index/3)*512,512,512))

func clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func shade(alpha: float = 0.55) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.015,0.04,0.045,alpha)
	dim.size = Vector2(1280,720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

func prepare_overlay(new_mode: String, darken: bool = true) -> void:
	mode = new_mode
	world.enabled = false
	overlay.show()
	clear(overlay)
	if darken:
		shade()

func update_music() -> void:
	world.motion = GameState.data.settings.motion
	# Render tests have a dummy audio device; no decoder thread is needed there.
	if qa: return
	if GameState.data.settings.music and not music.playing:
		music.play()
	elif not GameState.data.settings.music:
		music.stop()
	world.motion = GameState.data.settings.motion

func show_title() -> void:
	clear(hud)
	world.setup("brackenford",Vector2(600,480),[],false,"")
	prepare_overlay("title",false)
	var shadow := ColorRect.new()
	shadow.color = Color(0.025,0.075,0.09,0.73)
	shadow.size = Vector2(635,720)
	overlay.add_child(shadow)
	text_at(overlay,"A STORY OF HOME, AND WHAT WE OWE IT",Rect2(56,72,530,38),17,GOLD)
	text_at(overlay,"The\nUnfinished\nDawn",Rect2(50,125,570,270),66,PAPER,true)
	text_at(overlay,"CHAPTER ZERO  /  BRACKENFORD",Rect2(58,405,520,35),19,MUTED)
	var has_save: bool = GameState.has_save()
	button(overlay,"Continue your journey" if has_save else "Begin your journey",Rect2(58,477,475,68),func():
		if has_save:
			if GameState.load_game():
				enter_game()
			else:
				show_notice("A troubled memory",GameState.load_message,show_title)
		else:
			start_new())
	button(overlay,"New journey" if has_save else "How to play",Rect2(58,563,230,58),func():
		if has_save: confirm_new()
		else: show_help(show_title))
	button(overlay,"Settings",Rect2(303,563,230,58),func(): show_settings(show_title))
	text_at(overlay,"OPENING PROTOTYPE  •  0.1.0  •  OFFLINE",Rect2(58,660,530,30),16,MUTED)
	update_music()

func confirm_new() -> void:
	modal_back = show_title
	prepare_overlay("menu")
	box(overlay,Rect2(275,205,730,310))
	text_at(overlay,"Begin again?",Rect2(310,235,650,55),36,GOLD,true)
	text_at(overlay,"This replaces this device’s current journey. Your settings will be kept.",Rect2(310,310,650,90),26)
	button(overlay,"Keep my journey",Rect2(310,425,310,62),show_title)
	button(overlay,"Start anew",Rect2(640,425,325,62),start_new)

func start_new() -> void:
	GameState.new_game()
	enter_game()

func enter_game() -> void:
	var pos: Array = GameState.data.position
	change_map(GameState.data.map,Vector2(pos[0],pos[1]))
	update_music()
	if GameState.data.stage == 0:
		dialogue("intro",func():
			GameState.event("intro",1)
			refresh_world()
			toast("Tap the ground to walk. Gold diamonds mark your next objective."))
	elif GameState.load_message != "":
		toast(GameState.load_message)

func active_guide() -> String:
	var stage: int = int(GameState.data.stage)
	var map_id: String = GameState.data.map
	if map_id == "inn" and stage in [2,3,4,5]: return "exit_inn"
	if map_id == "brackenford" and stage in [4,5]: return "north"
	if map_id == "brackenford" and stage in [6,7]: return "inn"
	if map_id == "woodland" and stage in [6,7]: return "south"
	return ["mira","parcel","orren","cael","north","cart","mira","ysra",""][int(GameState.data.stage)]

func map_spots(id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	match id:
		"inn":
			result = [{"id":"mira","label":"Talk to Mira","pos":Vector2(555,354),"sprite":0},
				{"id":"tessa","label":"Talk to Tessa","pos":Vector2(391,376),"sprite":1},
				{"id":"exit_inn","label":"Step outside","pos":Vector2(1090,586)}]
			if GameState.data.stage == 1:
				result.append({"id":"parcel","label":"Take the parcel","pos":Vector2(670,350)})
			if GameState.data.stage >= 7:
				result.append({"id":"ysra","label":"Talk to Ysra","pos":Vector2(790,395),"sprite":2})
		"brackenford":
			result = [{"id":"inn","label":"Enter the inn","pos":Vector2(275,337)},
				{"id":"orren","label":"Talk to Orren","pos":Vector2(1057,499),"sprite":3},
				{"id":"fish","label":"Cast a line","pos":Vector2(1162,506)},
				{"id":"north","label":"Woodland path","pos":Vector2(627,228)},
				{"id":"petra","label":"Talk to Petra","pos":Vector2(851,389),"sprite":5}]
			if not GameState.data.party:
				result.append({"id":"cael","label":"Talk to Cael","pos":Vector2(624,314),"sprite":6})
		"woodland":
			result = [{"id":"south","label":"Return to Brackenford","pos":Vector2(683,650)},
				{"id":"cart","label":"Inspect the cart","pos":Vector2(974,320)},
				{"id":"waymark","label":"Read the waymark","pos":Vector2(850,257)}]
	return result

func change_map(id: String, pos: Vector2) -> void:
	GameState.data.map = id
	world.setup(id,pos,map_spots(id),GameState.data.party,active_guide())
	GameState.data.position = [world.foot.x,world.foot.y]
	GameState.save_game()
	close_overlay()

func refresh_world() -> void:
	world.setup(GameState.data.map,world.foot,map_spots(GameState.data.map),GameState.data.party,active_guide())
	close_overlay()

func close_overlay() -> void:
	clear(overlay)
	overlay.hide()
	mode = "explore"
	world.enabled = true
	build_hud()

func build_hud() -> void:
	clear(hud)
	box(hud,Rect2(22,18,480,66),Color(0.06,0.14,0.16,0.94))
	text_at(hud,{"inn":"Hearth & Heron","brackenford":"Brackenford","woodland":"The North Wood"}[GameState.data.map],Rect2(43,30,430,43),31,PAPER,true)
	box(hud,Rect2(22,95,415,100),Color(0.06,0.14,0.16,0.89))
	text_at(hud,"THE LANTERNS OF HOME",Rect2(39,104,370,24),14,GOLD)
	quest_label = text_at(hud,GameState.objective(),Rect2(39,133,370,58),21)
	button(hud,"Journal",Rect2(824,21,138,60),show_journal)
	button(hud,"Satchel",Rect2(978,21,134,60),show_bag)
	button(hud,"Menu",Rect2(1128,21,130,60),show_menu)
	box(hud,Rect2(22,629,357,69),Color(0.06,0.14,0.16,0.91))
	portrait(hud,"Rowan",Rect2(29,635,55,55))
	text_at(hud,"Rowan" + ("  ·  Cael" if GameState.data.party else ""),Rect2(96,635,265,28),22)
	text_at(hud,"Courier  ·  %d crowns" % GameState.data.gold,Rect2(96,666,265,22),16,GOLD)
	hint = button(hud,"",Rect2(924,627,334,71),func():
		var nearest: Dictionary = world.nearest_spot()
		if not nearest.is_empty(): world.request_interaction(nearest.id))
	hint.hide()
	toast_label = text_at(hud,"",Rect2(397,636,500,63),20,PAPER)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_shadow_color",Color.BLACK)
	toast_label.add_theme_constant_override("shadow_offset_x",2)
	toast_label.add_theme_constant_override("shadow_offset_y",2)

func toast(message: String) -> void:
	if is_instance_valid(toast_label):
		toast_label.text = message
		toast_time = 6

func _process(delta: float) -> void:
	if mode == "explore":
		if is_instance_valid(hint):
			var nearest: Dictionary = world.nearest_spot()
			hint.visible = not nearest.is_empty()
			if not nearest.is_empty(): hint.text = nearest.label
		auto_save += delta
		if auto_save > 12:
			auto_save = 0
			if not GameState.save_game(): toast(GameState.load_message)
	if toast_time > 0:
		toast_time -= delta
		if toast_time <= 0 and is_instance_valid(toast_label): toast_label.text = ""

func interact(id: String) -> void:
	match id:
		"mira":
			if GameState.data.stage == 6:
				dialogue("home",func(): GameState.event("home",7); refresh_world())
			else:
				dialogue("after" if GameState.data.stage >= 7 else "mira_wait",close_overlay)
		"parcel": dialogue("parcel",func(): GameState.event("parcel",2); refresh_world(); toast("Mira’s parcel added to your satchel."))
		"tessa": dialogue("mother",close_overlay)
		"exit_inn": change_map("brackenford",Vector2(315,385))
		"inn": change_map("inn",Vector2(1033,564))
		"orren":
			if GameState.data.stage == 2:
				dialogue("delivery",func(): GameState.event("delivery",3); refresh_world(); toast("+12 crowns • Fishing unlocked at the landing."))
			else:
				dialogue("orren" if GameState.data.stage >= 3 else "orren_early",close_overlay)
		"cael":
			if GameState.data.stage == 3:
				dialogue("cael",func(): GameState.event("cael",4); refresh_world(); toast("Cael joined the party • Vanguard"))
			else: dialogue("cael_early",close_overlay)
		"north":
			if GameState.data.stage < 4:
				toast("Cael is waiting by the north path. Finish Mira’s delivery first.")
			else:
				change_map("woodland",Vector2(680,598))
				if GameState.data.stage == 4:
					dialogue("woodland",func(): GameState.event("woodland",5); refresh_world())
		"south": change_map("brackenford",Vector2(620,282))
		"cart":
			if GameState.data.stage == 5: dialogue("cart",start_battle)
			else: toast("The oil is safely packed. The merchant can collect his cart tomorrow.")
		"waymark": dialogue("waymark",close_overlay)
		"ysra":
			if GameState.data.stage == 7:
				dialogue("ysra",func(): GameState.event("ysra",8); show_ending())
			else: dialogue("ysra",close_overlay)
		"petra": dialogue("petra",show_bag)
		"fish":
			if GameState.data.stage >= 3: fishing_setup()
			else: toast("Bring Orren his parcel first; he has a spare rod you can borrow.")

func dialogue(key: String, done: Callable) -> void:
	dialogue_lines = dialogue_data[key]
	dialogue_index = 0
	dialogue_done = done
	show_line()

func show_line() -> void:
	prepare_overlay("dialogue",false)
	var line: Array = dialogue_lines[dialogue_index]
	box(overlay,Rect2(24,449,1232,247),Color(0.055,0.12,0.14,0.98),GOLD)
	portrait(overlay,line[0],Rect2(42,470,193,193))
	text_at(overlay,line[0].to_upper(),Rect2(261,471,760,36),22,GOLD)
	text_at(overlay,line[1],Rect2(260,518,958,109),28 if GameState.data.settings.large_text else 26)
	text_at(overlay,"%d / %d" % [dialogue_index+1,dialogue_lines.size()],Rect2(261,650,100,27),17,MUTED)
	button(overlay,"Skip scene",Rect2(839,635,174,48),skip_dialogue)
	button(overlay,"Continue  ›",Rect2(1027,635,205,48),next_line)

func next_line() -> void:
	var line: Array = dialogue_lines[dialogue_index]
	GameState.remember(line[0],line[1])
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		GameState.save_game()
		dialogue_done.call()
	else: show_line()

func skip_dialogue() -> void:
	for i in range(dialogue_index,dialogue_lines.size()):
		GameState.remember(dialogue_lines[i][0],dialogue_lines[i][1])
	GameState.save_game()
	dialogue_done.call()

func sheet(title: String, subtitle: String) -> void:
	modal_back = close_overlay
	prepare_overlay("menu")
	box(overlay,Rect2(110,45,1060,630),INK,GOLD)
	text_at(overlay,title,Rect2(146,68,850,56),38,GOLD,true)
	text_at(overlay,subtitle,Rect2(148,130,925,42),21,MUTED)
	button(overlay,"Back",Rect2(1002,594,132,57),close_overlay)

func show_journal() -> void:
	sheet("The journey so far","The lanterns of home  /  Opening chapter")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(149,193)
	scroll.size = Vector2(972,374)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation",21)
	scroll.add_child(stack)
	var entries: Array[String] = ["NEXT  •  " + GameState.objective(),
		"Rowan Hale / Courier\nHome from the valley roads. Mira needs a parcel delivered and lantern oil brought back for the festival.",
		"RIVERCRAFT  •  %d / 3 catches\n%s" % [mini(3,int(GameState.data.catches)), "Riverglass charm earned. Rowan gains 4 maximum health in combat." if GameState.data.charm else "Land three fish to earn Orren’s riverglass charm. This is entirely optional."],
		"PARTY\n" + ("Cael / Vanguard — Rowan’s oldest friend. Opening Cut exposes a foe; Shield Bash can stop a charge." if GameState.data.party else "Rowan / Courier — Quick enough to create an opening for an ally.")]
	if GameState.data.stage >= 8:
		entries.append("END OF THE OPENING\nYsra has arrived. Supper waits at the Hearth & Heron. The larger story, further party members, mining and crafting are planned for future chapters.")
	entries.append("RECENT CONVERSATIONS")
	for line in GameState.data.history.slice(maxi(0,GameState.data.history.size()-24)):
		entries.append(line)
	for entry in entries:
		var label := Label.new()
		label.text = entry
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size",23)
		stack.add_child(label)

func show_bag() -> void:
	sheet("Rowan’s satchel","Supplies, keepsakes, and a shared purse")
	text_at(overlay,"%d crowns" % GameState.data.gold,Rect2(149,188,430,49),33,GOLD,true)
	var quest_item := "No delivery items."
	if GameState.data.stage == 2: quest_item = "Mira’s parcel • for Orren at the landing"
	if GameState.data.stage == 6: quest_item = "Lantern oil • bring it home to Mira"
	text_at(overlay,"DELIVERY\n" + quest_item,Rect2(150,253,940,80),23)
	text_at(overlay,"SUPPLIES\n%d healing herbs • restores 32 health in battle\n%d fresh fish • worth 6 crowns each at Petra’s stall" % [GameState.data.herbs,GameState.data.fish],Rect2(150,350,940,119),23)
	text_at(overlay,"KEEPSAKE\n" + ("Riverglass charm • equipped • +4 maximum health" if GameState.data.charm else "Orren’s charm • earn it by landing three fish"),Rect2(150,480,920,85),23,MUTED)
	var can_trade: bool = GameState.data.map == "brackenford" and world.foot.distance_to(Vector2(851,389)) < 150
	var sell := button(overlay,"Sell fish (%d crowns)" % (GameState.data.fish*6),Rect2(148,594,352,57),func():
		GameState.sell_fish()
		show_bag())
	sell.disabled = not can_trade or GameState.data.fish == 0
	text_at(overlay,"Visit Petra in the square to sell your catch.",Rect2(522,600,449,47),18,MUTED)

func show_menu() -> void:
	sheet("A moment’s rest","Your journey saves automatically at checkpoints and as you explore.")
	button(overlay,"Return to the village",Rect2(150,211,446,66),func():
		if GameState.data.map == "inn": change_map("inn",Vector2(650,480))
		else: change_map("brackenford",Vector2(615,440)))
	button(overlay,"Settings",Rect2(625,211,446,66),func(): show_settings(show_menu))
	button(overlay,"How to play",Rect2(150,299,446,66),func(): show_help(show_menu))
	button(overlay,"Credits",Rect2(625,299,446,66),show_credits)
	button(overlay,"Save & title",Rect2(150,387,446,66),func():
		if GameState.save_game(): show_title()
		else: show_notice("Couldn’t save",GameState.load_message,show_menu))
	text_at(overlay,"Need to find your footing? “Return to the village” moves you to safe ground without losing your story progress.",Rect2(150,484,950,81),23,MUTED)

func show_settings(back: Callable) -> void:
	sheet("Make yourself comfortable","Every important sound cue also has a visible cue.")
	modal_back = back
	button(overlay,"Music: " + ("on" if GameState.data.settings.music else "off"),Rect2(150,211,890,68),func():
		GameState.data.settings.music = not GameState.data.settings.music
		update_music()
		if mode != "title" and GameState.data.stage > 0: GameState.save_game()
		show_settings(back))
	button(overlay,"Walking animation: " + ("on" if GameState.data.settings.motion else "reduced"),Rect2(150,302,890,68),func():
		GameState.data.settings.motion = not GameState.data.settings.motion
		update_music()
		if GameState.data.stage > 0: GameState.save_game()
		show_settings(back))
	button(overlay,"Dialogue text: " + ("large" if GameState.data.settings.large_text else "standard"),Rect2(150,393,890,68),func():
		GameState.data.settings.large_text = not GameState.data.settings.large_text
		if GameState.data.stage > 0: GameState.save_game()
		show_settings(back))
	button(overlay,"Done",Rect2(150,585,830,66),back)
	# Replace the generic sheet back button, including when opened from title.
	for child in overlay.get_children():
		if child is Button and child.text == "Back":
			child.pressed.disconnect(close_overlay)
			child.pressed.connect(back)

func show_help(back: Callable) -> void:
	show_notice("A few things before you go","WALK  •  Tap open ground. Tap a person or marker to approach and interact. On a keyboard, use WASD / arrows and E.\n\nSTORY  •  Gold diamonds mark your next objective. Read it in the top-left card or journal.\n\nBATTLE  •  Rowan’s Opening Cut makes the next two hits stronger. Cael’s Shield Bash cancels an enemy turn. Guard a charge and recover focus.\n\nFISHING  •  No timer. Read the water before choosing. Reel at rest, guide a turn, give line during a surge.",back)

func show_credits() -> void:
	show_notice("The people behind the dawn","Created for Jamie’s JRPG project.\n\nStory, implementation, original music and art direction developed with OpenAI Codex. Backgrounds, character sheets and portraits generated with OpenAI image generation.\n\nBuilt with Godot Engine 4.5.1 (MIT). Interface headings use DejaVu Serif (Bitstream Vera / DejaVu licence). Full notices are in the repository.\n\nThis is an original work inspired by a love of classic role-playing games. Opening prototype 0.1.0.",show_menu)

func show_notice(title: String, body: String, done: Callable) -> void:
	modal_back = done
	prepare_overlay("notice")
	box(overlay,Rect2(105,48,1070,624),INK,GOLD)
	text_at(overlay,title,Rect2(145,77,960,60),38,GOLD,true)
	text_at(overlay,body,Rect2(148,167,960,398),23)
	button(overlay,"Continue",Rect2(837,588,291,60),done)

func show_ending() -> void:
	show_notice("For one evening, the world can wait.","You’ve reached the end of Brackenford’s opening.\n\nRowan is home. Cael walks beside him. Mira has a classroom to build. A stranger has brought a question no one quite wants to answer.\n\nThe next chapter will follow the festival and the first fracture in that ordinary life.\n\nYou can keep exploring, catch fish, earn Orren’s charm and sell your catch. Your journey will be saved.",func(): refresh_world(); GameState.save_game())

func meter(parent: Node, pos: Vector2, width: float, current: float, maximum: float, color: Color, caption: String) -> void:
	box(parent,Rect2(pos,Vector2(width,15)),Color("0b1d24"),Color("51635c"))
	if current > 0:
		box(parent,Rect2(pos,Vector2(maxf(8,width*clampf(current/maximum,0,1)),15)),color,color)
	text_at(parent,caption,Rect2(pos+Vector2(0,20),Vector2(width,30)),18,PAPER)

func start_battle() -> void:
	GameState.save_game()
	battle = Battle.new(GameState.data.charm,int(GameState.data.herbs))
	selected_enemy = 0
	show_battle()

func show_battle() -> void:
	prepare_overlay("battle",false)
	picture(overlay,World.BACKGROUNDS.woodland,Rect2(0,0,1280,720))
	box(overlay,Rect2(24,18,1232,84),Color(0.055,0.12,0.14,0.95),GOLD)
	text_at(overlay,"The stranded cart",Rect2(45,29,448,42),30,PAPER,true)
	text_at(overlay,"ROUND %d  •  %s" % [battle.round_number,battle.intent()],Rect2(482,36,748,44),21,GOLD)
	for i in range(2):
		var hero: Dictionary = battle.heroes[i]
		picture(overlay,World.WALK,Rect2(365+i*137,225+i*30,200,200),Rect2((1 if i==0 else 4)*256,2*256,256,256))
		box(overlay,Rect2(27,125+i*119,340,104),Color(0.055,0.12,0.14,0.96),GOLD if battle.actor==i else Color("566d62"))
		portrait(overlay,hero.name,Rect2(34,134+i*119,73,73))
		text_at(overlay,"%s  %s" % [hero.name,"‹ YOUR TURN" if battle.actor==i else ""],Rect2(120,132+i*119,236,28),19,GOLD if battle.actor==i else PAPER)
		meter(overlay,Vector2(121,169+i*119),226,hero.hp,hero.max_hp,Color("72ad94"),"%d / %d HP    %d / %d focus" % [hero.hp,hero.max_hp,hero.mp,hero.max_mp])
	for i in range(2):
		var enemy: Dictionary = battle.enemies[i]
		var x := 720.0 + i*269
		if enemy.hp > 0:
			picture(overlay,PEOPLE,Rect2(x-48,216+i*38,265,265),Rect2(512,512,512,512))
		var target := button(overlay,("◎ " if selected_enemy==i else "")+enemy.name,Rect2(x-43,118,250,58),func(): selected_enemy=i; show_battle())
		target.disabled = enemy.hp <= 0
		meter(overlay,Vector2(x-31,187),222,enemy.hp,enemy.max_hp,Color("ca916b"),"%d / %d HP%s" % [enemy.hp,enemy.max_hp," • exposed" if enemy.exposed>0 else ""])
	box(overlay,Rect2(24,465,1232,233),Color(0.055,0.12,0.14,0.98),GOLD)
	var recent := "\n".join(battle.log_lines.slice(maxi(0,battle.log_lines.size()-3)))
	text_at(overlay,recent,Rect2(47,480,1188,97),22)
	if battle.outcome != "":
		if battle.outcome == "victory":
			text_at(overlay,"The path is clear. Lantern oil recovered • +30 crowns",Rect2(48,592,786,58),25,GOLD)
			button(overlay,"Catch your breath",Rect2(884,611,344,63),func():
				GameState.data.herbs = battle.herbs
				GameState.event("battle",6)
				dialogue("victory",refresh_world))
		else:
			text_at(overlay,"A close call. Retry with your supplies restored.",Rect2(48,591,741,61),25,GOLD)
			button(overlay,"Retry",Rect2(839,611,184,63),start_battle)
			button(overlay,"Retreat",Rect2(1040,611,188,63),close_overlay)
		return
	var hero: Dictionary = battle.heroes[battle.actor]
	button(overlay,"Strike",Rect2(46,606,221,68),func(): battle_action("attack"))
	var skill := button(overlay,"Opening Cut · 2" if battle.actor==0 else "Shield Bash · 3",Rect2(282,606,330,68),func(): battle_action("skill"))
	skill.disabled = hero.mp < (2 if battle.actor==0 else 3)
	button(overlay,"Guard · +1 focus",Rect2(628,606,297,68),func(): battle_action("guard"))
	var herb := button(overlay,"Herb (%d)" % battle.herbs,Rect2(941,606,286,68),func(): battle_action("herb"))
	herb.disabled = battle.herbs <= 0 or battle.heroes.all(func(h): return h.hp==h.max_hp)

func battle_action(action: String) -> void:
	if battle.act(action,selected_enemy):
		if battle.enemies[selected_enemy].hp <= 0:
			selected_enemy = 1-selected_enemy
		show_battle()

func fishing_setup() -> void:
	sheet("A little patience. A little skill.","Orren’s landing  /  Rivercraft")
	portrait(overlay,"Orren",Rect2(151,219,198,198))
	text_at(overlay,"Where will you cast?",Rect2(384,208,702,55),34,GOLD,true)
	text_at(overlay,"The reed beds hold silver minnows. River perch favour the deeper channel.\n\nThere’s no timer: read the water and choose your next move.",Rect2(386,277,691,171),25)
	button(overlay,"Reed beds",Rect2(384,469,316,66),func(): start_fishing(false))
	button(overlay,"Deep channel",Rect2(719,469,343,66),func(): start_fishing(true))
	text_at(overlay,"%d / 3 catches toward Orren’s riverglass charm" % mini(3,int(GameState.data.catches)),Rect2(151,583,812,66),23,MUTED)

func start_fishing(deep: bool) -> void:
	fishing = Fishing.new(deep)
	show_fishing()

func show_fishing() -> void:
	prepare_overlay("fishing")
	box(overlay,Rect2(112,57,1056,606),INK,GOLD)
	text_at(overlay,"Reading the river",Rect2(149,77,887,55),38,GOLD,true)
	text_at(overlay,"DEEP CHANNEL" if fishing.deep else "THE REED BEDS",Rect2(151,141,917,32),18,MUTED)
	text_at(overlay,fishing.clue() if fishing.outcome=="" else fishing.last_line,Rect2(151,204,960,106),31,PAPER,true)
	meter(overlay,Vector2(151,343),453,fishing.progress,100,Color("78b9a4"),"CLOSER TO SHORE  •  %d%%" % fishing.progress)
	meter(overlay,Vector2(651,343),453,fishing.tension,100,Color("d09970"),"LINE TENSION  •  %d%% / 100%%" % fishing.tension)
	text_at(overlay,fishing.last_line,Rect2(151,414,954,66),23,MUTED)
	if fishing.outcome == "":
		button(overlay,"Reel in",Rect2(150,505,303,67),func(): fish_action("reel"))
		button(overlay,"Give line",Rect2(474,505,303,67),func(): fish_action("give"))
		button(overlay,"Guide the rod",Rect2(798,505,306,67),func(): fish_action("guide"))
		text_at(overlay,"Reel at rest. Guide a turn. Give line during a surge.",Rect2(151,602,726,44),20,MUTED)
		button(overlay,"Put rod away",Rect2(902,588,201,55),close_overlay)
	else:
		var reward := "%d / 3 catches • fish added to your satchel" % mini(3,int(GameState.data.catches)) if fishing.outcome=="caught" else "No supplies lost. The next cast is a fresh start."
		if GameState.data.charm: reward = "Riverglass charm earned • Rowan’s maximum health +4"
		text_at(overlay,reward,Rect2(151,494,950,51),24,GOLD)
		button(overlay,"Cast again",Rect2(151,579,454,62),fishing_setup)
		button(overlay,"Back to the village",Rect2(626,579,478,62),close_overlay)

func fish_action(action: String) -> void:
	if fishing.act(action):
		if fishing.outcome == "caught": GameState.caught_fish()
		show_fishing()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if mode == "explore": show_menu()
			elif mode in ["menu","notice"] and modal_back.is_valid(): modal_back.call()
		elif event.keycode in [KEY_SPACE,KEY_ENTER] and mode == "dialogue": next_line()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if mode != "title" and GameState.data.stage > 0: GameState.save_game()
		get_tree().quit()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if mode == "explore": show_menu()
		elif mode == "dialogue": pass
		elif mode in ["menu","notice"] and modal_back.is_valid(): modal_back.call()

func capture(name_value: String) -> void:
	await RenderingServer.frame_post_draw
	var directory := OS.get_environment("JRPG_SCREENSHOTS")
	if directory == "": directory = "/tmp/jrpg-screenshots"
	DirAccess.make_dir_recursive_absolute(directory)
	get_viewport().get_texture().get_image().save_png(directory.path_join(name_value+".png"))

func run_qa() -> void:
	await get_tree().create_timer(0.5).timeout
	await capture("01-title")
	start_new()
	await capture("02-dialogue")
	skip_dialogue()
	# Exercise the actual input route, not only the story callbacks.
	var tap := InputEventMouseButton.new()
	tap.position = Vector2(730,500)
	tap.global_position = tap.position
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	Input.parse_input_event(tap)
	var release := tap.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await get_tree().create_timer(0.8).timeout
	assert(world.foot.distance_to(Vector2(730,500)) < 12,"Ground tap moves Rowan")
	interact("parcel")
	skip_dialogue()
	interact("exit_inn")
	await capture("03-village")
	interact("orren")
	skip_dialogue()
	interact("cael")
	skip_dialogue()
	interact("north")
	skip_dialogue()
	await capture("04-woodland")
	interact("cart")
	skip_dialogue()
	await capture("05-battle")
	var steps := 0
	while battle.outcome == "" and steps < 40:
		var action := "attack"
		if battle.actor==0 and battle.heroes[0].mp >= 2: action="skill"
		if battle.actor==1 and battle.heroes[1].mp >= 3 and battle.round_number%2==0: action="skill"
		if battle.herbs>0 and battle.heroes.any(func(h): return h.hp<25): action="herb"
		battle_action(action)
		steps += 1
	assert(battle.outcome=="victory","Opening battle is winnable")
	GameState.data.herbs = battle.herbs
	GameState.event("battle",6)
	interact("south")
	interact("inn")
	interact("mira")
	skip_dialogue()
	interact("ysra")
	skip_dialogue()
	await capture("06-opening-complete")
	refresh_world()
	interact("exit_inn")
	world.foot = Vector2(1120,506)
	start_fishing(false)
	await capture("07-fishing")
	for cast in range(3):
		start_fishing(false)
		while fishing.outcome == "":
			fish_action({"turn":"guide","surge":"give","rest":"reel","dive":"guide"}[fishing.cue()])
		assert(fishing.outcome=="caught")
	assert(GameState.data.charm and GameState.data.stage==8)
	await capture("08-fishing-reward")
	show_journal()
	await capture("09-journal")
	print("UI_QA_PASS: opening completed, battle won, 3 fish caught, charm earned")
	clear(overlay)
	clear(hud)
	battle = null
	fishing = null
	music.stop()
	music.stream = null
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit.call_deferred()
