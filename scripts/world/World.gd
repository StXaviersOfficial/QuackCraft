# QuackCraft - World manager
# Owns all chunks, handles streaming around the player, chunk generation
# & meshing, save/load, and block I/O.
extends Node3D

const B = preload("res://scripts/blocks/BlockRegistry.gd")
const TG = preload("res://scripts/world/TerrainGen.gd")
const ChunkClass = preload("res://scripts/world/Chunk.gd")
const ChunkMesher = preload("res://scripts/world/ChunkMesher.gd")

const CHUNK_X: int = TG.CHUNK_X
const CHUNK_Y: int = TG.CHUNK_Y
const CHUNK_Z: int = TG.CHUNK_Z

@export var render_distance: int = 5
@export var seed_val: int = 1337
@export var fog_distance: float = 60.0

var terrain: TG
var chunks: Dictionary = {} # Vector2i -> Chunk
var chunks_to_mesh: Array = [] # queued for re-meshing

# Player reference (for streaming position)
var player: Node3D = null
# Cached player chunk position
var last_pcx: int = -9999
var last_pcz: int = -9999

# Atlas material
var atlas_material: StandardMaterial3D = null
var atlas_texture: Texture2D = null

# Save file
var save_path: String = "user://world_save.bin"
var modifications: Dictionary = {} # "x,y,z" -> block_id (player edits)
var _save_dirty: bool = false
var _save_timer: float = 0.0

signal chunk_loaded(cx, cz)
signal chunk_unloaded(cx, cz)
signal block_changed(wx, wy, wz, id)

func _ready() -> void:
	# Load atlas texture
	atlas_texture = load("res://assets/textures/atlas.png")
	atlas_material = StandardMaterial3D.new()
	atlas_material.albedo_texture = atlas_texture
	atlas_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	atlas_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	atlas_material.roughness = 1.0
	atlas_material.metallic = 0.0
	atlas_material.vertex_color_use_as_albedo = true
	# Alpha scissor for leaves/cross blocks with transparent pixels
	atlas_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	atlas_material.alpha_scissor_threshold = 0.3
	atlas_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	atlas_material.no_depth_test = false

	terrain = TG.new(seed_val)

	# Try to load existing save
	_load_modifications()

func _exit_tree() -> void:
	# Save any pending modifications before quitting
	if _save_dirty:
		_save_modifications()

func set_player(p: Node3D) -> void:
	player = p

func _process(delta: float) -> void:
	if player == null:
		return
	var ppos: Vector3 = player.position
	var pcx := floori(ppos.x / float(CHUNK_X))
	var pcz := floori(ppos.z / float(CHUNK_Z))
	if pcx != last_pcx or pcz != last_pcz:
		last_pcx = pcx
		last_pcz = pcz
		_update_streaming(pcx, pcz)

	# Mesh a small budget of chunks per frame (avoid hitches)
	var budget := 2
	while budget > 0 and chunks_to_mesh.size() > 0:
		budget -= 1
		var c = chunks_to_mesh.pop_front()
		if is_instance_valid(c) and c.dirty:
			_mesh_chunk(c)

	# Debounced save (don't save on every block edit — causes lag)
	if _save_dirty:
		_save_timer -= delta
		if _save_timer <= 0:
			_save_modifications()
			_save_dirty = false

func _update_streaming(pcx: int, pcz: int) -> void:
	# Request new chunks in render distance (sorted by distance for better pop-in)
	var rd: int = render_distance
	var to_load: Array = []
	for dz in range(-rd, rd + 1):
		for dx in range(-rd, rd + 1):
			var dist_sq := dx * dx + dz * dz
			if dist_sq > (rd + 0.5) * (rd + 0.5):
				continue
			var key := Vector2i(pcx + dx, pcz + dz)
			if not chunks.has(key):
				to_load.append({"key": key, "dist": dist_sq})
	# Sort by distance so closest chunks load first
	to_load.sort_custom(func(a, b): return a.dist < b.dist)
	for entry in to_load:
		_create_chunk(entry.key.x, entry.key.y)

	# Mark distant chunks for unload
	var to_remove: Array = []
	for key in chunks.keys():
		var dx: int = key.x - pcx
		var dz: int = key.y - pcz
		if dx * dx + dz * dz > (rd + 2) * (rd + 2):
			to_remove.append(key)
	for key in to_remove:
		var c = chunks[key]
		chunks.erase(key)
		# Remove from mesh queue if present
		chunks_to_mesh.erase(c)
		c.queue_free()
		chunk_unloaded.emit(key.x, key.y)

func _create_chunk(p_cx: int, p_cz: int) -> Node:
	var c: Node = ChunkClass.new()
	c.initialize(p_cx, p_cz, self)
	add_child(c)
	# CRITICAL: Generate terrain data before meshing!
	c.data = terrain.generate_chunk(p_cx, p_cz)
	chunks[Vector2i(p_cx, p_cz)] = c
	# Apply modifications from save
	_apply_modifications(c)
	# Schedule meshing
	c.dirty = true
	chunks_to_mesh.append(c)
	chunk_loaded.emit(p_cx, p_cz)
	return c

func _apply_modifications(c: Node) -> void:
	# Apply saved block edits for this chunk only (efficient: iterate modifications, not all voxels)
	var base_x: int = c.cx * CHUNK_X
	var base_z: int = c.cz * CHUNK_Z
	# Compute the world-coordinate range for this chunk
	var min_wx: int = base_x
	var max_wx: int = base_x + CHUNK_X - 1
	var min_wz: int = base_z
	var max_wz: int = base_z + CHUNK_Z - 1
	for key in modifications:
		var parts := key.split(",")
		if parts.size() != 3:
			continue
		var wx: int = int(parts[0])
		var wy: int = int(parts[1])
		var wz: int = int(parts[2])
		# Skip if outside this chunk's XZ range
		if wx < min_wx or wx > max_wx or wz < min_wz or wz > max_wz:
			continue
		if wy < 0 or wy >= CHUNK_Y:
			continue
		var lx: int = wx - base_x
		var lz: int = wz - base_z
		c.set_voxel_local(lx, wy, lz, int(modifications[key]))

func _mesh_chunk(c: Node) -> void:
	if c == null or not is_instance_valid(c):
		return
	var mesher: RefCounted = ChunkMesher.new()
	mesher.material = atlas_material
	var mesh_data: Dictionary = mesher.build_mesh(self, c)
	c.mesh_instance.mesh = mesh_data.mesh
	# Update collision shape
	if mesh_data.shape != null:
		c.collision.shape = mesh_data.shape
	c.dirty = false

# Public API: get/set block by world coords
func get_block(wx: int, wy: int, wz: int) -> int:
	if wy < 0 or wy >= CHUNK_Y:
		return B.AIR
	var pcx: int = floori(float(wx) / CHUNK_X)
	var pcz: int = floori(float(wz) / CHUNK_Z)
	var key := Vector2i(pcx, pcz)
	if not chunks.has(key):
		return B.AIR
	return chunks[key].get_voxel_world(wx, wy, wz)

func set_block(wx: int, wy: int, wz: int, id: int, persist: bool = true) -> void:
	if wy < 0 or wy >= CHUNK_Y:
		return
	var pcx: int = floori(float(wx) / CHUNK_X)
	var pcz: int = floori(float(wz) / CHUNK_Z)
	var key := Vector2i(pcx, pcz)
	if not chunks.has(key):
		return
	var c = chunks[key]
	c.set_voxel_world(wx, wy, wz, id)
	# Mark dirty for re-meshing
	c.dirty = true
	if not c in chunks_to_mesh:
		chunks_to_mesh.append(c)
	# Mark neighbors dirty if on border
	var lx: int = wx - pcx * CHUNK_X
	var lz: int = wz - pcz * CHUNK_Z
	if lx == 0:
		_mark_neighbor_dirty(pcx - 1, pcz)
	if lx == CHUNK_X - 1:
		_mark_neighbor_dirty(pcx + 1, pcz)
	if lz == 0:
		_mark_neighbor_dirty(pcx, pcz - 1)
	if lz == CHUNK_Z - 1:
		_mark_neighbor_dirty(pcx, pcz + 1)
	# Persist (debounced — don't save on every edit)
	if persist:
		modifications["%d,%d,%d" % [wx, wy, wz]] = id
		_save_dirty = true
		_save_timer = 2.0  # Save 2 seconds after the last edit
	block_changed.emit(wx, wy, wz, id)

func _mark_neighbor_dirty(p_cx: int, p_cz: int) -> void:
	var key := Vector2i(p_cx, p_cz)
	if chunks.has(key):
		var c = chunks[key]
		c.dirty = true
		if not c in chunks_to_mesh:
			chunks_to_mesh.append(c)

# Save / Load
func _save_modifications() -> void:
	var f: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_warning("QuackCraft: could not open save file for writing: " + save_path)
		return
	f.store_var(modifications)
	f.close()

func _load_modifications() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var f: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return
	modifications = f.get_var()
	f.close()
	if modifications == null:
		modifications = {}

# Raycast against the voxel grid (DDA-style).
# Returns {hit: bool, pos: Vector3i, normal: Vector3i, block: int} where pos
# is the voxel coordinate of the hit block, normal is the face normal.
func raycast(origin: Vector3, dir: Vector3, max_dist: float = 6.0) -> Dictionary:
	# Guard against zero-length direction
	if dir.length_squared() < 1e-12:
		return {"hit": false}
	dir = dir.normalized()
	var x := int(floor(origin.x))
	var y := int(floor(origin.y))
	var z := int(floor(origin.z))
	var stepX: int = 1 if dir.x > 0 else -1
	var stepY: int = 1 if dir.y > 0 else -1
	var stepZ: int = 1 if dir.z > 0 else -1

	# tMax: distance to next voxel boundary
	var tMaxX: float = _t_max(origin.x, dir.x)
	var tMaxY: float = _t_max(origin.y, dir.y)
	var tMaxZ: float = _t_max(origin.z, dir.z)
	var tDeltaX: float = abs(1.0 / dir.x) if abs(dir.x) > 1e-9 else 1e9
	var tDeltaY: float = abs(1.0 / dir.y) if abs(dir.y) > 1e-9 else 1e9
	var tDeltaZ: float = abs(1.0 / dir.z) if abs(dir.z) > 1e-9 else 1e9

	var normal := Vector3i.ZERO
	var t := 0.0
	var iterations := 0
	while t < max_dist and iterations < 200:  # iteration cap as safety
		iterations += 1
		var block: int = get_block(x, y, z)
		if block != B.AIR and not B.is_fluid(block):
			return {"hit": true, "pos": Vector3i(x, y, z), "normal": normal, "block": block}
		if tMaxX < tMaxY and tMaxX < tMaxZ:
			x += stepX
			t = tMaxX
			tMaxX += tDeltaX
			normal = Vector3i(-stepX, 0, 0)
		elif tMaxY < tMaxZ:
			y += stepY
			t = tMaxY
			tMaxY += tDeltaY
			normal = Vector3i(0, -stepY, 0)
		else:
			z += stepZ
			t = tMaxZ
			tMaxZ += tDeltaZ
			normal = Vector3i(0, 0, -stepZ)
	return {"hit": false}

func _t_max(origin: float, dir: float) -> float:
	if abs(dir) < 1e-9:
		return 1e9
	if dir > 0:
		var next: float = floor(origin) + 1.0
		return (next - origin) / dir
	else:
		var prev: float = floor(origin)
		return (origin - prev) / -dir

# Find a safe spawn position (top solid block near origin)
func find_spawn() -> Vector3:
	for attempt in range(20):
		var wx: int = (randi() % 32) - 16
		var wz: int = (randi() % 32) - 16
		var h: int = terrain.get_height(wx, wz)
		if h > 0:
			# Make sure the chunk is loaded first
			var pcx: int = floori(float(wx) / CHUNK_X)
			var pcz: int = floori(float(wz) / CHUNK_Z)
			_ensure_chunk(pcx, pcz)
			return Vector3(wx + 0.5, h + 2, wz + 0.5)
	return Vector3(0.5, 70, 0.5)

func _ensure_chunk(pcx: int, pcz: int) -> void:
	var key: Vector2i = Vector2i(pcx, pcz)
	if not chunks.has(key):
		var c: Node = _create_chunk(pcx, pcz)
		# Data is already generated in _create_chunk now
		_mesh_chunk(c)
