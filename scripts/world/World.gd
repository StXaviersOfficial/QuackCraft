# QuackCraft - World manager
# Owns all chunks, handles streaming around the player, multithreaded
# chunk generation & meshing, save/load, and block I/O.
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
var chunks_to_unload: Array = []
var thread: Thread
var mutex: Mutex
var gen_semaphore: Semaphore
var quit_thread: bool = false

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
	# Slight transparency support for leaves (alpha scissor)
	atlas_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	atlas_material.alpha_scissor_threshold = 0.3
	atlas_material.cull_mode = BaseMaterial3D.CULL_DISABLED # show both sides for cross blocks
	atlas_material.no_depth_test = false
	# Disable ambient occlusion (cheaper on mobile)
	atlas_material.gi_mode = BaseMaterial3D.GI_MODE_DISABLED

	terrain = TG.new(seed_val)

	mutex = Mutex.new()
	gen_semaphore = Semaphore.new()
	thread = Thread.new()
	thread.start(_generation_thread_main)

	# Try to load existing save
	_load_modifications()

func _exit_tree() -> void:
	quit_thread = true
	gen_semaphore.post()
	if thread:
		thread.wait_to_finish()

func set_player(p: Node3D) -> void:
	player = p

func _process(_delta: float) -> void:
	if player == null:
		return
	var ppos := player.position
	var pcx := int(ppos.x) / CHUNK_X
	var pcz := int(ppos.z) / CHUNK_Z
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

func _update_streaming(pcx: int, pcz: int) -> void:
	# Request new chunks in render distance
	var rd := render_distance
	for dz in range(-rd, rd + 1):
		for dx in range(-rd, rd + 1):
			if dx * dx + dz * dz > (rd + 0.5) * (rd + 0.5):
				continue
			var key := Vector2i(pcx + dx, pcz + dz)
			if not chunks.has(key):
				_create_chunk(key.x, key.y)

	# Mark distant chunks for unload
	var to_remove := []
	for key in chunks.keys():
		var dx := key.x - pcx
		var dz := key.y - pcz
		if dx * dx + dz * dz > (rd + 2) * (rd + 2):
			to_remove.append(key)
	for key in to_remove:
		var c = chunks[key]
		chunks.erase(key)
		c.queue_free()
		chunk_unloaded.emit(key.x, key.y)

func _create_chunk(p_cx: int, p_cz: int) -> Node:
	var c := ChunkClass.new()
	c.initialize(p_cx, p_cz, self)
	add_child(c)
	chunks[Vector2i(p_cx, p_cz)] = c
	# Apply modifications from save
	_apply_modifications(c)
	# Schedule meshing
	c.dirty = true
	chunks_to_mesh.append(c)
	chunk_loaded.emit(p_cx, p_cz)
	return c

func _apply_modifications(c: Node) -> void:
	# Apply any saved block edits for this chunk
	var base_x := c.cx * CHUNK_X
	var base_z := c.cz * CHUNK_Z
	for x in range(CHUNK_X):
		for z in range(CHUNK_Z):
			for y in range(CHUNK_Y):
				var key := "%d,%d,%d" % [base_x + x, y, base_z + z]
				if modifications.has(key):
					c.set_voxel_local(x, y, z, modifications[key])

func _generation_thread_main() -> void:
	# In this simple design, terrain gen happens synchronously on main thread
	# (it's fast enough for a single 16x128x16 chunk).
	# Meshing is the expensive part and is currently also on main thread
	# (limited to 2 per frame to avoid hitches).
	# For larger render distances, this thread can be used to pre-generate.
	while not quit_thread:
		gen_semaphore.wait()
		if quit_thread:
			return

func _mesh_chunk(c: Node) -> void:
	if c == null or not is_instance_valid(c):
		return
	var mesher := ChunkMesher.new()
	mesher.material = atlas_material
	var mesh_data := mesher.build_mesh(self, c)
	c.mesh_instance.mesh = mesh_data.mesh
	# Update collision shape
	if mesh_data.shape != null:
		collision_update(c, mesh_data.shape)
	c.dirty = false

func collision_update(c: Node, shape: ConcavePolygonShape3D) -> void:
	if c.collision.shape != null:
		c.collision.shape = null
	c.collision.shape = shape
	c.collision.make_convex_from_brothers = false

# Public API: get/set block by world coords
func get_block(wx: int, wy: int, wz: int) -> int:
	if wy < 0 or wy >= CHUNK_Y: return B.AIR
	var pcx := wx / CHUNK_X
	var pcz := wz / CHUNK_Z
	# Python-style floor division for negatives
	if wx < 0: pcx = (wx - CHUNK_X + 1) / CHUNK_X
	if wz < 0: pcz = (wz - CHUNK_Z + 1) / CHUNK_Z
	var key := Vector2i(pcx, pcz)
	if not chunks.has(key):
		return B.AIR
	return chunks[key].get_voxel_world(wx, wy, wz)

func set_block(wx: int, wy: int, wz: int, id: int, persist: bool = true) -> void:
	if wy < 0 or wy >= CHUNK_Y: return
	var pcx := wx / CHUNK_X
	var pcz := wz / CHUNK_Z
	if wx < 0: pcx = (wx - CHUNK_X + 1) / CHUNK_X
	if wz < 0: pcz = (wz - CHUNK_Z + 1) / CHUNK_Z
	var key := Vector2i(pcx, pcz)
	if not chunks.has(key):
		return
	var c = chunks[key]
	c.set_voxel_world(wx, wy, wz, id)
	# Mark dirty for re-meshing
	c.dirty = true
	chunks_to_mesh.append(c)
	# Mark neighbors dirty if on border
	var lx := wx - pcx * CHUNK_X
	var lz := wz - pcz * CHUNK_Z
	if lx == 0:
		_mark_neighbor_dirty(pcx - 1, pcz)
	if lx == CHUNK_X - 1:
		_mark_neighbor_dirty(pcx + 1, pcz)
	if lz == 0:
		_mark_neighbor_dirty(pcx, pcz - 1)
	if lz == CHUNK_Z - 1:
		_mark_neighbor_dirty(pcx, pcz + 1)
	# Persist
	if persist:
		modifications["%d,%d,%d" % [wx, wy, wz]] = id
		_save_modifications()
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
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		return
	f.store_var(modifications)
	f.close()

func _load_modifications() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return
	modifications = f.get_var()
	f.close()
	if modifications == null:
		modifications = {}

# Raycast against the voxel grid (DDA-style).
# Returns {hit: bool, pos: Vector3i, normal: Vector3i} where pos is the
# voxel coordinate of the hit block, normal is the face normal.
func raycast(origin: Vector3, dir: Vector3, max_dist: float = 6.0) -> Dictionary:
	var x := int(floor(origin.x))
	var y := int(floor(origin.y))
	var z := int(floor(origin.z))
	var stepX: int = 1 if dir.x > 0 else -1
	var stepY: int = 1 if dir.y > 0 else -1
	var stepZ: int = 1 if dir.z > 0 else -1

	# tMax: distance to next voxel boundary
	var tMaxX := _t_max(origin.x, dir.x)
	var tMaxY := _t_max(origin.y, dir.y)
	var tMaxZ := _t_max(origin.z, dir.z)
	var tDeltaX: float = abs(1.0 / dir.x) if abs(dir.x) > 1e-9 else 1e9
	var tDeltaY: float = abs(1.0 / dir.y) if abs(dir.y) > 1e-9 else 1e9
	var tDeltaZ: float = abs(1.0 / dir.z) if abs(dir.z) > 1e-9 else 1e9

	var normal := Vector3i.ZERO
	var t := 0.0
	while t < max_dist:
		var block := get_block(x, y, z)
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
		var wx := (randi() % 32) - 16
		var wz := (randi() % 32) - 16
		var h := terrain.get_height(wx, wz)
		if h > 0:
			# Make sure the chunk is loaded first
			var pcx := wx / CHUNK_X
			var pcz := wz / CHUNK_Z
			_ensure_chunk(pcx, pcz)
			return Vector3(wx + 0.5, h + 2, wz + 0.5)
	return Vector3(0.5, 70, 0.5)

func _ensure_chunk(pcx: int, pcz: int) -> void:
	var key := Vector2i(pcx, pcz)
	if not chunks.has(key):
		var c := _create_chunk(pcx, pcz)
		# Generate immediately
		c.data = terrain.generate_chunk(pcx, pcz)
		_apply_modifications(c)
		_mesh_chunk(c)
