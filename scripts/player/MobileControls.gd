# QuackCraft - Mobile touch controls overlay
# Renders joystick (left), look area (right), jump + inventory buttons,
# and the hotbar. Reports intent back to the Player.
extends CanvasLayer

const PlayerClass = preload("res://scripts/player/Player.gd")

var player: Node = null
var look_sensitivity: float = 0.4

# Joystick
var joystick_base: Control
var joystick_knob: Control
var joystick_origin: Vector2 = Vector2.ZERO
var joystick_active: bool = false
var joystick_touch_idx: int = -1
var joystick_value: Vector2 = Vector2.ZERO

# Look
var look_touch_idx: int = -1
var look_last_pos: Vector2 = Vector2.ZERO

# Mining/placing touch
var action_touch_idx: int = -1
var action_pos: Vector2 = Vector2.ZERO
var action_held_time: float = 0.0
var action_is_mining: bool = false
var action_swiped: bool = false

# Buttons
var jump_button: Button
var inventory_button: Button
var up_button: Button  # for hotbar scroll up
var down_button: Button

# Hotbar
var hotbar_container: HBoxContainer
var hotbar_slots: Array = []
const HOTBAR_SLOT_COUNT := 9

# Crosshair
var crosshair: ColorRect

# Look area (right half of screen)
var look_area: Control

# Health/hunger bars
var health_bar: ProgressBar
var hunger_bar: ProgressBar

# Mining crack overlay
var crack_overlay: TextureRect

# Day-night clock
var clock_label: Label

func _ready() -> void:
	layer = 10
	_build_ui()

func _build_ui() -> void:
	# Full-screen touch surface
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Look area (right 60% of screen) — passes drags to camera
	look_area = Control.new()
	look_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	look_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(look_area)

	# Crosshair in center
	crosshair = ColorRect.new()
	crosshair.color = Color(1, 1, 1, 0.85)
	crosshair.size = Vector2(4, 4)
	crosshair.position = Vector2(get_viewport().get_visible_rect().size * 0.5) - Vector2(2, 2)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crosshair)

	# Joystick base (bottom-left)
	joystick_base = Control.new()
	joystick_base.size = Vector2(180, 180)
	joystick_base.position = Vector2(40, get_viewport().get_visible_rect().size.y - 220)
	joystick_base.mouse_filter = Control.MOUSE_FILTER_STOP
	joystick_base.add_theme_stylebox_override("panel", _circle_style(Color(1, 1, 1, 0.15)))
	root.add_child(joystick_base)

	joystick_knob = Control.new()
	joystick_knob.size = Vector2(80, 80)
	joystick_knob.position = Vector2(50, 50)
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_knob.add_theme_stylebox_override("panel", _circle_style(Color(1, 1, 1, 0.35)))
	joystick_base.add_child(joystick_knob)

	# Jump button (bottom-right area)
	jump_button = Button.new()
	jump_button.text = "JUMP"
	jump_button.size = Vector2(110, 110)
	jump_button.position = Vector2(get_viewport().get_visible_rect().size.x - 240, get_viewport().get_visible_rect().size.y - 220)
	jump_button.modulate = Color(1, 1, 1, 0.65)
	jump_button.mouse_filter = Control.MOUSE_FILTER_STOP
	jump_button.button_down.connect(_on_jump_down)
	jump_button.button_up.connect(_on_jump_up)
	root.add_child(jump_button)

	# Inventory button (top-right)
	inventory_button = Button.new()
	inventory_button.text = "INV"
	inventory_button.size = Vector2(90, 70)
	inventory_button.position = Vector2(get_viewport().get_visible_rect().size.x - 110, 30)
	inventory_button.modulate = Color(1, 1, 1, 0.65)
	inventory_button.pressed.connect(_on_inventory_pressed)
	root.add_child(inventory_button)

	# Hotbar (bottom center)
	hotbar_container = HBoxContainer.new()
	hotbar_container.position = Vector2(get_viewport().get_visible_rect().size.x * 0.5 - HOTBAR_SLOT_COUNT * 30, get_viewport().get_visible_rect().size.y - 75)
	hotbar_container.add_theme_constant_override("separation", 4)
	root.add_child(hotbar_container)
	for i in range(HOTBAR_SLOT_COUNT):
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(56, 56)
		slot.add_theme_stylebox_override("panel", _slot_style(Color(0, 0, 0, 0.55), 2, Color(1, 1, 1, 0.4)))
		var label := Label.new()
		label.text = str(i + 1)
		label.position = Vector2(3, 1)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
		label.add_theme_font_size_override("font", 10)
		slot.add_child(label)
		var icon := ColorRect.new()
		icon.name = "Icon"
		icon.color = Color(0, 0, 0, 0)
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		var count := Label.new()
		count.name = "Count"
		count.position = Vector2(35, 35)
		count.add_theme_color_override("font_color", Color.WHITE)
		count.add_theme_font_size_override("font", 10)
		count.add_theme_outline_size_override("font_outline", 2)
		count.add_theme_color_override("font_outline_color", Color.BLACK)
		slot.add_child(count)
		slot.gui_input.connect(_on_hotbar_slot_input.bind(i))
		hotbar_container.add_child(slot)
		hotbar_slots.append(slot)

	# Health bar (above hotbar, left)
	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.max_value = 20
	health_bar.value = 20
	health_bar.size = Vector2(200, 14)
	health_bar.position = Vector2(get_viewport().get_visible_rect().size.x * 0.5 - 200, get_viewport().get_visible_rect().size.y - 95)
	health_bar.modulate = Color(1, 0.4, 0.4, 0.85)
	root.add_child(health_bar)

	# Hunger bar (right side)
	hunger_bar = ProgressBar.new()
	hunger_bar.min_value = 0
	hunger_bar.max_value = 20
	hunger_bar.value = 20
	hunger_bar.size = Vector2(200, 14)
	hunger_bar.position = Vector2(get_viewport().get_visible_rect().size.x * 0.5 + 0, get_viewport().get_visible_rect().size.y - 95)
	hunger_bar.modulate = Color(0.9, 0.7, 0.2, 0.85)
	root.add_child(hunger_bar)

	# Mining crack overlay (centered, hidden by default)
	crack_overlay = TextureRect.new()
	crack_overlay.size = Vector2(60, 60)
	crack_overlay.position = Vector2(get_viewport().get_visible_rect().size * 0.5) - Vector2(30, 30)
	crack_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crack_overlay.visible = false
	root.add_child(crack_overlay)

	# Day-night clock (top-left)
	clock_label = Label.new()
	clock_label.text = "Day 1"
	clock_label.position = Vector2(15, 15)
	clock_label.add_theme_color_override("font_color", Color.WHITE)
	clock_label.add_theme_font_size_override("font", 14)
	clock_label.add_theme_outline_size_override("font_outline", 2)
	clock_label.add_theme_color_override("font_outline_color", Color.BLACK)
	root.add_child(clock_label)

	# Hotbar scroll buttons (right of hotbar)
	up_button = Button.new()
	up_button.text = "<"
	up_button.size = Vector2(35, 56)
	up_button.position = hotbar_container.position + Vector2(-40, 0)
	up_button.modulate = Color(1, 1, 1, 0.65)
	up_button.pressed.connect(func(): if player: player.scroll_hotbar(-1))
	root.add_child(up_button)

	down_button = Button.new()
	down_button.text = ">"
	down_button.size = Vector2(35, 56)
	down_button.position = hotbar_container.position + Vector2(HOTBAR_SLOT_COUNT * 60, 0)
	down_button.modulate = Color(1, 1, 1, 0.65)
	down_button.pressed.connect(func(): if player: player.scroll_hotbar(1))
	root.add_child(down_button)

func _circle_style(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.corner_radius_top_left = 90
	s.corner_radius_top_right = 90
	s.corner_radius_bottom_left = 90
	s.corner_radius_bottom_right = 90
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.border_color = Color(1, 1, 1, 0.3)
	return s

func _slot_style(bg: Color, border_w: int, border_c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = border_w
	s.border_width_top = border_w
	s.border_width_right = border_w
	s.border_width_bottom = border_w
	s.border_color = border_c
	return s

func set_player(p: Node) -> void:
	player = p
	refresh_hotbar()
	player.health_changed.connect(_on_health_changed)
	player.hunger_changed.connect(_on_hunger_changed)
	player.hotbar_changed.connect(_on_hotbar_changed)

func _on_health_changed(v: float) -> void:
	health_bar.value = v
	health_bar.modulate = Color(1, 0.3, 0.3, 0.85) if v < 6 else Color(1, 0.4, 0.4, 0.85)

func _on_hunger_changed(v: float) -> void:
	hunger_bar.value = v

func _on_hotbar_changed(_idx: int) -> void:
	refresh_hotbar()

func refresh_hotbar() -> void:
	if player == null: return
	for i in range(HOTBAR_SLOT_COUNT):
		var slot: Panel = hotbar_slots[i]
		var icon: ColorRect = slot.get_node("Icon")
		var count: Label = slot.get_node("Count")
		var item = player.get_hotbar_item(i)
		if item == null:
			icon.color = Color(0, 0, 0, 0)
			count.text = ""
		else:
			icon.color = _color_for_item(item.id)
			count.text = str(item.count) if item.count > 1 else ""
		# Highlight selected
		if i == player.hotbar_index:
			slot.add_theme_stylebox_override("panel", _slot_style(Color(1, 1, 1, 0.25), 3, Color(1, 1, 0, 1)))
		else:
			slot.add_theme_stylebox_override("panel", _slot_style(Color(0, 0, 0, 0.55), 2, Color(1, 1, 1, 0.4)))

func _color_for_item(id: int) -> Color:
	# Simple color hash for icon — gives a quick visual cue
	const B = preload("res://scripts/blocks/BlockRegistry.gd")
	var def := B.get_def(id)
	if def.size() > 0:
		match id:
			B.GRASS: return Color(0.5, 0.7, 0.3)
			B.DIRT: return Color(0.45, 0.3, 0.2)
			B.STONE: return Color(0.55, 0.55, 0.55)
			B.COBBLESTONE: return Color(0.45, 0.45, 0.45)
			B.SAND: return Color(0.85, 0.78, 0.5)
			B.WATER: return Color(0.2, 0.4, 0.9)
			B.LAVA: return Color(0.9, 0.4, 0.1)
			B.OAK_LOG: return Color(0.4, 0.3, 0.15)
			B.OAK_PLANKS: return Color(0.7, 0.55, 0.3)
			B.TORCH: return Color(1.0, 0.85, 0.3)
			B.GLASS: return Color(0.7, 0.85, 0.95, 0.6)
			B.CRAFTING_TABLE: return Color(0.6, 0.45, 0.25)
			B.FURNACE: return Color(0.35, 0.35, 0.35)
			B.BEDROCK: return Color(0.15, 0.15, 0.15)
			B.GEM_ORE: return Color(0.3, 0.95, 0.85)
			B.COAL_ORE: return Color(0.15, 0.15, 0.15)
			_: return Color(0.7, 0.7, 0.7)
	# Items — derive from name hash
	var name := ItemRegistry.get_item_name(id)
	return Color.from_hsv(abs(name.hash()) % 100 / 100.0, 0.5, 0.7)

func _on_jump_down() -> void:
	if player: player.jump_held = true

func _on_jump_up() -> void:
	if player: player.jump_held = false

func _on_inventory_pressed() -> void:
	# Open inventory overlay
	var inv := get_tree().current_scene.get_node_or_null("InventoryUI")
	if inv == null:
		return
	inv.toggle()

func _on_hotbar_slot_input(event: InputEvent, idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if player: player.select_hotbar(idx)

# Handle all touch input here so we can route correctly
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Check joystick base first
		if joystick_touch_idx == -1 and _is_in_joystick(event.position):
			joystick_touch_idx = event.index
			joystick_active = true
			joystick_origin = event.position
			_joystick_update(event.position)
			get_viewport().set_input_as_handled()
			return
		# Check if touch is on right half (look area) — also starts an action
		if look_touch_idx == -1 and _is_in_look_area(event.position):
			look_touch_idx = event.index
			look_last_pos = event.position
			# Start mining / action
			if action_touch_idx == -1:
				action_touch_idx = event.index
				action_pos = event.position
				action_held_time = 0.0
				action_is_mining = true
				action_swiped = false
				if player: player.try_attack()
			get_viewport().set_input_as_handled()
			return
	else:
		if event.index == joystick_touch_idx:
			joystick_touch_idx = -1
			joystick_active = false
			joystick_value = Vector2.ZERO
			if player: player.move_vector = Vector2.ZERO
			_joystick_update(joystick_base.position + joystick_base.size * 0.5)
			get_viewport().set_input_as_handled()
		elif event.index == look_touch_idx:
			look_touch_idx = -1
			# Release action
			if event.index == action_touch_idx:
				action_touch_idx = -1
				action_is_mining = false
				if player and not action_swiped:
					# Was a tap — if holding a placeable block, place it
					player.try_place_block()
				if player: player.release_attack()
			get_viewport().set_input_as_handled()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == joystick_touch_idx:
		_joystick_update(event.position)
		get_viewport().set_input_as_handled()
	elif event.index == look_touch_idx:
		var delta := event.position - look_last_pos
		look_last_pos = event.position
		if player:
			var sens := Settings.look_sensitivity * 0.25
			player.look_around(delta.y * sens, delta.x * sens)
		# Detect swipe (cancels mining & makes it a place)
		if action_touch_idx == event.index and delta.length() > 20:
			action_swiped = true
			if player: player.release_attack()
		get_viewport().set_input_as_handled()

func _is_in_joystick(pos: Vector2) -> bool:
	var center := joystick_base.position + joystick_base.size * 0.5
	return pos.distance_to(center) <= joystick_base.size.x * 0.5 + 30

func _is_in_look_area(pos: Vector2) -> bool:
	var vr := get_viewport().get_visible_rect().size
	return pos.x > vr.x * 0.45

func _joystick_update(touch_pos: Vector2) -> void:
	var center := joystick_base.position + joystick_base.size * 0.5
	var offset := touch_pos - center
	var max_r := joystick_base.size.x * 0.5
	if offset.length() > max_r:
		offset = offset.normalized() * max_r
	joystick_knob.position = Vector2(90, 90) + offset - Vector2(40, 40)
	var v := offset / max_r
	joystick_value = v
	if player:
		player.move_vector = Vector2(v.x, -v.y) # y flipped: forward = -y joystick

func _process(delta: float) -> void:
	if action_touch_idx != -1 and action_is_mining:
		action_held_time += delta

func set_clock(text: String) -> void:
	clock_label.text = text

func set_crack_stage(stage: int) -> void:
	# stage 0 = no crack, 1..10 = crack progression
	if stage <= 0:
		crack_overlay.visible = false
		return
	crack_overlay.visible = true
	# Set modulate based on stage (10 = fully cracked)
	crack_overlay.modulate = Color(0, 0, 0, float(stage) / 10.0 * 0.6)
