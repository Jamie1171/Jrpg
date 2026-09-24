extends Node
## Godot-normalised Xbox layout. Own the joy events so GUI actions cannot fire twice.
signal button_pressed(index: int)
signal activity_changed
const DEADZONE := 0.22
var active := false
var device := -1
var focused := true
var waiting_neutral := false
var axes := Vector4.ZERO
var held: Dictionary = {}

func _ready() -> void:
	Input.joy_connection_changed.connect(connection_changed)

func set_active(value: bool) -> void:
	if active != value:
		active=value
		activity_changed.emit()

func radial(value: Vector2) -> Vector2:
	var magnitude := value.length()
	if magnitude <= DEADZONE: return Vector2.ZERO
	return value.normalized()*clampf((magnitude-DEADZONE)/(1.0-DEADZONE),0,1)

func movement() -> Vector2:
	return radial(Vector2(axes.x,axes.y)) if focused and not waiting_neutral else Vector2.ZERO

func look() -> Vector2:
	return radial(Vector2(axes.z,axes.w)) if focused and not waiting_neutral else Vector2.ZERO

func navigation() -> Vector2:
	if not focused: return Vector2.ZERO
	var value := Vector2(float(held.get(JOY_BUTTON_DPAD_RIGHT,false))-float(held.get(JOY_BUTTON_DPAD_LEFT,false)),float(held.get(JOY_BUTTON_DPAD_DOWN,false))-float(held.get(JOY_BUTTON_DPAD_UP,false)))
	return value if value != Vector2.ZERO else movement()

func require_neutral() -> void:
	waiting_neutral = Vector2(axes.x,axes.y).length()>DEADZONE or Vector2(axes.z,axes.w).length()>DEADZONE

func reset() -> void:
	axes=Vector4.ZERO
	held.clear()

func connection_changed(id: int, connected: bool) -> void:
	if not connected and id==device:
		reset()
		device=-1
		waiting_neutral=false
		set_active(false)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		set_active(false)
	elif event is InputEventMouseButton and event.pressed and event.device != -1:
		set_active(false)
	elif event is InputEventKey and event.pressed:
		set_active(false)
	if not event is InputEventJoypadMotion and not event is InputEventJoypadButton: return
	get_viewport().set_input_as_handled()
	if not focused: return
	if device != -1 and event.device != device: return
	if event is InputEventJoypadMotion:
		if event.axis > JOY_AXIS_RIGHT_Y: return
		device=event.device
		axes[event.axis]=event.axis_value
		if waiting_neutral and Vector2(axes.x,axes.y).length()<=DEADZONE and Vector2(axes.z,axes.w).length()<=DEADZONE: waiting_neutral=false
		if absf(event.axis_value)>DEADZONE: set_active(true)
	elif event is InputEventJoypadButton:
		device=event.device
		var was_held: bool = held.get(event.button_index,false)
		held[event.button_index]=event.pressed
		if event.pressed and not was_held:
			set_active(true)
			button_pressed.emit(event.button_index)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		focused=false
		reset()
		waiting_neutral=true
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]:
		focused=true
