# QuackCraft - Voxel block registry
# Stores every block type's metadata, texture mapping, and properties.
# Original asset names; designs are original voxel/pixel art.
extends Node

# Block ID constants
const AIR := 0
const GRASS := 1
const DIRT := 2
const STONE := 3
const COBBLESTONE := 4
const SAND := 5
const GRAVEL := 6
const CLAY := 7
const SNOW := 8
const ICE := 9
const SANDSTONE := 10
const BEDROCK := 11
const MYCEL := 12
const COAL_ORE := 13
const IRON_ORE := 14
const GOLD_ORE := 15
const GEM_ORE := 16
const EMERALD_ORE := 17
const LAPIS_ORE := 18
const SPARK_ORE := 19
const OAK_LOG := 20
const OAK_PLANKS := 21
const OAK_LEAVES := 22
const OAK_SAPLING := 23
const BIRCH_LOG := 24
const BIRCH_PLANKS := 25
const BIRCH_LEAVES := 26
const BIRCH_SAPLING := 27
const SPRUCE_LOG := 28
const SPRUCE_PLANKS := 29
const SPRUCE_LEAVES := 30
const SPRUCE_SAPLING := 31
const JUNGLE_LOG := 32
const JUNGLE_PLANKS := 33
const JUNGLE_LEAVES := 34
const JUNGLE_SAPLING := 35
const ACACIA_LOG := 36
const ACACIA_PLANKS := 37
const ACACIA_LEAVES := 38
const ACACIA_SAPLING := 39
const DARK_OAK_LOG := 40
const DARK_OAK_PLANKS := 41
const DARK_OAK_LEAVES := 42
const DARK_OAK_SAPLING := 43
const WATER := 44
const LAVA := 45
const BRICKS := 46
const STONE_BRICKS := 47
const GLASS := 48
const WOOL_WHITE := 49
const WOOL_RED := 50
const WOOL_GREEN := 51
const WOOL_BLUE := 52
const WOOL_YELLOW := 53
const WOOL_BLACK := 54
const WOOL_GRAY := 55
const WOOL_BROWN := 56
const WOOL_PINK := 57
const WOOL_CYAN := 58
const WOOL_MAGENTA := 59
const WOOL_ORANGE := 60
const WOOL_LIME := 61
const WOOL_PURPLE := 62
const TERRACOTTA_WHITE := 63
const TERRACOTTA_RED := 64
const TERRACOTTA_ORANGE := 65
const TERRACOTTA_YELLOW := 66
const TERRACOTTA_GREEN := 67
const TERRACOTTA_BLUE := 68
const TERRACOTTA_PURPLE := 69
const TERRACOTTA_PINK := 70
const TERRACOTTA_BROWN := 71
const TERRACOTTA_CYAN := 72
const TERRACOTTA_GRAY := 73
const TERRACOTTA_BLACK := 74
const TERRACOTTA_MAGENTA := 75
const TERRACOTTA_LIME := 76
const BOOKSHELF := 77
const HAY_BALE := 78
const LADDER := 79
const CRAFTING_TABLE := 80
const FURNACE := 81
const CHEST := 82
const DOOR := 83
const TRAPDOOR := 84
const BED := 85
const TORCH := 86
const RUNE_ALTAR := 87
const BREW_STAND := 88
const TALL_GRASS := 89
const FLOWER_RED := 90
const FLOWER_YELLOW := 91
const FLOWER_WHITE := 92
const FLOWER_PURPLE := 93
const FLOWER_PINK := 94
const FLOWER_BLUE := 95
const MUSHROOM_RED := 96
const MUSHROOM_BROWN := 97
const CACTUS := 98
const REED := 99
const VINES := 100
const LILY_PAD := 101
const SNOW_LAYER := 102

# Tool tier constants
enum ToolTier { HAND=0, WOOD=1, STONE=2, IRON=3, GOLD=4, GEM=5 }
enum ToolType { NONE=0, PICKAXE=1, AXE=2, SHOVEL=3, SWORD=4, HOE=5 }

# Block definitions
static var _defs := {}

const ATLAS_COLS := 16
const ATLAS_ROWS := 16
const TILE_SIZE := 16

func _ready() -> void:
	_register_all()

func _register(id: int, name: String, top: int, side: int, bottom: int, opts: Dictionary = {}) -> void:
	_defs[id] = {
		"name": name,
		"top": top,
		"side": side,
		"bottom": bottom,
		"solid": opts.get("solid", true),
		"transparent": opts.get("transparent", false),
		"hardness": opts.get("hardness", 1.0),
		"tool_type": opts.get("tool_type", ToolType.NONE),
		"tool_tier": opts.get("tool_tier", ToolTier.HAND),
		"light": opts.get("light", 0),
		"fluid": opts.get("fluid", false),
		"render": opts.get("render", "cube"),
	}

func _register_all() -> void:
	_t(AIR, "air", 0, {"solid": false, "transparent": true, "hardness": 0.0, "render": "none"})
	_g(GRASS, "grass", 0, 2, 3, {"hardness": 0.6, "tool_type": ToolType.SHOVEL})
	_t(DIRT, "dirt", 3, {"hardness": 0.5, "tool_type": ToolType.SHOVEL})
	_t(STONE, "stone", 4, {"hardness": 1.5, "tool_type": ToolType.PICKAXE, "tool_tier": ToolTier.WOOD})
	_t(COBBLESTONE, "cobblestone", 5, {"hardness": 2.0, "tool_type": ToolType.PICKAXE, "tool_tier": ToolTier.WOOD})
	_t(SAND, "sand", 6, {"hardness": 0.5, "tool_type": ToolType.SHOVEL})
	_t(GRAVEL, "gravel", 7, {"hardness": 0.6, "tool_type": ToolType.SHOVEL})
	_t(CLAY, "clay", 8, {"hardness": 0.6, "tool_type": ToolType.SHOVEL})
	_t(SNOW, "snow", 9, {"hardness": 0.3, "tool_type": ToolType.SHOVEL})
	_t(ICE, "ice", 10, {"hardness": 0.5, "tool_type": ToolType.PICKAXE, "transparent": true})
	_t(SANDSTONE, "sandstone", 11, {"hardness": 1.0, "tool_type": ToolType.PICKAXE})
	_t(BEDROCK, "bedrock", 12, {"hardness": 9999.0, "tool_type": ToolType.NONE, "tool_tier": ToolTier.HAND})
	_t(MYCEL, "mycel", 13, {"hardness": 0.6, "tool_type": ToolType.SHOVEL})

	_t(COAL_ORE, "coal_ore", 16, {"hardness": 3.0, "tool_type": ToolType.PICKAXE, "tool_tier": ToolTier.WOOD})
	_t(IRON_ORE, "iron_ore", 17, {"hardness": 3.5, "tool_type": ToolType.PICKAXE, "tool_tier": ToolTier.STONE})
	_t(GOLD_ORE, "gold_ore", 18, {"hardness": 3.0, "tool_type": ToolType.PICKAXE, "tool_tier": ToolTier.IRON})
	_t(GEM_ORE, "gem_ore", 19, {"hardness": 5.0, "tool_type": ToolType.PICKAXE, "tool_tier": ToolTier.IRON})
	_t(EMERALD_ORE, "emerald_ore", 20, {"hardness": 3.0, "tool_type": ToolType.PICKAXE, "tool_tier": ToolTier.IRON})
	_t(LAPIS_ORE, "lapis_ore", 21, {"hardness": 3.0, "tool_type": ToolType.PICKAXE, "tool_tier": ToolTier.STONE})
	_t(SPARK_ORE, "spark_ore", 22, {"hardness": 3.0, "tool_type": ToolType.PICKAXE, "tool_tier": ToolTier.STONE})

	_g(OAK_LOG, "oak_log", 24, 25, 24, {"hardness": 2.0, "tool_type": ToolType.AXE})
	_t(OAK_PLANKS, "oak_planks", 26, {"hardness": 2.0, "tool_type": ToolType.AXE})
	_t(OAK_LEAVES, "oak_leaves", 27, {"hardness": 0.2, "transparent": true})
	_t(OAK_SAPLING, "oak_sapling", 28, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})

	_g(BIRCH_LOG, "birch_log", 24, 30, 24, {"hardness": 2.0, "tool_type": ToolType.AXE})
	_t(BIRCH_PLANKS, "birch_planks", 31, {"hardness": 2.0, "tool_type": ToolType.AXE})
	_t(BIRCH_LEAVES, "birch_leaves", 32, {"hardness": 0.2, "transparent": true})
	_t(BIRCH_SAPLING, "birch_sapling", 33, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})

	_g(SPRUCE_LOG, "spruce_log", 24, 35, 24, {"hardness": 2.0, "tool_type": ToolType.AXE})
	_t(SPRUCE_PLANKS, "spruce_planks", 36, {"hardness": 2.0, "tool_type": ToolType.AXE})
	_t(SPRUCE_LEAVES, "spruce_leaves", 37, {"hardness": 0.2, "transparent": true})
	_t(SPRUCE_SAPLING, "spruce_sapling", 38, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})

	_g(JUNGLE_LOG, "jungle_log", 24, 40, 24, {"hardness": 2.0, "tool_type": ToolType.AXE})
	_t(JUNGLE_PLANKS, "jungle_planks", 41, {"hardness": 2.0, "tool_type": ToolType.AXE})
	_t(JUNGLE_LEAVES, "jungle_leaves", 42, {"hardness": 0.2, "transparent": true})
	_t(JUNGLE_SAPLING, "jungle_sapling", 43, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})

	_g(ACACIA_LOG, "acacia_log", 24, 45, 24, {"hardness": 2.0, "tool_type": ToolType.AXE})
	_t(ACACIA_PLANKS, "acacia_planks", 46, {"hardness": 2.0, "tool_type": ToolType.AXE})
	_t(ACACIA_LEAVES, "acacia_leaves", 47, {"hardness": 0.2, "transparent": true})
	_t(ACACIA_SAPLING, "acacia_sapling", 48, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})

	_g(DARK_OAK_LOG, "dark_oak_log", 24, 50, 24, {"hardness": 2.0, "tool_type": ToolType.AXE})
	_t(DARK_OAK_PLANKS, "dark_oak_planks", 51, {"hardness": 2.0, "tool_type": ToolType.AXE})
	_t(DARK_OAK_LEAVES, "dark_oak_leaves", 52, {"hardness": 0.2, "transparent": true})
	_t(DARK_OAK_SAPLING, "dark_oak_sapling", 53, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})

	_t(WATER, "water", 60, {"solid": false, "transparent": true, "fluid": true, "hardness": 9999.0, "render": "fluid"})
	_t(LAVA, "lava", 61, {"solid": false, "transparent": true, "fluid": true, "hardness": 9999.0, "light": 15, "render": "fluid"})

	_t(BRICKS, "bricks", 64, {"hardness": 2.0, "tool_type": ToolType.PICKAXE})
	_t(STONE_BRICKS, "stone_bricks", 65, {"hardness": 1.5, "tool_type": ToolType.PICKAXE})
	_t(GLASS, "glass", 66, {"hardness": 0.3, "transparent": true})

	_t(WOOL_WHITE, "wool_white", 67, {"hardness": 0.8})
	_t(WOOL_RED, "wool_red", 68, {"hardness": 0.8})
	_t(WOOL_GREEN, "wool_green", 69, {"hardness": 0.8})
	_t(WOOL_BLUE, "wool_blue", 70, {"hardness": 0.8})
	_t(WOOL_YELLOW, "wool_yellow", 71, {"hardness": 0.8})
	_t(WOOL_BLACK, "wool_black", 72, {"hardness": 0.8})
	_t(WOOL_GRAY, "wool_gray", 73, {"hardness": 0.8})
	_t(WOOL_BROWN, "wool_brown", 74, {"hardness": 0.8})
	_t(WOOL_PINK, "wool_pink", 75, {"hardness": 0.8})
	_t(WOOL_CYAN, "wool_cyan", 76, {"hardness": 0.8})
	_t(WOOL_MAGENTA, "wool_magenta", 77, {"hardness": 0.8})
	_t(WOOL_ORANGE, "wool_orange", 78, {"hardness": 0.8})
	_t(WOOL_LIME, "wool_lime", 79, {"hardness": 0.8})
	_t(WOOL_PURPLE, "wool_purple", 80, {"hardness": 0.8})

	_t(TERRACOTTA_WHITE, "terracotta_white", 81, {"hardness": 1.25, "tool_type": ToolType.PICKAXE})
	_t(TERRACOTTA_RED, "terracotta_red", 82, {"hardness": 1.25, "tool_type": ToolType.PICKAXE})
	_t(TERRACOTTA_ORANGE, "terracotta_orange", 83, {"hardness": 1.25, "tool_type": ToolType.PICKAXE})
	_t(TERRACOTTA_YELLOW, "terracotta_yellow", 84, {"hardness": 1.25, "tool_type": ToolType.PICKAXE})
	_t(TERRACOTTA_GREEN, "terracotta_green", 85, {"hardness": 1.25, "tool_type": ToolType.PICKAXE})
	_t(TERRACOTTA_BLUE, "terracotta_blue", 86, {"hardness": 1.25, "tool_type": ToolType.PICKAXE})
	_t(TERRACOTTA_PURPLE, "terracotta_purple", 87, {"hardness": 1.25, "tool_type": ToolType.PICKAXE})
	_t(TERRACOTTA_PINK, "terracotta_pink", 88, {"hardness": 1.25, "tool_type": ToolType.PICKAXE})
	_t(TERRACOTTA_BROWN, "terracotta_brown", 89, {"hardness": 1.25, "tool_type": ToolType.PICKAXE})
	_t(TERRACOTTA_CYAN, "terracotta_cyan", 90, {"hardness": 1.25, "tool_type": ToolType.PICKAXE})
	_t(TERRACOTTA_GRAY, "terracotta_gray", 91, {"hardness": 1.25, "tool_type": ToolType.PICKAXE})
	_t(TERRACOTTA_BLACK, "terracotta_black", 92, {"hardness": 1.25, "tool_type": ToolType.PICKAXE})
	_t(TERRACOTTA_MAGENTA, "terracotta_magenta", 93, {"hardness": 1.25, "tool_type": ToolType.PICKAXE})
	_t(TERRACOTTA_LIME, "terracotta_lime", 94, {"hardness": 1.25, "tool_type": ToolType.PICKAXE})

	_t(BOOKSHELF, "bookshelf", 95, {"hardness": 1.5, "tool_type": ToolType.AXE})
	_t(HAY_BALE, "hay_bale", 96, {"hardness": 0.5})
	_t(LADDER, "ladder", 97, {"solid": false, "transparent": true, "hardness": 0.4, "render": "cross"})

	_t(CRAFTING_TABLE, "crafting_table", 98, {"hardness": 2.5, "tool_type": ToolType.AXE})
	_t(FURNACE, "furnace", 99, {"hardness": 3.5, "tool_type": ToolType.PICKAXE, "light": 0})
	_t(CHEST, "chest", 100, {"hardness": 2.5, "tool_type": ToolType.AXE})
	_t(DOOR, "door", 101, {"solid": false, "transparent": true, "hardness": 1.0, "tool_type": ToolType.AXE})
	_t(TRAPDOOR, "trapdoor", 102, {"solid": false, "transparent": true, "hardness": 1.0, "tool_type": ToolType.AXE})
	_t(BED, "bed", 103, {"solid": false, "transparent": true, "hardness": 0.2})
	_t(TORCH, "torch", 104, {"solid": false, "transparent": true, "hardness": 0.0, "light": 14, "render": "cross"})
	_t(RUNE_ALTAR, "rune_altar", 105, {"hardness": 3.0, "tool_type": ToolType.PICKAXE, "light": 7})
	_t(BREW_STAND, "brew_stand", 106, {"hardness": 1.0, "light": 4})

	_t(TALL_GRASS, "tall_grass", 107, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})
	_t(FLOWER_RED, "flower_red", 108, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})
	_t(FLOWER_YELLOW, "flower_yellow", 109, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})
	_t(FLOWER_WHITE, "flower_white", 110, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})
	_t(FLOWER_PURPLE, "flower_purple", 111, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})
	_t(FLOWER_PINK, "flower_pink", 112, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})
	_t(FLOWER_BLUE, "flower_blue", 113, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})
	_t(MUSHROOM_RED, "mushroom_red", 114, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross", "light": 3})
	_t(MUSHROOM_BROWN, "mushroom_brown", 115, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})
	_t(CACTUS, "cactus", 116, {"hardness": 0.4})
	_t(REED, "reed", 117, {"solid": false, "transparent": true, "hardness": 0.0, "render": "cross"})
	_t(VINES, "vines", 118, {"solid": false, "transparent": true, "hardness": 0.2, "render": "cross"})
	_t(LILY_PAD, "lily_pad", 119, {"solid": false, "transparent": true, "hardness": 0.0})
	_t(SNOW_LAYER, "snow_layer", 120, {"hardness": 0.2, "tool_type": ToolType.SHOVEL})



# Helper methods (replacing lambdas which can't be called directly in GDScript 4)
func _t(id: int, name: String, tile: int, opts: Dictionary = {}) -> void:
	_register(id, name, tile, tile, tile, opts)

func _g(id: int, name: String, top: int, side: int, bottom: int, opts: Dictionary = {}) -> void:
	_register(id, name, top, side, bottom, opts)

static func is_solid(id: int) -> bool:
	if id == AIR: return false
	var d = _defs.get(id)
	return d != null and d.solid

static func is_transparent(id: int) -> bool:
	if id == AIR: return true
	var d = _defs.get(id)
	return d != null and d.transparent

static func is_fluid(id: int) -> bool:
	var d = _defs.get(id)
	return d != null and d.fluid

static func is_air(id: int) -> bool:
	return id == AIR

static func is_cross(id: int) -> bool:
	var d = _defs.get(id)
	return d != null and d.render == "cross"

static func is_opaque_cube(id: int) -> bool:
	if id == AIR: return false
	var d = _defs.get(id)
	if d == null: return false
	if d.transparent or d.fluid: return false
	if d.render != "cube": return false
	return true

static func get_def(id: int) -> Dictionary:
	return _defs.get(id, {})

static func get_block_name(id: int) -> String:
	var d = _defs.get(id)
	return d.name if d != null else "unknown"

static func get_hardness(id: int) -> float:
	var d = _defs.get(id)
	return d.hardness if d != null else 1.0

static func get_light(id: int) -> int:
	var d = _defs.get(id)
	return d.light if d != null else 0

static func get_render(id: int) -> String:
	var d = _defs.get(id)
	return d.render if d != null else "cube"

static func get_tiles(id: int) -> Dictionary:
	var d = _defs.get(id)
	if d == null:
		return {"top": 0, "side": 0, "bottom": 0}
	return {"top": d.top, "side": d.side, "bottom": d.bottom}

static func get_required_tool(id: int) -> Dictionary:
	var d = _defs.get(id)
	if d == null:
		return {"type": ToolType.NONE, "tier": ToolTier.HAND}
	return {"type": d.tool_type, "tier": d.tool_tier}

static func all_ids() -> Array:
	return _defs.keys()

static func tile_to_uv(tile: int) -> Vector2:
	var x := float(tile % ATLAS_COLS) / float(ATLAS_COLS)
	var y := float(tile / ATLAS_COLS) / float(ATLAS_ROWS)
	return Vector2(x, y)

static func tile_size_uv() -> Vector2:
	return Vector2(1.0 / ATLAS_COLS, 1.0 / ATLAS_ROWS)
