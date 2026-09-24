extends Node
## All irreversible rewards are keyed events. Saves are offline and atomic.
signal changed
var save_path = "user://dawn-save.json"
var data: Dictionary = {}
var load_message := ""
var saving_enabled := true

func _ready() -> void:
	data = fresh()

func fresh() -> Dictionary:
	return {"version":1, "stage":0, "map":"inn", "position":[0,4],
		"gold":0, "herbs":3, "fish":0, "catches":0, "charm":false,
		"party":false, "events":[], "history":[],
		"settings":{"music":true, "motion":true, "large_text":false}}

func new_game() -> void:
	var settings: Dictionary = data.get("settings", fresh().settings).duplicate()
	data = fresh()
	data.settings = settings
	save_game()
	changed.emit()

func has_save() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak")

func valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if value.get("version") != 1:
		return false
	for key in ["stage", "gold", "herbs", "fish", "catches"]:
		if not value.get(key) is float and not value.get(key) is int:
			return false
		if value[key] < 0 or value[key] > 100000:
			return false
	if value.stage > 8 or value.get("map") not in ["inn", "brackenford", "woodland"]:
		return false
	if not value.get("position") is Array or value.position.size() != 2:
		return false
	for n in value.position:
		if (not n is float and not n is int) or not is_finite(float(n)):
			return false
	for key in ["events", "history"]:
		if not value.get(key) is Array:
			return false
		for entry in value[key]:
			if not entry is String:
				return false
	if not value.get("party") is bool or not value.get("charm") is bool:
		return false
	if not value.get("settings") is Dictionary:
		return false
	for key in ["music", "motion", "large_text"]:
		if not value.settings.get(key) is bool:
			return false
	return true

func read_save(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	var parsed = parser.data
	return parsed if valid(parsed) else null

func load_game() -> bool:
	load_message = ""
	var loaded = read_save(save_path)
	if loaded == null:
		loaded = read_save(save_path + ".bak")
		if loaded != null:
			load_message = "Your previous checkpoint was recovered."
	if loaded == null:
		load_message = "The saved journey could not be read. Your existing files have been kept."
		return false
	data = loaded
	changed.emit()
	return true

func save_game() -> bool:
	if not saving_enabled:
		return true
	var file = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		load_message = "Saving failed. Please free some device storage."
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	# Never overwrite a valid backup with a corrupt primary save.
	if read_save(save_path) != null:
		DirAccess.copy_absolute(save_path, save_path + ".bak")
	var result = DirAccess.rename_absolute(save_path + ".tmp", save_path)
	if result != OK:
		load_message = "Saving failed. Please free some device storage."
	return result == OK

func event(key: String, stage: int = -1) -> bool:
	if key in data.events:
		return false
	data.events.append(key)
	if stage >= 0:
		data.stage = maxi(int(data.stage), stage)
	match key:
		"delivery": data.gold += 12
		"cael": data.party = true
		"battle": data.gold += 30
		"riverglass": data.charm = true
	save_game()
	changed.emit()
	return true

func caught_fish() -> void:
	data.fish += 1
	data.catches += 1
	if data.catches >= 3:
		event("riverglass")
	save_game()
	changed.emit()

func sell_fish() -> int:
	var price: int = int(data.fish) * 6
	data.gold += price
	data.fish = 0
	save_game()
	changed.emit()
	return price

func remember(speaker: String, line: String) -> void:
	data.history.append(speaker + ": " + line)
	if data.history.size() > 120:
		data.history.pop_front()

func objective() -> String:
	return ["A morning at the Hearth & Heron", "Pick up Mira’s parcel by the bar.",
		"Deliver Mira’s parcel to Orren at the landing.", "Find Cael by the northern village path.",
		"Follow Cael into the woodland.", "Check the stranded cart in the woodland.",
		"Bring the lantern oil home to Mira.", "Speak to the traveller at the inn.",
		"Opening complete • Explore, fish, or visit your journal."][int(data.stage)]

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and data.get("stage", 0) > 0:
		save_game()
