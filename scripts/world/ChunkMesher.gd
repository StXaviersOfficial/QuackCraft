# QuackCraft - Chunk mesher
# Builds a single ArrayMesh for a chunk, culling faces between solid blocks.
# Uses one texture atlas with UVs per block-face.
extends RefCounted

const B = preload("res://scripts/blocks/BlockRegistry.gd")
const TG = preload("res://scripts/world/TerrainGen.gd")

const CHUNK_X: int = TG.CHUNK_X
const CHUNK_Y: int = TG.CHUNK_Y
const CHUNK_Z: int = TG.CHUNK_Z

var material: Material = null

# Cube face definitions: positions and normals
# Order: +X, -X, +Y, -Y, +Z, -Z
const FACES := [
	{
		"dir": Vector3i(1, 0, 0),
		"normal": Vector3(1, 0, 0),
		"corners": [
			Vector3(1, 0, 0), Vector3(1, 1, 0),
			Vector3(1, 1, 1), Vector3(1, 0, 1)
		],
		"uv": [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]
	},
	{
		"dir": Vector3i(-1, 0, 0),
		"normal": Vector3(-1, 0, 0),
		"corners": [
			Vector3(0, 0, 1), Vector3(0, 1, 1),
			Vector3(0, 1, 0), Vector3(0, 0, 0)
		],
		"uv": [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]
	},
	{
		"dir": Vector3i(0, 1, 0),
		"normal": Vector3(0, 1, 0),
		"corners": [
			Vector3(0, 1, 1), Vector3(1, 1, 1),
			Vector3(1, 1, 0), Vector3(0, 1, 0)
		],
		"uv": [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	},
	{
		"dir": Vector3i(0, -1, 0),
		"normal": Vector3(0, -1, 0),
		"corners": [
			Vector3(0, 0, 0), Vector3(1, 0, 0),
			Vector3(1, 0, 1), Vector3(0, 0, 1)
		],
		"uv": [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	},
	{
		"dir": Vector3i(0, 0, 1),
		"normal": Vector3(0, 0, 1),
		"corners": [
			Vector3(1, 0, 1), Vector3(1, 1, 1),
			Vector3(0, 1, 1), Vector3(0, 0, 1)
		],
		"uv": [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]
	},
	{
		"dir": Vector3i(0, 0, -1),
		"normal": Vector3(0, 0, -1),
		"corners": [
			Vector3(0, 0, 0), Vector3(0, 1, 0),
			Vector3(1, 1, 0), Vector3(1, 0, 0)
		],
		"uv": [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]
	},
]

# Returns {mesh: ArrayMesh, shape: ConcavePolygonShape3D}
func build_mesh(world: Node, chunk: Node) -> Dictionary:
	var opaque_verts := PackedVector3Array()
	var opaque_uvs := PackedVector2Array()
	var opaque_normals := PackedVector3Array()
	var opaque_indices := PackedInt32Array()
	var opaque_colors := PackedColorArray()

	var trans_verts := PackedVector3Array()
	var trans_uvs := PackedVector2Array()
	var trans_normals := PackedVector3Array()
	var trans_indices := PackedInt32Array()
	var trans_colors := PackedColorArray()

	var cross_verts := PackedVector3Array()
	var cross_uvs := PackedVector2Array()
	var cross_normals := PackedVector3Array()
	var cross_indices := PackedInt32Array()
	var cross_colors := PackedColorArray()

	var collision_faces := PackedVector3Array()

	for y in range(CHUNK_Y):
		for z in range(CHUNK_Z):
			for x in range(CHUNK_X):
				var id: int = chunk.get_voxel_local(x, y, z)
				if id == B.AIR:
					continue
				var def: Dictionary = B.get_def(id)
				var render: String = def.get("render", "cube")
				var wx := chunk.cx * CHUNK_X + x
				var wz := chunk.cz * CHUNK_Z + z
				if render == "cube":
					# Build each face only if the neighbor is air or transparent
					for f in range(6):
						var face := FACES[f]
						var nb := Vector3i(x + face.dir.x, y + face.dir.y, z + face.dir.z)
						var nblock: int = _get_block_or_neighbor(world, chunk, nb.x, nb.y, nb.z)
						# Cull if neighbor is opaque
						if B.is_opaque_cube(nblock):
							continue
						# Don't render face between two of the same fluid
						if B.is_fluid(id) and nblock == id:
							continue
						# Don't render face between same transparent blocks
						if id == nblock:
							continue
						# Pick tile (top/side/bottom based on face)
						var tile: int = def.side
						if face.dir.y > 0: tile = def.top
						elif face.dir.y < 0: tile = def.bottom
						var uv_origin := B.tile_to_uv(tile)
						var uv_sz := B.tile_size_uv()
						# Append quad
						var target_verts
						var target_uvs
						var target_normals
						var target_indices
						var target_colors
						if B.is_transparent(id) and not B.is_fluid(id):
							target_verts = trans_verts
							target_uvs = trans_uvs
							target_normals = trans_normals
							target_indices = trans_indices
							target_colors = trans_colors
						else:
							target_verts = opaque_verts
							target_uvs = opaque_uvs
							target_normals = opaque_normals
							target_indices = opaque_indices
							target_colors = opaque_colors
						_add_quad(target_verts, target_uvs, target_normals, target_indices, target_colors,
							Vector3(x, y, z), face, uv_origin, uv_sz, Color(1, 1, 1, 1))
						# Collision: only for solid opaque cubes
						if not B.is_transparent(id) and not B.is_fluid(id):
							for c in face.corners:
								collision_faces.append(Vector3(x, y, z) + c)
				elif render == "cross":
					# Billboard cross (flowers, grass, etc.)
					var tile: int = def.side
					var uv_origin := B.tile_to_uv(tile)
					var uv_sz := B.tile_size_uv()
					_add_cross(cross_verts, cross_uvs, cross_normals, cross_indices, cross_colors,
						Vector3(x, y, z), uv_origin, uv_sz)
				elif render == "fluid":
					# Render only top face + side faces (against non-fluid neighbor)
					for f in range(6):
						var face := FACES[f]
						if face.dir.y < 0:
							continue # don't render bottom of fluid (perf)
						var nb := Vector3i(x + face.dir.x, y + face.dir.y, z + face.dir.z)
						var nblock: int = _get_block_or_neighbor(world, chunk, nb.x, nb.y, nb.z)
						if B.is_opaque_cube(nblock):
							continue
						if nblock == id:
							continue
						var tile: int = def.side
						var uv_origin := B.tile_to_uv(tile)
						var uv_sz := B.tile_size_uv()
						_add_quad(opaque_verts, opaque_uvs, opaque_normals, opaque_indices, opaque_colors,
							Vector3(x, y, z), face, uv_origin, uv_sz, Color(1, 1, 1, 0.8))

	# Build the ArrayMesh
	var arr_mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)

	if opaque_verts.size() > 0:
		arrays[Mesh.ARRAY_VERTEX] = opaque_verts
		arrays[Mesh.ARRAY_TEX_UV] = opaque_uvs
		arrays[Mesh.ARRAY_NORMAL] = opaque_normals
		arrays[Mesh.ARRAY_INDEX] = opaque_indices
		arrays[Mesh.ARRAY_COLOR] = opaque_colors
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(0, material)

	if trans_verts.size() > 0:
		arrays[Mesh.ARRAY_VERTEX] = trans_verts
		arrays[Mesh.ARRAY_TEX_UV] = trans_uvs
		arrays[Mesh.ARRAY_NORMAL] = trans_normals
		arrays[Mesh.ARRAY_INDEX] = trans_indices
		arrays[Mesh.ARRAY_COLOR] = trans_colors
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count(), material)

	if cross_verts.size() > 0:
		arrays[Mesh.ARRAY_VERTEX] = cross_verts
		arrays[Mesh.ARRAY_TEX_UV] = cross_uvs
		arrays[Mesh.ARRAY_NORMAL] = cross_normals
		arrays[Mesh.ARRAY_INDEX] = cross_indices
		arrays[Mesh.ARRAY_COLOR] = cross_colors
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count(), material)

	# Build collision shape from opaque cube faces
	var shape := ConcavePolygonShape3D.new()
	if collision_faces.size() > 0:
		shape.set_faces(collision_faces)

	return {"mesh": arr_mesh, "shape": shape}

func _get_block_or_neighbor(world: Node, chunk: Node, x: int, y: int, z: int) -> int:
	# If inside this chunk, read directly; otherwise query the world.
	if x >= 0 and x < CHUNK_X and y >= 0 and y < CHUNK_Y and z >= 0 and z < CHUNK_Z:
		return chunk.get_voxel_local(x, y, z)
	# Outside: query world (returns AIR if neighbor chunk not loaded)
	var wx := chunk.cx * CHUNK_X + x
	var wz := chunk.cz * CHUNK_Z + z
	return world.get_block(wx, y, wz)

func _add_quad(verts, uvs, normals, indices, colors, origin: Vector3, face: Dictionary, uv_origin: Vector2, uv_sz: Vector2, color: Color) -> void:
	var start := verts.size()
	for i in range(4):
		verts.append(origin + face.corners[i])
		normals.append(face.normal)
		colors.append(color)
		var uv := uv_origin + Vector2(face.uv[i].x * uv_sz.x, face.uv[i].y * uv_sz.y)
		uvs.append(uv)
	# Two triangles
	indices.append(start)
	indices.append(start + 1)
	indices.append(start + 2)
	indices.append(start)
	indices.append(start + 2)
	indices.append(start + 3)

func _add_cross(verts, uvs, normals, indices, colors, origin: Vector3, uv_origin: Vector2, uv_sz: Vector2) -> void:
	# Two crossed quads forming an X
	var p1 := [
		Vector3(0.15, 0, 0.15), Vector3(0.15, 1, 0.15),
		Vector3(0.85, 1, 0.85), Vector3(0.85, 0, 0.85)
	]
	var p2 := [
		Vector3(0.85, 0, 0.15), Vector3(0.85, 1, 0.15),
		Vector3(0.15, 1, 0.85), Vector3(0.15, 0, 0.85)
	]
	# Quad 1 (+normal)
	var start := verts.size()
	for i in range(4):
		verts.append(origin + p1[i])
		normals.append(Vector3(0.7, 0, 0.7))
		colors.append(Color(1, 1, 1, 1))
		var uv: Vector2 = uv_origin + Vector2(float(i) * uv_sz.x * 0.5, float(1 if i == 1 or i == 2 else 0) * uv_sz.y)
		uvs.append(uv)
	indices.append(start)
	indices.append(start + 1)
	indices.append(start + 2)
	indices.append(start)
	indices.append(start + 2)
	indices.append(start + 3)
	# Quad 2 (other diagonal)
	start = verts.size()
	for i in range(4):
		verts.append(origin + p2[i])
		normals.append(Vector3(-0.7, 0, 0.7))
		colors.append(Color(1, 1, 1, 1))
		var uv: Vector2 = uv_origin + Vector2(float(i) * uv_sz.x * 0.5, float(1 if i == 1 or i == 2 else 0) * uv_sz.y)
		uvs.append(uv)
	indices.append(start)
	indices.append(start + 1)
	indices.append(start + 2)
	indices.append(start)
	indices.append(start + 2)
	indices.append(start + 3)
