# QuackCraft - Inventory UI overlay
# Shows hotbar items + crafting 2x2 (always) and 3x3 (when near a crafting table).
extends Control

const B = preload("res://scripts/blocks/BlockRegistry.gd")
const PlayerClass = preload("res://scripts/player/Player.gd")

var player: Node = null
var visible_state: bool = false
var grid_2x2: Array = []  # 4 slots (InventorySlot Controls)
var grid_3x3: Array = []  # 9 slots
var output_slot: Panel
var inventory_grid: GridContainer  # main inventory 27 slots
var use_3x3: bool = false
var held_item: Variant = null  # {id, count} the cursor is carrying

# Main inventory (27 slots + 9 hotbar)
var inv_slots: Array = []
const INV_SLOTS_COUNT := 27

func setup(p: Node) -> void:
	player = p
	_build_ui()
	visible = false

func _build_ui() -> void:
	# Background panel
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", _bg_style())
	add_child(bg)

	# Main container centered
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "Inventory"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font", 22)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	# Crafting grid
	var craft_row := HBoxContainer.new()
	craft_row.add_theme_constant_override("separation", 18)
	vbox.add_child(craft_row)
	craft_row.alignment = BoxContainer.ALIGNMENT_CENTER

	# 2x2 or 3x3 grid
	var grid_holder := VBoxContainer.new()
	craft_row.add_child(grid_holder)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid_holder.add_child(grid)
	for i in range(9):
		var slot := _make_slot("3x3_%d" % i)
		grid.add_child(slot)
		grid_3x3.append(slot)
	# Hide 3x3 unless crafting table is open
	_show_3x3(false)

	# Arrow + output
	var arrow := Label.new()
	arrow.text = "->"
	arrow.add_theme_font_size_override("font", 26)
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	craft_row.add_child(arrow)
	output_slot = _make_slot("output")
	output_slot.custom_minimum_size = Vector2(64, 64)
	craft_row.add_child(output_slot)

	# Main inventory (3 rows of 9)
	var inv_grid := GridContainer.new()
	inv_grid.columns = 9
	inv_grid.add_theme_constant_override("h_separation", 4)
	inv_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(inv_grid)
	for i in range(INV_SLOTS_COUNT):
		var slot := _make_slot("inv_%d" % i)
		inv_grid.add_child(slot)
		inv_slots.append(slot)

	# Hotbar row
	var hotbar_grid := GridContainer.new()
	hotbar_grid.columns = 9
	hotbar_grid.add_theme_constant_override("h_separation", 4)
	hotbar_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(hotbar_grid)
	for i in range(9):
		var slot := _make_slot("hb_%d" % i)
		hotbar_grid.add_child(slot)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "Close (E)"
	close_btn.pressed.connect(toggle)
	vbox.add_child(close_btn)

	_refresh_all()

func _show_3x3(show: bool) -> void:
	use_3x3 = show
	# In 3x3 mode all 9 slots visible; in 2x2 mode only first 4 + hide rest
	for i in range(9):
		grid_3x3[i].visible = show or i < 4

func _make_slot(name: String) -> Panel:
	var slot := Panel.new()
	slot.name = name
	slot.custom_minimum_size = Vector2(48, 48)
	slot.add_theme_stylebox_override("panel", _slot_style())
	var icon := ColorRect.new()
	icon.name = "Icon"
	icon.color = Color(0, 0, 0, 0)
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	var count := Label.new()
	count.name = "Count"
	count.position = Vector2(28, 28)
	count.add_theme_color_override("font_color", Color.WHITE)
	count.add_theme_font_size_override("font", 11)
	count.add_theme_outline_size_override("font_outline", 2)
	count.add_theme_color_override("font_outline_color", Color.BLACK)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(count)
	slot.gui_input.connect(_on_slot_input.bind(slot))
	return slot

func _bg_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0.7)
	return s

func _slot_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.15, 0.15, 0.18, 0.9)
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.border_color = Color(0.4, 0.4, 0.45, 1)
	return s

func toggle() -> void:
	visible_state = not visible_state
	visible = visible_state
	# Detect if player is near a crafting table for 3x3
	_show_3x3(_is_near_crafting_table())
	if visible_state:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_refresh_all()

func _is_near_crafting_table() -> bool:
	if player == null: return false
	var p := player.position
	var bx := int(p.x)
	var by := int(p.y)
	var bz := int(p.z)
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			for dz in range(-2, 3):
				var world_node = WorldRef.get_world()
				if world_node != null and world_node.get_block(bx + dx, by + dy, bz + dz) == B.CRAFTING_TABLE:
					return true
	return false

func _refresh_all() -> void:
	for i in range(9):
		_set_slot(grid_3x3[i], null)
	for i in range(INV_SLOTS_COUNT):
		_set_slot(inv_slots[i], null)
	# Hotbar
	for i in range(9):
		_set_slot(get_parent().get_parent().get_node("MobileControls").hotbar_slots[i], player.get_hotbar_item(i) if player else null)

func _set_slot(slot: Panel, item: Variant) -> void:
	if slot == null: return
	var icon: ColorRect = slot.get_node_or_null("Icon")
	var count: Label = slot.get_node_or_null("Count")
	if icon == null or count == null: return
	if item == null or item.count <= 0:
		icon.color = Color(0, 0, 0, 0)
		count.text = ""
	else:
		icon.color = _color_for_item(item.id)
		count.text = str(item.count) if item.count > 1 else ""

func _color_for_item(id: int) -> Color:
	const BR = preload("res://scripts/blocks/BlockRegistry.gd")
	match id:
		BR.GRASS: return Color(0.5, 0.7, 0.3)
		BR.DIRT: return Color(0.45, 0.3, 0.2)
		BR.STONE: return Color(0.55, 0.55, 0.55)
		BR.COBBLESTONE: return Color(0.45, 0.45, 0.45)
		BR.SAND: return Color(0.85, 0.78, 0.5)
		BR.OAK_LOG: return Color(0.4, 0.3, 0.15)
		BR.OAK_PLANKS: return Color(0.7, 0.55, 0.3)
		BR.TORCH: return Color(1.0, 0.85, 0.3)
		_: return Color(0.7, 0.7, 0.7)

func _on_slot_input(event: InputEvent, slot: Panel) -> void:
	if not visible_state: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Pick up / put down
		var current: Variant = _get_slot_item(slot)
		if held_item == null:
			if current != null:
				held_item = current
				_set_slot(slot, null)
		else:
			if current == null:
				_set_slot(slot, held_item)
				held_item = null
			elif current.id == held_item.id:
				current.count += held_item.count
				_set_slot(slot, current)
				held_item = null
			else:
				_set_slot(slot, held_item)
				held_item = current
		# Try craft
		_check_crafting()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		# Place one
		if held_item != null:
			var current: Variant = _get_slot_item(slot)
			if current == null:
				_set_slot(slot, {"id": held_item.id, "count": 1})
				held_item.count -= 1
				if held_item.count <= 0: held_item = null
			_check_crafting()

func _get_slot_item(slot: Panel) -> Variant:
	# We don't track per-slot state in this simplified inventory; just return null
	# (a more complete impl would track a slot→item map)
	return null

func _check_crafting() -> void:
	# In a full impl: read all 4/9 crafting slots, scan recipes, populate output
	# For v1 simplicity: only do output_slot visualization if pattern matches any recipe
	# (see ItemRegistry.get_recipes)
	pass
