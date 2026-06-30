# QuackCraft - Procedural terrain generator
# Multithreaded; operates on a chunk-sized voxel buffer at a time.
extends RefCounted

const B = preload("res://scripts/blocks/BlockRegistry.gd")

const CHUNK_X := 16
const CHUNK_Y := 128
const CHUNK_Z := 16
const SEA_LEVEL := 48

# Biome constants
enum Biome { PLAINS=0, FOREST=1, DESERT=2, SNOWY=3, MUSHROOM=4 }

# Noise seeds (configured per-world)
var _seed: int = 1337
var _noise_height: FastNoiseLite
var _noise_moisture: FastNoiseLite
var _noise_temp: FastNoiseLite
var _noise_cave: FastNoiseLite
var _noise_ore: FastNoiseLite

func _init(seed_val: int = 1337) -> void:
	_seed = seed_val
	_noise_height = FastNoiseLite.new()
	_noise_height.seed = _seed
	_noise_height.frequency = 0.005
	_noise_height.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise_height.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise_height.fractal_octaves = 4

	_noise_moisture = FastNoiseLite.new()
	_noise_moisture.seed = _seed + 1
	_noise_moisture.frequency = 0.003
	_noise_moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX

	_noise_temp = FastNoiseLite.new()
	_noise_temp.seed = _seed + 2
	_noise_temp.frequency = 0.002
	_noise_temp.noise_type = FastNoiseLite.TYPE_SIMPLEX

	_noise_cave = FastNoiseLite.new()
	_noise_cave.seed = _seed + 3
	_noise_cave.frequency = 0.015
	_noise_cave.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise_cave.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise_cave.fractal_octaves = 3

	_noise_ore = FastNoiseLite.new()
	_noise_ore.seed = _seed + 4
	_noise_ore.frequency = 0.08
	_noise_ore.noise_type = FastNoiseLite.TYPE_CELLULAR

# Returns biome id at world XZ
func get_biome(wx: int, wz: int) -> int:
	var t := _noise_temp.get_noise_2d(wx, wz) # -1..1
	var m := _noise_moisture.get_noise_2d(wx, wz) # -1..1
	# Temperature bands
	if t < -0.4:
		return Biome.SNOWY
	if t > 0.35 and m < -0.1:
		return Biome.DESERT
	if m > 0.35 and t < -0.05:
		return Biome.MUSHROOM
	if m > 0.0:
		return Biome.FOREST
	return Biome.PLAINS

# Returns surface height (top solid block Y) at world XZ
func get_height(wx: int, wz: int) -> int:
	var base := _noise_height.get_noise_2d(wx, wz) # -1..1
	var h := int(SEA_LEVEL + 8 + base * 18.0)
	return clamp(h, 8, CHUNK_Y - 8)

# Generate a chunk's voxel data. cx, cz are chunk coordinates.
# Returns a PackedByteArray of size CHUNK_X*CHUNK_Y*CHUNK_Z
func generate_chunk(cx: int, cz: int) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(CHUNK_X * CHUNK_Y * CHUNK_Z)
	data.fill(0) # AIR

	var base_x := cx * CHUNK_X
	var base_z := cz * CHUNK_Z

	for lx in range(CHUNK_X):
		for lz in range(CHUNK_Z):
			var wx := base_x + lx
			var wz := base_z + lz
			var biome := get_biome(wx, wz)
			var h := get_height(wx, wz)
			# Bedrock floor
			set_voxel(data, lx, 0, lz, B.BEDROCK)
			# Stone layer down to h-4
			for y in range(1, h - 4):
				# Carve caves
				if _is_cave(wx, y, wz):
					continue
				# Maybe place ore
				var ore := _get_ore_at(wx, y, wz)
				if ore != B.AIR:
					set_voxel(data, lx, y, lz, ore)
				else:
					set_voxel(data, lx, y, lz, B.STONE)
			# Sub-surface layers (dirt/sand/etc.)
			for y in range(max(1, h - 4), h):
				match biome:
					Biome.DESERT:
						set_voxel(data, lx, y, lz, B.SAND)
					Biome.SNOWY:
						set_voxel(data, lx, y, lz, B.DIRT)
					_:
						set_voxel(data, lx, y, lz, B.DIRT)
			# Surface block
			match biome:
				Biome.DESERT:
					set_voxel(data, lx, h, lz, B.SAND)
					# Sandstone under top sand
					if h - 1 >= 0:
						set_voxel(data, lx, h - 1, lz, B.SANDSTONE)
				Biome.SNOWY:
					set_voxel(data, lx, h, lz, B.SNOW)
					set_voxel(data, lx, h - 1, lz, B.DIRT)
				Biome.MUSHROOM:
					set_voxel(data, lx, h, lz, B.MYCEL)
				_:
					set_voxel(data, lx, h, lz, B.GRASS)
			# Water fill up to sea level
			for y in range(h + 1, SEA_LEVEL + 1):
				if get_voxel(data, lx, y, lz) == B.AIR:
					set_voxel(data, lx, y, lz, B.WATER)
			# Surface decoration: trees, flowers, grass, cacti
			if h >= SEA_LEVEL and get_voxel(data, lx, h, lz) != B.WATER:
				_decoration(data, lx, h, lz, wx, wz, biome)

	return data

func _is_cave(wx: int, y: int, wz: int) -> bool:
	if y < 4 or y > 70:
		return false
	var n := _noise_cave.get_noise_3d(wx, y * 1.2, wz)
	# Carve where noise > threshold (creates 3D tunnels)
	return n > 0.55

func _get_ore_at(wx: int, y: int, wz: int) -> int:
	# Depth-based ore distribution
	if y < 1: return B.AIR
	var n := _noise_ore.get_noise_3d(wx, y, wz)
	# Higher noise threshold = rarer
	if y < 16 and n > 0.85:
		return B.GEM_ORE
	if y < 24 and n > 0.82:
		return B.GOLD_ORE
	if y < 32 and n > 0.78:
		return B.LAPIS_ORE
	if y < 40 and n > 0.75:
		return B.EMERALD_ORE
	if y < 48 and n > 0.72:
		return B.SPARK_ORE
	if y < 56 and n > 0.68:
		return B.IRON_ORE
	if y < 64 and n > 0.6:
		return B.COAL_ORE
	return B.AIR

func _decoration(data: PackedByteArray, lx: int, h: int, lz: int, wx: int, wz: int, biome: int) -> void:
	# Use a deterministic hash from wx,wz for placement
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(wx, wz)) & 0x7FFFFFFF
	var r := rng.randf()
	# Trees in forest/plains
	if biome == Biome.FOREST and r < 0.06:
		_place_tree(data, lx, h, lz, B.OAK_LOG, B.OAK_LEAVES, rng)
	elif biome == Biome.FOREST and r < 0.09:
		_place_tree(data, lx, h, lz, B.BIRCH_LOG, B.BIRCH_LEAVES, rng)
	elif biome == Biome.PLAINS and r < 0.02:
		_place_tree(data, lx, h, lz, B.OAK_LOG, B.OAK_LEAVES, rng)
	elif biome == Biome.SNOWY and r < 0.03:
		_place_tree(data, lx, h, lz, B.SPRUCE_LOG, B.SPRUCE_LEAVES, rng)
	elif biome == Biome.DESERT and r < 0.04:
		# Cactus
		var ch := rng.randi_range(1, 3)
		for i in range(ch):
			if is_in_bounds(lx, h + 1 + i, lz):
				set_voxel(data, lx, h + 1 + i, lz, B.CACTUS)
	elif biome == Biome.DESERT and r < 0.06:
		# Reed
		if is_in_bounds(lx, h + 1, lz):
			set_voxel(data, lx, h + 1, lz, B.REED)
			if is_in_bounds(lx, h + 2, lz):
				set_voxel(data, lx, h + 2, lz, B.REED)
	elif r < 0.12:
		# Tall grass / flowers
		var pick := rng.randf()
		var block := B.TALL_GRASS
		if biome == Biome.SNOWY:
			return
		if pick < 0.4:
			block = B.TALL_GRASS
		elif pick < 0.55:
			block = B.FLOWER_RED
		elif pick < 0.7:
			block = B.FLOWER_YELLOW
		elif pick < 0.8:
			block = B.FLOWER_WHITE
		elif pick < 0.88:
			block = B.FLOWER_PURPLE
		elif pick < 0.94:
			block = B.FLOWER_PINK
		else:
			block = B.FLOWER_BLUE
		if is_in_bounds(lx, h + 1, lz):
			set_voxel(data, lx, h + 1, lz, block)
	elif biome == Biome.MUSHROOM and r < 0.15:
		var pick := rng.randf()
		var block: int = B.MUSHROOM_RED if pick < 0.5 else B.MUSHROOM_BROWN
		if is_in_bounds(lx, h + 1, lz):
			set_voxel(data, lx, h + 1, lz, block)

func _place_tree(data: PackedByteArray, lx: int, h: int, lz: int, log: int, leaves: int, rng: RandomNumberGenerator) -> void:
	var th := rng.randi_range(4, 6)
	# Leaves: a small blob around the top
	var top := h + th
	for y in range(top - 2, top + 2):
		var radius: int = 2 if y < top else 1
		for dx in range(-radius, radius + 1):
			for dz in range(-radius, radius + 1):
				if dx == 0 and dz == 0 and y < top:
					continue
				if abs(dx) == radius and abs(dz) == radius and rng.randf() < 0.5:
					continue
				var nx := lx + dx
				var nz := lz + dz
				var ny := y
				if is_in_bounds(nx, ny, nz) and get_voxel(data, nx, ny, nz) == B.AIR:
					set_voxel(data, nx, ny, nz, leaves)
	# Trunk
	for y in range(1, th + 1):
		if is_in_bounds(lx, h + y, lz):
			set_voxel(data, lx, h + y, lz, log)

# Helpers for in-place array access (CHUNK_X * CHUNK_Y * CHUNK_Z)
static func idx(x: int, y: int, z: int) -> int:
	return x + CHUNK_X * (z + CHUNK_Z * y)

static func is_in_bounds(x: int, y: int, z: int) -> bool:
	return x >= 0 and x < CHUNK_X and y >= 0 and y < CHUNK_Y and z >= 0 and z < CHUNK_Z

static func get_voxel(data: PackedByteArray, x: int, y: int, z: int) -> int:
	if not is_in_bounds(x, y, z): return 0
	return data[idx(x, y, z)]

static func set_voxel(data: PackedByteArray, x: int, y: int, z: int, v: int) -> void:
	if not is_in_bounds(x, y, z): return
	data[idx(x, y, z)] = v
