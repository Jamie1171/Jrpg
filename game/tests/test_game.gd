extends SceneTree
const Battle = preload("res://scripts/battle_model.gd")
const Fishing = preload("res://scripts/fishing_model.gd")
const State = preload("res://scripts/game_state.gd")
const World = preload("res://scripts/world_view.gd")
var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state = State.new()
	root.add_child(state)
	state.saving_enabled = false
	state.new_game()
	check(state.valid(state.data),"Fresh state validates")
	check(not state.valid({"version":1}),"Incomplete save rejected")
	var bad: Dictionary = state.fresh()
	bad.stage = 99
	check(not state.valid(bad),"Unknown stage rejected")
	bad = state.fresh()
	bad.position = ["bad",0]
	check(not state.valid(bad),"Invalid position rejected")
	state.event("intro",1)
	state.event("parcel",2)
	state.event("delivery",3)
	state.event("delivery",3)
	check(state.data.gold==12 and state.data.stage==3,"Delivery reward is idempotent")
	state.event("cael",4)
	check(state.data.party,"Cael joins")
	state.event("woodland",5)
	state.event("battle",6)
	state.event("battle",6)
	check(state.data.gold==42,"Battle reward is idempotent")
	state.event("home",7)
	state.event("ysra",8)
	check(state.data.stage==8,"Story can reach completion")
	for i in range(3): state.caught_fish()
	check(state.data.charm and state.data.catches==3 and state.data.fish==3,"Three catches earn charm")
	check(state.sell_fish()==18 and state.data.fish==0,"Selling transfers all fish")
	check(state.sell_fish()==0 and state.data.gold==60,"Empty inventory cannot sell twice")
	state.save_path = "user://qa-save.json"
	state.saving_enabled = true
	check(state.save_game(),"First save writes successfully")
	state.data.gold = 77
	check(state.save_game(),"Atomic replacement writes successfully")
	state.data.gold = 0
	check(state.load_game() and state.data.gold==77,"Saved progress survives reload")
	var corrupt := FileAccess.open(state.save_path,FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	check(state.load_game() and state.data.gold==60,"Corrupt primary recovers previous checkpoint")
	check(state.load_message!="","Recovery is reported to the player")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(state.save_path+suffix)
	state.saving_enabled = false
	var battle = Battle.new(true,3)
	check(battle.heroes[0].max_hp==68,"Optional charm improves health")
	check(not battle.act("skill",-1),"Invalid target rejected")
	check(battle.heroes[0].mp==8 and battle.actor==0,"Invalid target doesn't consume focus or turn")
	check(not battle.act("herb"),"Full-health herb use rejected")
	check(battle.act("skill",0),"Opening Cut accepted")
	check(battle.enemies[0].exposed==2,"Opening Cut applies exposure")
	var before: int = battle.enemies[0].hp
	battle.act("attack",0)
	check(before-battle.enemies[0].hp==24,"Cael benefits from Rowan's exposure")
	check(battle.round_number==2,"Enemy phase advances round")
	battle.act("guard",0)
	battle.act("skill",0)
	check(battle.log_lines.any(func(line): return "loses its turn" in line),"Shield Bash cancels a charge")
	var steps := 0
	while battle.outcome=="" and steps<45:
		var target := 0 if battle.enemies[0].hp>0 else 1
		var action := "attack"
		if battle.actor==0 and battle.heroes[0].mp>=2: action="skill"
		if battle.actor==1 and battle.heroes[1].mp>=3 and battle.round_number%2==0: action="skill"
		if battle.herbs>0 and battle.heroes.any(func(h): return h.hp<25): action="herb"
		check(battle.act(action,target),"Battle action advances")
		steps += 1
	check(battle.outcome=="victory","First encounter is winnable")
	check(not battle.act("attack",0),"Completed battle rejects actions")
	for deep in [false,true]:
		var fish = Fishing.new(deep)
		while fish.outcome=="":
			fish.act({"turn":"guide","surge":"give","rest":"reel","dive":"guide"}[fish.cue()])
		check(fish.outcome=="caught","Both fishing spots reward reading the cues")
		check(not fish.act("reel"),"Finished fishing rejects duplicate catch")
	var recklessness = Fishing.new()
	while recklessness.outcome=="": recklessness.act("reel")
	check(recklessness.outcome=="escaped","Ignoring tension can lose a fish")
	var world = World.new()
	root.add_child(world)
	for map_id in ["inn","brackenford","woodland"]:
		world.setup(map_id,Vector2(650,460),[],false,"")
		for dest in [Vector2(20,20),Vector2(1200,690),Vector2(1070,510),Vector2(610,245)]:
			var path: Array[Vector2] = world.route(world.foot,dest)
			check(not path.is_empty(),"Navigation finds a route on " + map_id)
			var previous: Vector2 = world.foot
			for point in path:
				check(world.visible_segment(previous,point),"Navigation stays within walkable floor")
				previous=point
	world.queue_free()
	state.queue_free()
	print("RULE_TESTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures>0 else 0)
