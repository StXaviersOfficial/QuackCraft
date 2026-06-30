# QuackCraft - Chunk (a 16x128x16 voxel column)
# Owns its voxel data, its mesh instance, and a thread-safe dirty flag.
extends Node3D

const B = preload("res://scripts/blocks/BlockRegistry.gd")
const TG = preload("res://scripts/world/TerrainGen.gd")

const CHUNK_X: int = TG.CHUNK_X
const CHUNK_Y: int = TG.CHUNK_Y
const CHUNK_Z: int = TG.CHUNK_Z

var cx: int = 0
var cz: int = 0
var data: PackedByteArray
var dirty: bool = true
var mesh_instance: MeshInstance3D
var collision: CollisionShape3D
var static_body: StaticBody3D
var generated: bool = false

# World reference (set on creation)
var world: Node = null

func _ready() -> void:
	mesh_instance = MeshInstance3D.new()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_STATIC
	add_child(mesh_instance)

	static_body = StaticBody3D.new()
	static_body.collision_layer = 1 # world
	collision = CollisionShape3D.new()
	static_body.add_child(collision)
	add_child(static_body)

func initialize(p_cx: int, p_cz: int, p_world: Node) -> void:
	cx = p_cx
	cz = p_cz
	world = p_world
	data = PackedByteArray()
	data.resize(CHUNK_X * CHUNK_Y * CHUNK_Z)
	data.fill(0)
	position = Vector3(cx * CHUNK_X, 0, cz * CHUNK_Z)
	name = "Chunk_%d_%d" % [cx, cz]

func get_voxel_local(x: int, y: int, z: int) -> int:
	if x < 0 or x >= CHUNK_X or y < 0 or y >= CHUNK_Y or z < 0 or z >= CHUNK_Z:
		return B.AIR
	return data[TG.idx(x, y, z)]

func set_voxel_local(x: int, y: int, z: int, v: int) -> void:
	if x < 0 or x >= CHUNK_X or y < 0 or y >= CHUNK_Y or z < 0 or z >= CHUNK_Z:
		return
	data[TG.idx(x, y, z)] = v
	dirty = true

func get_voxel_world(wx: int, wy: int, wz: int) -> int:
	var lx: int = wx - cx * CHUNK_X
	var lz: int = wz - cz * CHUNK_Z
	return get_voxel_local(lx, wy, lz)

func set_voxel_world(wx: int, wy: int, wz: int, v: int) -> bool:
	var lx: int = wx - cx * CHUNK_X
	var lz: int = wz - cz * CHUNK_Z
	if lx < 0 or lx >= CHUNK_X or lz < 0 or lz >= CHUNK_Z:
		return false
	if wy < 0 or wy >= CHUNK_Y:
		return false
	data[TG.idx(lx, wy, lz)] = v
	dirty = true
	return true

func is_generated() -> bool:
	return generated
