# QuackCraft - HUD overlay
# Desktop mouse-look + mining/placing fallback; mobile controls do touch.
extends CanvasLayer

const B = preload("res://scripts/blocks/BlockRegistry.gd")

var player: Node = null
var day_night: Node = null
var world: Node = null

var mouse_captured: bool = false
var inventory_ui: Control = null

func setup(p: Node, dn: Node, w: Node) -> void:
	player = p
	day_night = dn
	world = w
	# Build a minimal HUD (crosshair already handled by MobileControls, but this
	# layer also handles desktop mouse capture on non-touch platforms)
	_build()

func _build() -> void:
	# Add a hidden inventory UI as child
	var inv_script = load("res://scripts/ui/InventoryUI.gd")
	inventory_ui = Control.new()
	inventory_ui.set_script(inv_script)
	inventory_ui.name = "InventoryUI"
	inventory_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(inventory_ui)
	inventory_ui.setup(player)

	# Capture mouse for desktop-style play
	_capture_mouse(true)

func _capture_mouse(c: bool) -> void:
	mouse_captured = c
	if c:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if inventory_ui != null and inventory_ui.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			inventory_ui.toggle()
		return
	# Desktop mouse capture
	if event is InputEventMouseMotion and mouse_captured:
		if player:
			var sens := Settings.look_sensitivity * 0.25
			player.look_around(event.relative.y * sens, event.relative.x * sens)
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if player: player.try_attack()
			MOUSE_BUTTON_RIGHT:
				if player: player.try_place_block()
			MOUSE_BUTTON_WHEEL_UP:
				if player: player.scroll_hotbar(-1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if player: player.scroll_hotbar(1)
	elif event is InputEventMouseButton and not event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if player: player.release_attack()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_capture_mouse(not mouse_captured)

func _process(_delta: float) -> void:
	# Show mining crack overlay
	if player != null and player.mining:
		var p = player.get_mining_progress()
		# Update crosshair color via mobile controls crack overlay
		var mc = get_parent().get_node_or_null("MobileControls")
		if mc != null:
			var stage := int(p * 10)
			mc.set_crack_stage(stage)
	else:
		var mc = get_parent().get_node_or_null("MobileControls")
		if mc != null:
			mc.set_crack_stage(0)
