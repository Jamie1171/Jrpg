extends SceneTree
var world: Node3D
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	world = load("res://scripts/world_3d.gd").new()
	root.add_child(world)
	world.setup("brackenford",Vector2(-9.4,4.0),[],false,"")
	world.enabled = false
	world.player.rotation.y = -.5
	world.pivot.position = Vector3(-8.6,.85,3)
	world.pitch = -.26
	world.yaw = .35
	world.pivot.rotation = Vector3(world.pitch,world.yaw,0)
	world.arm.spring_length = 4.3
	for i in range(12): await process_frame
	assert(world.scene.get_node("IronOutcrop") != null)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/ore-godot.png")
	print("ORE_PREVIEW_PASS")
	quit()
