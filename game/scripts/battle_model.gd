extends RefCounted
## Pure turn-based rules, independent of animation and frame rate.
var heroes: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var actor := 0
var round_number := 1
var herbs := 3
var outcome := ""
var log_lines: Array[String] = []

func _init(charm: bool = false, herb_count: int = 3) -> void:
	var bonus := 4 if charm else 0
	heroes = [
		{"name":"Rowan", "hp":64+bonus, "max_hp":64+bonus, "mp":8, "max_mp":8, "attack":13, "guard":false},
		{"name":"Cael", "hp":78, "max_hp":78, "mp":7, "max_mp":7, "attack":16, "guard":false}]
	enemies = [
		{"name":"Mossback", "hp":86, "max_hp":86, "attack":13, "exposed":0, "stagger":false},
		{"name":"Young boar", "hp":38, "max_hp":38, "attack":8, "exposed":0, "stagger":false}]
	herbs = herb_count
	log_lines = ["Cael: Watch their shoulders. Brace when they lower their heads."]

func intent() -> String:
	return "CHARGE • Guard or use Shield Bash." if round_number % 2 == 0 else "PROWL • A good moment to attack."

func act(action: String, target: int = 0) -> bool:
	if outcome != "" or actor < 0 or actor >= heroes.size():
		return false
	if action not in ["attack", "skill", "guard", "herb"]:
		return false
	var hero: Dictionary = heroes[actor]
	if action in ["attack", "skill"] and (target < 0 or target >= enemies.size() or enemies[target].hp <= 0):
		return false
	var cost := 2 if actor == 0 else 3
	if action == "skill" and hero.mp < cost:
		return false
	if action == "herb" and (herbs <= 0 or heroes.all(func(h): return h.hp == h.max_hp)):
		return false
	match action:
		"attack", "skill":
			var enemy: Dictionary = enemies[target]
			var damage: int = int(hero.attack)
			if action == "skill":
				hero.mp -= cost
				damage = 8 if actor == 0 else 14
			if enemy.exposed > 0:
				damage = int(ceil(damage * 1.5))
				enemy.exposed -= 1
			enemy.hp = maxi(0, int(enemy.hp) - damage)
			if action == "skill":
				if actor == 0:
					enemy.exposed = 2
				else:
					enemy.stagger = true
			var verb := "strikes" if action == "attack" else ("uses Opening Cut on" if actor == 0 else "uses Shield Bash on")
			log_lines.append("%s %s %s • %d damage." % [hero.name, verb, enemy.name, damage])
		"guard":
			hero.guard = true
			hero.mp = mini(int(hero.max_mp), int(hero.mp) + 1)
			log_lines.append("%s braces • damage reduced, 1 focus restored." % hero.name)
		"herb":
			herbs -= 1
			var wounded: Dictionary = heroes[0]
			for member in heroes:
				if float(member.hp) / member.max_hp < float(wounded.hp) / wounded.max_hp:
					wounded = member
			wounded.hp = mini(int(wounded.max_hp), int(wounded.hp) + 32)
			log_lines.append("%s uses a herb • %s recovers 32 health." % [hero.name, wounded.name])
	if enemies.all(func(e): return e.hp <= 0):
		outcome = "victory"
		return true
	actor += 1
	while actor < heroes.size() and heroes[actor].hp <= 0:
		actor += 1
	if actor >= heroes.size():
		enemy_turn()
	return true

func enemy_turn() -> void:
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		if enemy.hp <= 0:
			continue
		if enemy.stagger:
			enemy.stagger = false
			log_lines.append("%s stumbles and loses its turn." % enemy.name)
			continue
		var index: int = (round_number + i) % heroes.size()
		if heroes[index].hp <= 0:
			index = 1 - index
		if heroes[index].hp <= 0:
			break
		var hero: Dictionary = heroes[index]
		var damage: int = int(enemy.attack) * (2 if round_number % 2 == 0 else 1)
		if hero.guard:
			damage = maxi(1, int(ceil(damage * 0.4)))
		hero.hp = maxi(0, int(hero.hp) - damage)
		log_lines.append("%s %s %s • %d damage." % [enemy.name, "charges" if round_number % 2 == 0 else "strikes", hero.name, damage])
	for hero in heroes:
		hero.guard = false
	if heroes.all(func(h): return h.hp <= 0):
		outcome = "defeat"
	actor = 0
	while actor < heroes.size() and heroes[actor].hp <= 0:
		actor += 1
	round_number += 1
