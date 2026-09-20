extends RefCounted
var progress := 0
var tension := 18
var turn := 0
var outcome := ""
var deep := false
var last_line := "Watch the water, then choose your next move."
const CUES = ["turn", "surge", "rest", "dive", "rest", "turn", "surge", "rest"]

func _init(channel: bool = false) -> void:
	deep = channel

func cue() -> String:
	return CUES[(turn + (2 if deep else 0)) % CUES.size()]

func clue() -> String:
	return {"turn":"The float drifts sideways. Guide the rod with it.",
		"surge":"A silver flash! It surges away. Let the line run.",
		"rest":"The ripples soften. Now is the time to reel.",
		"dive":"It dives under the reeds. Keep the line from tightening."}[cue()]

func act(action: String) -> bool:
	if outcome != "" or action not in ["reel", "give", "guide"]:
		return false
	match action:
		"reel":
			progress += 30 if cue() == "rest" else 22
			tension += 12 if cue() == "rest" else (43 if cue() == "surge" else 26)
			last_line = "You draw the fish closer."
		"give":
			progress = maxi(0, progress - 3)
			tension -= 34
			last_line = "The line loosens; the rod steadies."
		"guide":
			progress += 21 if cue() == "turn" else 12
			tension += -12 if cue() == "turn" else (16 if cue() == "surge" else 5)
			last_line = "You lead the fish clear of the reeds."
	turn += 1
	tension = maxi(0, tension)
	if tension >= 100:
		outcome = "escaped"
		last_line = "The line snaps loose. The river keeps this one."
	elif progress >= 100:
		progress = 100
		outcome = "caught"
		last_line = "Caught: %s!" % ("river perch" if deep else "silver minnow")
	elif turn >= 14:
		outcome = "escaped"
		last_line = "It slips into the reeds. Try drawing it closer sooner."
	return true
