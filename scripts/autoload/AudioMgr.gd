# QuackCraft - Audio manager (autoload)
# Loads and plays all SFX; falls back silently if a sound is missing.
extends Node

var _sounds: Dictionary = {} # name -> AudioStream
var _pool: Array[AudioStreamPlayer] = []
var _pool_idx: int = 0
const POOL_SIZE := 8
var _master_muted: bool = false

func _ready() -> void:
	for i in range(POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)
	_preload_sounds()

func _preload_sounds() -> void:
	# Try to load each .wav from res://assets/sounds/
	var dir: DirAccess = DirAccess.open("res://assets/sounds")
	if dir == null:
		return
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if name.ends_with(".wav") or name.ends_with(".ogg"):
			var key: String = name.get_basename()
			var stream: Resource = load("res://assets/sounds/%s" % name)
			if stream != null:
				_sounds[key] = stream
		name = dir.get_next()
	dir.list_dir_end()

func play(name: String, volume: float = 0.0, pitch: float = 1.0) -> void:
	if _master_muted: return
	if not _sounds.has(name):
		return
	var p: AudioStreamPlayer = _pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE
	p.stream = _sounds[name]
	p.volume_db = volume
	p.pitch_scale = pitch
	p.play()

func play_footstep(block_id: int) -> void:
	var name := "footstep_dirt"
	const B = preload("res://scripts/blocks/BlockRegistry.gd")
	match block_id:
		B.STONE, B.COBBLESTONE, B.STONE_BRICKS, B.BRICKS:
			name = "footstep_stone"
		B.SAND, B.SANDSTONE, B.GRAVEL:
			name = "footstep_sand"
		B.SNOW, B.ICE, B.SNOW_LAYER:
			name = "footstep_snow"
		B.GRASS, B.DIRT, B.MYCEL:
			name = "footstep_dirt"
		B.OAK_PLANKS, B.OAK_LOG, B.BIRCH_PLANKS, B.SPRUCE_PLANKS, B.JUNGLE_PLANKS, B.ACACIA_PLANKS, B.DARK_OAK_PLANKS:
			name = "footstep_wood"
		_:
			name = "footstep_dirt"
	play(name, -10.0, randf_range(0.9, 1.1))

func set_muted(m: bool) -> void:
	_master_muted = m
	var master: int = AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, m)
