# QuackCraft - Player controller (first-person, mobile-first)
extends CharacterBody3D

const B = preload("res://scripts/blocks/BlockRegistry.gd")

signal health_changed(v: float)
signal hunger_changed(v: float)
signal hotbar_changed(idx: int)
signal died

# Movement
@export var walk_speed: float = 4.5
@export var sprint_speed: float = 6.5
@export var jump_velocity: float = 9.0
@export var gravity: float = 29.4
@export var eye_height: float = 1.65
@export var body_height: float = 1.8
@export var reach: float = 5.5

# Stats
var max_health: float = 20.0
var health: float = 20.0:
	set(v): health = clamp(v, 0, max_health); health_changed.emit(health)
var max_hunger: float = 20.0
var hunger: float = 20.0:
	set(v): hunger = clamp(v, 0, max_hunger); hunger_changed.emit(hunger)

# Camera control
var camera: Camera3D
var head: Node3D
var pitch: float = 0.0
var yaw: float = 0.0
var mouse_look: bool = false

# Mobile input state
var move_vector: Vector2 = Vector2.ZERO  # x=strafe, y=forward
var jump_held: bool = false
var look_delta: Vector2 = Vector2.ZERO  # accumulated look delta from right-side drag

# Block interaction
var targeted_block: Dictionary = {} # raycast result
var mining_block: Vector3i = Vector3i.ZERO
var mining_progress: float = 0.0
var mining: bool = false
var place_cooldown: float = 0.0

# Hotbar
var hotbar: Array = []  # 9 slots, each {id: int, count: int} or null
var hotbar_index: int = 0

# Damage / hit feedback
var hurt_timer: float = 0.0
var knockback: Vector3 = Vector3.ZERO

# Sound
var footstep_timer: float = 0.0

# World reference (set externally)
var world: Node = null

# Block break particles scene
var particles_scene: PackedScene = null

func _ready() -> void:
	# Add to player collision layer
	collision_layer = 2
	collision_mask = 1 # world

	# Build camera/head hierarchy
	head = Node3D.new()
	head.position = Vector3(0, eye_height, 0)
	add_child(head)
	camera = Camera3D.new()
	camera.fov = 70.0
	camera.near = 0.05
	camera.far = 200.0
	camera.current = true
	head.add_child(camera)

	# Initialize hotbar (start with some blocks)
	hotbar.resize(9)
	hotbar[0] = {"id": B.GRASS, "count": 64}
	hotbar[1] = {"id": B.DIRT, "count": 64}
	hotbar[2] = {"id": B.STONE, "count": 64}
	hotbar[3] = {"id": B.OAK_LOG, "count": 32}
	hotbar[4] = {"id": B.OAK_PLANKS, "count": 32}
	hotbar[5] = {"id": B.TORCH, "count": 16}
	hotbar[6] = {"id": B.GLASS, "count": 32}
	hotbar[7] = {"id": B.CRAFTING_TABLE, "count": 4}
	hotbar[8] = {"id": B.FURNACE, "count": 4}

	# Initialize look direction
	pitch = -10.0
	yaw = 0.0
	_apply_look()

func set_world(w: Node) -> void:
	world = w

func _physics_process(delta: float) -> void:
	if world == null:
		return
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	# Movement
	var speed := walk_speed
	if Input.is_action_pressed("sprint") or _is_sprinting_mobile():
		speed = sprint_speed
	var forward := Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw)))
	var right := Vector3(forward.z, 0, -forward.x)
	# Combine keyboard + mobile joystick
	var input_vec := Vector2.ZERO
	input_vec.y += Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	input_vec.x += Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vec += move_vector
	input_vec = input_vec.clampf(-1.0, 1.0)
	var move_dir := forward * input_vec.y + right * input_vec.x
	move_dir = move_dir.normalized() * min(move_dir.length(), 1.0)
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	# Jump
	if (Input.is_action_pressed("jump") or jump_held) and is_on_floor():
		velocity.y = jump_velocity
	# Knockback
	if knockback.length() > 0.1:
		velocity += knockback
		knockback = knockback.move_toward(Vector3.ZERO, 8.0 * delta)
	# Apply look
	_apply_look()
	# Move
	move_and_slide()
	# Footstep audio
	if is_on_floor() and velocity.length() > 0.5:
		footstep_timer -= delta
		if footstep_timer <= 0:
			footstep_timer = 0.35
			_play_footstep()
	# Mining logic
	_update_mining(delta)
	place_cooldown = max(0, place_cooldown - delta)
	# Hunger
	hunger -= delta * 0.05
	if hunger <= 0:
		health -= delta * 0.5
	elif hunger >= 18 and health < max_health:
		health += delta * 0.5
	# Drowning
	var head_block := world.get_block(int(position.x), int(position.y + eye_height), int(position.z))
	if head_block == B.WATER:
		health -= delta * 1.0
	# Lava
	var foot_block := world.get_block(int(position.x), int(position.y), int(position.z))
	if foot_block == B.LAVA:
		health -= delta * 4.0
		velocity.y = 4.0 # bounce out
	# Hurt flash decay
	if hurt_timer > 0:
		hurt_timer -= delta
	# Death
	if health <= 0:
		_die()

func _is_sprinting_mobile() -> bool:
	# Double-tap joystick triggers sprint (handled by MobileControls)
	return false

func _apply_look() -> void:
	rotation.y = deg_to_rad(yaw)
	head.rotation.x = deg_to_rad(pitch)

func look_around(delta_pitch: float, delta_yaw: float) -> void:
	pitch = clamp(pitch - delta_pitch, -89, 89)
	yaw = wrapf(yaw - delta_yaw, -180, 180)

func _process(_delta: float) -> void:
	# Update targeted block via raycast from camera center
	if camera != null and world != null:
		var origin := camera.global_position
		var dir := -camera.global_transform.basis.z.normalized()
		var hit := world.raycast(origin, dir, reach)
		targeted_block = hit

func _update_mining(delta: float) -> void:
	if mining and not targeted_block.get("hit", false):
		mining = false
		mining_progress = 0
		return
	if not mining:
		return
	if not targeted_block.get("hit", false):
		mining = false
		return
	var pos: Vector3i = targeted_block.pos
	if pos != mining_block:
		mining_block = pos
		mining_progress = 0
	var id: int = targeted_block.block
	if id == B.AIR or id == B.BEDROCK:
		mining = false
		return
	var hardness: float = B.get_hardness(id)
	# Determine mining speed based on tool (current hotbar item)
	var speed_mult := 1.0
	if hotbar[hotbar_index] != null:
		speed_mult = _tool_mining_speed(hotbar[hotbar_index].id, id)
	mining_progress += delta * speed_mult / hardness
	if mining_progress >= 1.0:
		# Block broken
		world.set_block(pos.x, pos.y, pos.z, B.AIR)
		# Add to inventory
		_give_drop(id)
		_play_sound("dig")
		mining_progress = 0
		mining = false

func _tool_mining_speed(item_id: int, block_id: int) -> float:
	# If item is a tool and block requires it, multiply speed based on tier
	var req := B.get_required_tool(block_id)
	# Check ItemRegistry for tool type/tier of item_id
	var item := ItemRegistry.get_item(item_id)
	if item == null or not item.has("tool_type"):
		return 1.0 if req.type == B.ToolType.NONE else 0.3
	var tool_type: int = item.get("tool_type", B.ToolType.NONE)
	var tool_tier: int = item.get("tool_tier", B.ToolTier.HAND)
	if tool_type != req.type:
		return 1.0 if req.type == B.ToolType.NONE else 0.3
	# Required tier check — can't mine if tier too low
	if tool_tier < req.tier:
		return 0.1 # barely scratches it
	match tool_tier:
		B.ToolTier.HAND: return 1.0
		B.ToolTier.WOOD: return 2.0
		B.ToolTier.STONE: return 4.0
		B.ToolTier.IRON: return 6.0
		B.ToolTier.GOLD: return 8.0
		B.ToolTier.GEM: return 12.0
	return 1.0

func _give_drop(block_id: int) -> void:
	# In v1, the block drops itself (with a few exceptions handled in ItemRegistry)
	var drop_id: int = ItemRegistry.get_block_drop(block_id)
	if drop_id == B.AIR:
		return
	_add_to_inventory(drop_id, 1)

func _add_to_inventory(item_id: int, count: int) -> void:
	# Try to stack into hotbar first
	for i in range(hotbar.size()):
		if hotbar[i] != null and hotbar[i].id == item_id:
			hotbar[i].count += count
			return
	# Find empty slot
	for i in range(hotbar.size()):
		if hotbar[i] == null:
			hotbar[i] = {"id": item_id, "count": count}
			return
	# Hotbar full — drop would go on ground (v1: just discard)

func try_place_block() -> bool:
	if place_cooldown > 0:
		return false
	if not targeted_block.get("hit", false):
		return false
	if hotbar[hotbar_index] == null:
		return false
	var id: int = hotbar[hotbar_index].id
	if not B.is_solid(id) and B.get_render(id) == "none":
		return false
	# Place adjacent to hit face
	var pos: Vector3i = targeted_block.pos + targeted_block.normal
	# Don't place inside player's body
	var player_pos := Vector3(position)
	var block_pos := Vector3(pos.x + 0.5, pos.y + 0.5, pos.z + 0.5)
	if block_pos.distance_to(player_pos) < 1.0:
		return false
	world.set_block(pos.x, pos.y, pos.z, id)
	hotbar[hotbar_index].count -= 1
	if hotbar[hotbar_index].count <= 0:
		hotbar[hotbar_index] = null
	place_cooldown = 0.2
	_play_sound("place")
	return true

func try_attack() -> void:
	# If targeting a mob, attack it (mob system handles this via signal)
	# Otherwise, swing and apply melee to mob in front
	if not targeted_block.get("hit", false):
		# Maybe mob is between player and block? Just swing.
		pass
	# Mine the targeted block
	mining = true
	if targeted_block.get("hit", false):
		mining_block = targeted_block.pos

func release_attack() -> void:
	mining = false
	mining_progress = 0

func take_damage(amount: float, from_dir: Vector3 = Vector3.ZERO) -> void:
	health -= amount
	hurt_timer = 0.3
	if from_dir.length() > 0.1:
		knockback = from_dir.normalized() * 6.0
	_play_sound("hurt")

func _die() -> void:
	died.emit()
	# Respawn at world spawn
	var spawn: Vector3 = world.find_spawn()
	position = spawn
	velocity = Vector3.ZERO
	health = max_health
	hunger = max_hunger

func select_hotbar(idx: int) -> void:
	if idx < 0 or idx >= hotbar.size():
		return
	hotbar_index = idx
	hotbar_changed.emit(idx)

func scroll_hotbar(dir: int) -> void:
	var idx := (hotbar_index + dir) % hotbar.size()
	if idx < 0: idx += hotbar.size()
	select_hotbar(idx)

func get_mining_progress() -> float:
	return mining_progress

func get_targeted_block() -> Dictionary:
	return targeted_block

func get_hotbar() -> Array:
	return hotbar

func get_hotbar_item(idx: int) -> Variant:
	if idx < 0 or idx >= hotbar.size(): return null
	return hotbar[idx]

func _play_footstep() -> void:
	# Pick sound based on surface block under player
	var bx := int(position.x)
	var bz := int(position.z)
	var by := int(position.y - 0.1)
	var block := world.get_block(bx, by, bz)
	AudioMgr.play_footstep(block)

func _play_sound(name: String) -> void:
	AudioMgr.play(name)
