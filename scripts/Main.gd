# QuackCraft - Main game scene controller
# Manages world creation, player spawning, day/night cycle, mob spawning.
extends Node3D

const WorldClass = preload("res://scripts/world/World.gd")
const PlayerClass = preload("res://scripts/player/Player.gd")
const MobileControlsClass = preload("res://scripts/player/MobileControls.gd")
const MobManagerClass = preload("res://scripts/mobs/MobManager.gd")
const DayNightClass = preload("res://scripts/world/DayNight.gd")
const HUDClass = preload("res://scripts/ui/HUD.gd")

var world: Node3D
var player: Node3D
var mobile_controls: CanvasLayer
var mob_manager: Node
var day_night: Node
var hud: CanvasLayer

func _ready() -> void:
	# Create world
	world = WorldClass.new()
	world.name = "World"
	world.seed_val = Settings.world_seed
	world.render_distance = Settings.render_distance
	add_child(world)
	WorldRef.set_world(world)

	# Force-load spawn chunk before placing player
	var spawn := world.find_spawn()
	# Pre-generate the spawn chunk
	var pcx := int(spawn.x) / world.CHUNK_X
	var pcz := int(spawn.z) / world.CHUNK_Z
	world._ensure_chunk(pcx, pcz)
	# Pre-load a small ring of chunks around spawn
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			world._ensure_chunk(pcx + dx, pcz + dz)

	# Create player
	player = PlayerClass.new()
	player.name = "Player"
	player.position = spawn
	world.add_child(player)
	world.set_player(player)
	player.set_world(world)
	WorldRef.set_player(player)

	# Day/night
	day_night = DayNightClass.new()
	day_night.name = "DayNight"
	add_child(day_night)
	day_night.setup(world, player)

	# Mob manager
	mob_manager = MobManagerClass.new()
	mob_manager.name = "MobManager"
	add_child(mob_manager)
	mob_manager.setup(world, player)

	# HUD
	hud = HUDClass.new()
	hud.name = "HUD"
	add_child(hud)
	hud.setup(player, day_night, world)

	# Mobile controls overlay
	mobile_controls = MobileControlsClass.new()
	mobile_controls.name = "MobileControls"
	add_child(mobile_controls)
	mobile_controls.set_player(player)

	# Hook day/night to mobile_controls clock
	day_night.time_changed.connect(_on_time_changed)

func _on_time_changed(day: int, hour: int, minute: int) -> void:
	mobile_controls.set_clock("Day %d — %02d:%02d" % [day, hour, minute])

func _process(_delta: float) -> void:
	# Process hotbar selection via keyboard
	if Input.is_action_just_pressed("hotbar_1"): player.select_hotbar(0)
	if Input.is_action_just_pressed("hotbar_2"): player.select_hotbar(1)
	if Input.is_action_just_pressed("hotbar_3"): player.select_hotbar(2)
	if Input.is_action_just_pressed("hotbar_4"): player.select_hotbar(3)
	if Input.is_action_just_pressed("hotbar_5"): player.select_hotbar(4)
	if Input.is_action_just_pressed("hotbar_6"): player.select_hotbar(5)
	if Input.is_action_just_pressed("hotbar_7"): player.select_hotbar(6)
	if Input.is_action_just_pressed("hotbar_8"): player.select_hotbar(7)
	if Input.is_action_just_pressed("hotbar_9"): player.select_hotbar(8)
	if Input.is_action_just_pressed("inventory"):
		var inv = hud.get_node_or_null("InventoryUI")
		if inv != null:
			inv.toggle()
	# Desktop mouse look (right-click to look, left-click to mine/place)
	# These are emulated as touch — but Godot 4 emulates mouse as touch via setting
