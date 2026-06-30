# QuackCraft - Item registry
# Items are distinct from blocks (e.g. tools, food, materials).
# Blocks are also items (their ID is the block ID).
extends Node

const B = preload("res://scripts/blocks/BlockRegistry.gd")

# Item ID space: blocks 0..255, items 256..511
const STICK := 256
const STRING_ITEM := 257
const FEATHER := 258
const LEATHER := 259
const BONE := 260
const SPARK_POWDER := 261
const GOO_BALL := 262
const PEARL := 263
const FLINT := 264
const COAL := 265
const IRON_INGOT := 266
const GOLD_INGOT := 267
const GEM := 268
const EMERALD := 269
const LAPIS_DUST := 270

# Tools (start at 300)
const WOOD_PICKAXE := 300
const STONE_PICKAXE := 301
const IRON_PICKAXE := 302
const GOLD_PICKAXE := 303
const GEM_PICKAXE := 304
const WOOD_AXE := 310
const STONE_AXE := 311
const IRON_AXE := 312
const GOLD_AXE := 313
const GEM_AXE := 314
const WOOD_SHOVEL := 320
const STONE_SHOVEL := 321
const IRON_SHOVEL := 322
const GOLD_SHOVEL := 323
const GEM_SHOVEL := 324
const WOOD_SWORD := 330
const STONE_SWORD := 331
const IRON_SWORD := 332
const GOLD_SWORD := 333
const GEM_SWORD := 334
const WOOD_HOE := 340
const STONE_HOE := 341
const IRON_HOE := 342
const GOLD_HOE := 343
const GEM_HOE := 344

# Bow + arrows + shield
const BOW := 360
const ARROW := 361
const SHIELD := 362

# Armor (start at 380)
const LEATHER_HELMET := 380
const LEATHER_CHESTPLATE := 381
const LEATHER_LEGGINGS := 382
const LEATHER_BOOTS := 383
const IRON_HELMET := 384
const IRON_CHESTPLATE := 385
const IRON_LEGGINGS := 386
const IRON_BOOTS := 387
const GOLD_HELMET := 388
const GOLD_CHESTPLATE := 389
const GOLD_LEGGINGS := 390
const GOLD_BOOTS := 391
const GEM_HELMET := 392
const GEM_CHESTPLATE := 393
const GEM_LEGGINGS := 394
const GEM_BOOTS := 395

# Food (start at 410)
const BREAD := 410
const COOKED_BEEF := 411
const COOKED_PORK := 412
const COOKED_CHICKEN := 413
const APPLE := 414
const CARROT := 415
const POTATO := 416
const BAKED_POTATO := 417
const MELON_SLICE := 418
const BERRIES := 419

# Buckets / misc
const BUCKET_EMPTY := 430
const BUCKET_WATER := 431
const BUCKET_LAVA := 432
const FLINT_AND_STEEL := 433
const COMPASS := 434
const MAP := 435
const CLOCK := 436

var _items := {}

func _ready() -> void:
        _register_all()

func _r(id, name, opts={}) -> void:
        _items[id] = {
                "id": id,
                "name": name,
                "stackable": opts.get("stackable", true),
                "max_stack": opts.get("max_stack", 64),
                "tool_type": opts.get("tool_type", B.ToolType.NONE),
                "tool_tier": opts.get("tool_tier", B.ToolTier.HAND),
                "damage": opts.get("damage", 1.0),
                "durability": opts.get("durability", 0),
                "food": opts.get("food", 0),
                "place_block": opts.get("place_block", -1),
                "icon_tile": opts.get("icon_tile", 0),
        }

func _register_all() -> void:
        # Materials
        _r(STICK, "stick", {"icon_tile": 200})
        _r(STRING_ITEM, "string", {"icon_tile": 201})
        _r(FEATHER, "feather", {"icon_tile": 202})
        _r(LEATHER, "leather", {"icon_tile": 203})
        _r(BONE, "bone", {"icon_tile": 204})
        _r(SPARK_POWDER, "spark_powder", {"icon_tile": 205})
        _r(GOO_BALL, "goo_ball", {"icon_tile": 206})
        _r(PEARL, "pearl", {"icon_tile": 207})
        _r(FLINT, "flint", {"icon_tile": 208})
        _r(COAL, "coal", {"icon_tile": 209})
        _r(IRON_INGOT, "iron_ingot", {"icon_tile": 210})
        _r(GOLD_INGOT, "gold_ingot", {"icon_tile": 211})
        _r(GEM, "gem", {"icon_tile": 212})
        _r(EMERALD, "emerald", {"icon_tile": 213})
        _r(LAPIS_DUST, "lapis_dust", {"icon_tile": 214})

        # Pickaxes
        _r(WOOD_PICKAXE, "wood_pickaxe", {"tool_type": B.ToolType.PICKAXE, "tool_tier": B.ToolTier.WOOD, "damage": 2.0, "durability": 60, "stackable": false, "icon_tile": 220})
        _r(STONE_PICKAXE, "stone_pickaxe", {"tool_type": B.ToolType.PICKAXE, "tool_tier": B.ToolTier.STONE, "damage": 3.0, "durability": 130, "stackable": false, "icon_tile": 221})
        _r(IRON_PICKAXE, "iron_pickaxe", {"tool_type": B.ToolType.PICKAXE, "tool_tier": B.ToolTier.IRON, "damage": 4.0, "durability": 250, "stackable": false, "icon_tile": 222})
        _r(GOLD_PICKAXE, "gold_pickaxe", {"tool_type": B.ToolType.PICKAXE, "tool_tier": B.ToolTier.GOLD, "damage": 3.0, "durability": 80, "stackable": false, "icon_tile": 223})
        _r(GEM_PICKAXE, "gem_pickaxe", {"tool_type": B.ToolType.PICKAXE, "tool_tier": B.ToolTier.GEM, "damage": 6.0, "durability": 1500, "stackable": false, "icon_tile": 224})

        # Axes
        _r(WOOD_AXE, "wood_axe", {"tool_type": B.ToolType.AXE, "tool_tier": B.ToolTier.WOOD, "damage": 3.0, "durability": 60, "stackable": false, "icon_tile": 225})
        _r(STONE_AXE, "stone_axe", {"tool_type": B.ToolType.AXE, "tool_tier": B.ToolTier.STONE, "damage": 4.0, "durability": 130, "stackable": false, "icon_tile": 226})
        _r(IRON_AXE, "iron_axe", {"tool_type": B.ToolType.AXE, "tool_tier": B.ToolTier.IRON, "damage": 5.0, "durability": 250, "stackable": false, "icon_tile": 227})
        _r(GOLD_AXE, "gold_axe", {"tool_type": B.ToolType.AXE, "tool_tier": B.ToolTier.GOLD, "damage": 4.0, "durability": 80, "stackable": false, "icon_tile": 228})
        _r(GEM_AXE, "gem_axe", {"tool_type": B.ToolType.AXE, "tool_tier": B.ToolTier.GEM, "damage": 8.0, "durability": 1500, "stackable": false, "icon_tile": 229})

        # Shovels
        _r(WOOD_SHOVEL, "wood_shovel", {"tool_type": B.ToolType.SHOVEL, "tool_tier": B.ToolTier.WOOD, "damage": 1.5, "durability": 60, "stackable": false, "icon_tile": 230})
        _r(STONE_SHOVEL, "stone_shovel", {"tool_type": B.ToolType.SHOVEL, "tool_tier": B.ToolTier.STONE, "damage": 2.0, "durability": 130, "stackable": false, "icon_tile": 231})
        _r(IRON_SHOVEL, "iron_shovel", {"tool_type": B.ToolType.SHOVEL, "tool_tier": B.ToolTier.IRON, "damage": 3.0, "durability": 250, "stackable": false, "icon_tile": 232})
        _r(GOLD_SHOVEL, "gold_shovel", {"tool_type": B.ToolType.SHOVEL, "tool_tier": B.ToolTier.GOLD, "damage": 2.0, "durability": 80, "stackable": false, "icon_tile": 233})
        _r(GEM_SHOVEL, "gem_shovel", {"tool_type": B.ToolType.SHOVEL, "tool_tier": B.ToolTier.GEM, "damage": 4.0, "durability": 1500, "stackable": false, "icon_tile": 234})

        # Swords
        _r(WOOD_SWORD, "wood_sword", {"tool_type": B.ToolType.SWORD, "tool_tier": B.ToolTier.WOOD, "damage": 4.0, "durability": 60, "stackable": false, "icon_tile": 235})
        _r(STONE_SWORD, "stone_sword", {"tool_type": B.ToolType.SWORD, "tool_tier": B.ToolTier.STONE, "damage": 5.0, "durability": 130, "stackable": false, "icon_tile": 236})
        _r(IRON_SWORD, "iron_sword", {"tool_type": B.ToolType.SWORD, "tool_tier": B.ToolTier.IRON, "damage": 6.0, "durability": 250, "stackable": false, "icon_tile": 237})
        _r(GOLD_SWORD, "gold_sword", {"tool_type": B.ToolType.SWORD, "tool_tier": B.ToolTier.GOLD, "damage": 5.0, "durability": 80, "stackable": false, "icon_tile": 238})
        _r(GEM_SWORD, "gem_sword", {"tool_type": B.ToolType.SWORD, "tool_tier": B.ToolTier.GEM, "damage": 9.0, "durability": 1500, "stackable": false, "icon_tile": 239})

        # Hoes
        _r(WOOD_HOE, "wood_hoe", {"tool_type": B.ToolType.HOE, "tool_tier": B.ToolTier.WOOD, "damage": 1.0, "durability": 60, "stackable": false, "icon_tile": 240})
        _r(STONE_HOE, "stone_hoe", {"tool_type": B.ToolType.HOE, "tool_tier": B.ToolTier.STONE, "damage": 1.0, "durability": 130, "stackable": false, "icon_tile": 241})
        _r(IRON_HOE, "iron_hoe", {"tool_type": B.ToolType.HOE, "tool_tier": B.ToolTier.IRON, "damage": 1.0, "durability": 250, "stackable": false, "icon_tile": 242})
        _r(GOLD_HOE, "gold_hoe", {"tool_type": B.ToolType.HOE, "tool_tier": B.ToolTier.GOLD, "damage": 1.0, "durability": 80, "stackable": false, "icon_tile": 243})
        _r(GEM_HOE, "gem_hoe", {"tool_type": B.ToolType.HOE, "tool_tier": B.ToolTier.GEM, "damage": 1.0, "durability": 1500, "stackable": false, "icon_tile": 244})

        # Bow + Arrow + Shield
        _r(BOW, "bow", {"stackable": false, "damage": 1.0, "icon_tile": 250})
        _r(ARROW, "arrow", {"max_stack": 64, "icon_tile": 251})
        _r(SHIELD, "shield", {"stackable": false, "icon_tile": 252})

        # Armor
        _r(LEATHER_HELMET, "leather_helmet", {"stackable": false, "icon_tile": 260})
        _r(LEATHER_CHESTPLATE, "leather_chestplate", {"stackable": false, "icon_tile": 261})
        _r(LEATHER_LEGGINGS, "leather_leggings", {"stackable": false, "icon_tile": 262})
        _r(LEATHER_BOOTS, "leather_boots", {"stackable": false, "icon_tile": 263})
        _r(IRON_HELMET, "iron_helmet", {"stackable": false, "icon_tile": 264})
        _r(IRON_CHESTPLATE, "iron_chestplate", {"stackable": false, "icon_tile": 265})
        _r(IRON_LEGGINGS, "iron_leggings", {"stackable": false, "icon_tile": 266})
        _r(IRON_BOOTS, "iron_boots", {"stackable": false, "icon_tile": 267})
        _r(GOLD_HELMET, "gold_helmet", {"stackable": false, "icon_tile": 268})
        _r(GOLD_CHESTPLATE, "gold_chestplate", {"stackable": false, "icon_tile": 269})
        _r(GOLD_LEGGINGS, "gold_leggings", {"stackable": false, "icon_tile": 270})
        _r(GOLD_BOOTS, "gold_boots", {"stackable": false, "icon_tile": 271})
        _r(GEM_HELMET, "gem_helmet", {"stackable": false, "icon_tile": 272})
        _r(GEM_CHESTPLATE, "gem_chestplate", {"stackable": false, "icon_tile": 273})
        _r(GEM_LEGGINGS, "gem_leggings", {"stackable": false, "icon_tile": 274})
        _r(GEM_BOOTS, "gem_boots", {"stackable": false, "icon_tile": 275})

        # Food
        _r(BREAD, "bread", {"food": 6, "icon_tile": 280})
        _r(COOKED_BEEF, "cooked_beef", {"food": 8, "icon_tile": 281})
        _r(COOKED_PORK, "cooked_pork", {"food": 7, "icon_tile": 282})
        _r(COOKED_CHICKEN, "cooked_chicken", {"food": 6, "icon_tile": 283})
        _r(APPLE, "apple", {"food": 4, "icon_tile": 284})
        _r(CARROT, "carrot", {"food": 3, "icon_tile": 285})
        _r(POTATO, "potato", {"food": 1, "icon_tile": 286})
        _r(BAKED_POTATO, "baked_potato", {"food": 5, "icon_tile": 287})
        _r(MELON_SLICE, "melon_slice", {"food": 2, "icon_tile": 288})
        _r(BERRIES, "berries", {"food": 2, "icon_tile": 289})

        # Buckets etc.
        _r(BUCKET_EMPTY, "bucket_empty", {"stackable": true, "max_stack": 16, "icon_tile": 300})
        _r(BUCKET_WATER, "bucket_water", {"stackable": false, "place_block": B.WATER, "icon_tile": 301})
        _r(BUCKET_LAVA, "bucket_lava", {"stackable": false, "place_block": B.LAVA, "icon_tile": 302})
        _r(FLINT_AND_STEEL, "flint_and_steel", {"stackable": false, "icon_tile": 303})
        _r(COMPASS, "compass", {"stackable": false, "icon_tile": 304})
        _r(MAP, "map", {"stackable": false, "icon_tile": 305})
        _r(CLOCK, "clock", {"stackable": false, "icon_tile": 306})

func get_item(id: int) -> Dictionary:
        if _items.has(id):
                return _items[id]
        # Blocks themselves are valid items
        if B.get_def(id).size() > 0:
                return {"id": id, "name": B.get_block_name(id), "stackable": true, "max_stack": 64, "icon_tile": B.get_tiles(id).side}
        return {}

func get_item_name(id: int) -> String:
        var d := get_item(id)
        return d.get("name", "unknown")

func is_food(id: int) -> bool:
        var d := get_item(id)
        return d.get("food", 0) > 0

# Block drops: by default a block drops itself; ores drop their mineral.
func get_block_drop(block_id: int) -> int:
        match block_id:
                B.COAL_ORE: return COAL
                B.IRON_ORE: return IRON_INGOT # simplified: drops ingot directly
                B.GOLD_ORE: return GOLD_INGOT
                B.GEM_ORE: return GEM
                B.EMERALD_ORE: return EMERALD
                B.LAPIS_ORE: return LAPIS_DUST
                B.SPARK_ORE: return SPARK_POWDER
                B.STONE: return B.COBBLESTONE
                B.GRASS: return B.DIRT
                B.LEAVES, B.OAK_LEAVES, B.BIRCH_LEAVES, B.SPRUCE_LEAVES, B.JUNGLE_LEAVES, B.ACACIA_LEAVES, B.DARK_OAK_LEAVES:
                        # Sometimes drops a sapling (simplified: just leaves itself for decoration items)
                        return B.AIR if randf() < 0.9 else B.OAK_SAPLING
                B.ICE: return B.AIR
                B.GLASS: return B.AIR
                _:
                        return block_id

# Crafting recipes: returns list of {output_id, count, pattern (array of 9 ints or null)}
# Pattern is 3x3 row-major, with -1 meaning empty.
func get_recipes() -> Array:
        return [
                # Planks from logs (1 log -> 4 planks)
                {"out": B.OAK_PLANKS, "count": 4, "pattern": [-1,-1,-1, -1,B.OAK_LOG,-1, -1,-1,-1]},
                {"out": B.BIRCH_PLANKS, "count": 4, "pattern": [-1,-1,-1, -1,B.BIRCH_LOG,-1, -1,-1,-1]},
                {"out": B.SPRUCE_PLANKS, "count": 4, "pattern": [-1,-1,-1, -1,B.SPRUCE_LOG,-1, -1,-1,-1]},
                {"out": B.JUNGLE_PLANKS, "count": 4, "pattern": [-1,-1,-1, -1,B.JUNGLE_LOG,-1, -1,-1,-1]},
                {"out": B.ACACIA_PLANKS, "count": 4, "pattern": [-1,-1,-1, -1,B.ACACIA_LOG,-1, -1,-1,-1]},
                {"out": B.DARK_OAK_PLANKS, "count": 4, "pattern": [-1,-1,-1, -1,B.DARK_OAK_LOG,-1, -1,-1,-1]},
                # Sticks (2 planks -> 4 sticks)
                {"out": STICK, "count": 4, "pattern": [-1,-1,-1, -1,B.OAK_PLANKS,-1, -1,B.OAK_PLANKS,-1]},
                # Crafting table (4 planks -> 1)
                {"out": B.CRAFTING_TABLE, "count": 1, "pattern": [B.OAK_PLANKS,B.OAK_PLANKS,-1, B.OAK_PLANKS,B.OAK_PLANKS,-1, -1,-1,-1]},
                # Furnace (8 cobblestone -> 1)
                {"out": B.FURNACE, "count": 1, "pattern": [B.COBBLESTONE,B.COBBLESTONE,B.COBBLESTONE, B.COBBLESTONE,-1,B.COBBLESTONE, B.COBBLESTONE,B.COBBLESTONE,B.COBBLESTONE]},
                # Chest (8 planks)
                {"out": B.CHEST, "count": 1, "pattern": [B.OAK_PLANKS,B.OAK_PLANKS,B.OAK_PLANKS, B.OAK_PLANKS,-1,B.OAK_PLANKS, B.OAK_PLANKS,B.OAK_PLANKS,B.OAK_PLANKS]},
                # Torch (1 coal + 1 stick -> 4 torches)
                {"out": B.TORCH, "count": 4, "pattern": [-1,-1,-1, -1,COAL,-1, -1,STICK,-1]},
                # Wood pickaxe
                {"out": WOOD_PICKAXE, "count": 1, "pattern": [B.OAK_PLANKS,B.OAK_PLANKS,B.OAK_PLANKS, -1,STICK,-1, -1,STICK,-1]},
                # Stone pickaxe
                {"out": STONE_PICKAXE, "count": 1, "pattern": [B.COBBLESTONE,B.COBBLESTONE,B.COBBLESTONE, -1,STICK,-1, -1,STICK,-1]},
                # Iron pickaxe
                {"out": IRON_PICKAXE, "count": 1, "pattern": [IRON_INGOT,IRON_INGOT,IRON_INGOT, -1,STICK,-1, -1,STICK,-1]},
                # Wood sword
                {"out": WOOD_SWORD, "count": 1, "pattern": [-1,B.OAK_PLANKS,-1, -1,B.OAK_PLANKS,-1, -1,STICK,-1]},
                # Iron sword
                {"out": IRON_SWORD, "count": 1, "pattern": [-1,IRON_INGOT,-1, -1,IRON_INGOT,-1, -1,STICK,-1]},
                # Gem sword
                {"out": GEM_SWORD, "count": 1, "pattern": [-1,GEM,-1, -1,GEM,-1, -1,STICK,-1]},
                # Wood axe
                {"out": WOOD_AXE, "count": 1, "pattern": [B.OAK_PLANKS,B.OAK_PLANKS,-1, B.OAK_PLANKS,STICK,-1, -1,STICK,-1]},
                # Iron axe
                {"out": IRON_AXE, "count": 1, "pattern": [IRON_INGOT,IRON_INGOT,-1, IRON_INGOT,STICK,-1, -1,STICK,-1]},
                # Wood shovel
                {"out": WOOD_SHOVEL, "count": 1, "pattern": [-1,B.OAK_PLANKS,-1, -1,STICK,-1, -1,STICK,-1]},
                # Bricks (4 clay -> 4 bricks block) simplified
                {"out": B.BRICKS, "count": 4, "pattern": [B.CLAY,B.CLAY,-1, B.CLAY,B.CLAY,-1, -1,-1,-1]},
                # Glass (smelt sand — but allow crafting from 1 sand in 2x2 to get glass for v1)
                # Actually only obtainable via furnace — skip
                # Bread (3 wheat) - simplified, skip wheat; allow bread from 1 reed + 1 reed + 1 reed
                {"out": BREAD, "count": 1, "pattern": [-1,-1,-1, B.REED,B.REED,B.REED, -1,-1,-1]},
        ]
