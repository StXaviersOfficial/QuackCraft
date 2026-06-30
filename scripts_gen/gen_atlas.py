#!/usr/bin/env python3
"""
QuackCraft - Texture Atlas Generator
Generates a 256x256 PNG atlas of 16x16 tiles (16x16 grid of tiles).
All artwork is original (not derived from any existing game's assets).
"""
import os
from PIL import Image, ImageDraw, ImageFilter
import random

random.seed(1337)

ATLAS_COLS = 16
ATLAS_ROWS = 16
TILE_SIZE = 16
ATLAS_W = ATLAS_COLS * TILE_SIZE  # 256
ATLAS_H = ATLAS_ROWS * TILE_SIZE

# Color palette
COL = {
    'air': (0, 0, 0, 0),
    'grass_top': (108, 158, 76),
    'grass_side': (134, 96, 67),
    'grass_overlay': (124, 178, 82),
    'dirt': (134, 96, 67),
    'dirt_dark': (108, 78, 53),
    'stone': (130, 130, 130),
    'stone_dark': (100, 100, 100),
    'cobble': (110, 110, 110),
    'cobble_dark': (75, 75, 75),
    'sand': (218, 200, 138),
    'sand_dark': (190, 170, 110),
    'gravel': (135, 125, 118),
    'gravel_dark': (95, 88, 82),
    'clay': (165, 165, 175),
    'clay_dark': (135, 135, 145),
    'snow': (245, 248, 252),
    'snow_dark': (215, 220, 228),
    'ice': (155, 195, 230, 200),
    'ice_dark': (120, 165, 215, 200),
    'sandstone': (200, 180, 120),
    'sandstone_dark': (170, 150, 90),
    'bedrock': (50, 50, 50),
    'bedrock_dark': (30, 30, 30),
    'mycel': (105, 95, 105),
    'mycel_dark': (85, 75, 85),
    'coal_ore': (110, 110, 110),
    'coal_spot': (30, 30, 30),
    'iron_ore': (130, 130, 130),
    'iron_spot': (200, 165, 130),
    'gold_ore': (130, 130, 130),
    'gold_spot': (235, 200, 70),
    'gem_ore': (110, 110, 110),
    'gem_spot': (95, 230, 215),
    'emerald_ore': (120, 120, 120),
    'emerald_spot': (60, 210, 110),
    'lapis_ore': (120, 120, 130),
    'lapis_spot': (40, 70, 180),
    'spark_ore': (110, 110, 110),
    'spark_spot': (220, 60, 50),
    'log_top_oak': (180, 140, 90),
    'log_top_oak_dark': (150, 115, 70),
    'log_side_oak': (110, 80, 50),
    'log_side_oak_dark': (80, 55, 35),
    'planks_oak': (170, 130, 80),
    'planks_oak_dark': (140, 105, 65),
    'leaves_oak': (62, 120, 35),
    'leaves_oak_dark': (45, 90, 25),
    'sapling_oak': (75, 130, 45),
    'log_side_birch': (220, 215, 200),
    'log_side_birch_dark': (160, 155, 145),
    'planks_birch': (200, 180, 150),
    'leaves_birch': (90, 140, 60),
    'sapling_birch': (90, 140, 60),
    'log_side_spruce': (75, 55, 35),
    'planks_spruce': (95, 70, 45),
    'leaves_spruce': (40, 80, 30),
    'sapling_spruce': (55, 95, 35),
    'log_side_jungle': (85, 60, 35),
    'planks_jungle': (110, 80, 45),
    'leaves_jungle': (50, 110, 35),
    'sapling_jungle': (65, 120, 40),
    'log_side_acacia': (130, 85, 45),
    'planks_acacia': (155, 105, 60),
    'leaves_acacia': (75, 130, 45),
    'sapling_acacia': (85, 130, 45),
    'log_side_dark_oak': (55, 40, 25),
    'planks_dark_oak': (70, 50, 30),
    'leaves_dark_oak': (45, 75, 30),
    'sapling_dark_oak': (55, 90, 30),
    'water': (60, 110, 200, 180),
    'water_dark': (40, 80, 160, 180),
    'lava': (230, 95, 25),
    'lava_dark': (190, 65, 20),
    'lava_bright': (255, 200, 80),
    'bricks': (150, 75, 65),
    'bricks_dark': (115, 55, 45),
    'bricks_mortar': (200, 195, 185),
    'stone_bricks': (110, 110, 110),
    'stone_bricks_dark': (80, 80, 80),
    'glass': (200, 230, 240, 100),
    'glass_border': (220, 240, 250, 200),
    'wool_white': (235, 235, 235),
    'wool_red': (165, 50, 45),
    'wool_green': (90, 130, 50),
    'wool_blue': (60, 80, 165),
    'wool_yellow': (200, 175, 40),
    'wool_black': (25, 25, 25),
    'wool_gray': (70, 70, 75),
    'wool_brown': (105, 75, 50),
    'wool_pink': (220, 130, 165),
    'wool_cyan': (75, 130, 150),
    'wool_magenta': (175, 70, 165),
    'wool_orange': (210, 110, 40),
    'wool_lime': (105, 175, 50),
    'wool_purple': (115, 55, 130),
    'terracotta': (160, 100, 80),
    'terracotta_white': (210, 195, 180),
    'terracotta_red': (150, 70, 60),
    'terracotta_orange': (165, 95, 50),
    'terracotta_yellow': (170, 145, 70),
    'terracotta_green': (90, 110, 70),
    'terracotta_blue': (75, 90, 120),
    'terracotta_purple': (105, 75, 105),
    'terracotta_pink': (170, 110, 110),
    'terracotta_brown': (100, 75, 55),
    'terracotta_cyan': (85, 105, 105),
    'terracotta_gray': (75, 70, 75),
    'terracotta_black': (40, 35, 40),
    'terracotta_magenta': (130, 75, 110),
    'terracotta_lime': (100, 120, 65),
    'bookshelf_top': (170, 130, 80),
    'bookshelf_books_red': (155, 55, 50),
    'bookshelf_books_blue': (60, 80, 130),
    'bookshelf_books_green': (75, 110, 55),
    'bookshelf_books_yellow': (190, 165, 50),
    'hay': (200, 170, 70),
    'hay_dark': (165, 135, 50),
    'ladder': (130, 95, 55),
    'ladder_dark': (90, 65, 40),
    'crafting_top': (155, 115, 70),
    'crafting_top_dark': (115, 85, 50),
    'furnace_front': (90, 90, 90),
    'furnace_front_lit': (240, 140, 50),
    'furnace_side': (110, 110, 110),
    'chest_front': (170, 130, 80),
    'chest_side': (160, 120, 70),
    'chest_top': (180, 140, 90),
    'door_top': (160, 110, 60),
    'door_bottom': (150, 100, 55),
    'trapdoor': (130, 90, 50),
    'bed_top': (190, 60, 70),
    'bed_top_pillow': (230, 230, 230),
    'torch_handle': (95, 70, 40),
    'torch_flame': (245, 195, 70),
    'torch_flame_hot': (255, 240, 140),
    'rune_altar': (50, 35, 65),
    'rune_altar_glow': (130, 90, 220),
    'brew_stand': (70, 70, 75),
    'brew_stand_glow': (130, 220, 90),
    'tall_grass': (105, 145, 60),
    'tall_grass_dark': (75, 110, 40),
    'flower_red_petal': (210, 50, 55),
    'flower_red_stem': (60, 110, 40),
    'flower_yellow_petal': (230, 200, 60),
    'flower_yellow_stem': (60, 110, 40),
    'flower_white_petal': (235, 235, 240),
    'flower_white_stem': (60, 110, 40),
    'flower_purple_petal': (155, 90, 200),
    'flower_purple_stem': (60, 110, 40),
    'flower_pink_petal': (220, 130, 165),
    'flower_pink_stem': (60, 110, 40),
    'flower_blue_petal': (90, 130, 210),
    'flower_blue_stem': (60, 110, 40),
    'mushroom_red_cap': (185, 55, 50),
    'mushroom_red_stem': (225, 220, 200),
    'mushroom_brown_cap': (130, 90, 60),
    'mushroom_brown_stem': (220, 215, 195),
    'cactus': (85, 130, 60),
    'cactus_dark': (60, 100, 40),
    'reed': (165, 175, 95),
    'reed_dark': (135, 145, 75),
    'vines': (55, 100, 40),
    'lily_pad': (75, 130, 55),
    'lily_pad_dark': (55, 100, 40),
    'snow_layer': (245, 248, 252),
}

# Item icons (16x16, rendered as a centered icon)
ITEM_COL = {
    'stick': (110, 80, 50),
    'string': (220, 215, 200),
    'feather': (230, 230, 230),
    'leather': (130, 90, 60),
    'bone': (235, 230, 215),
    'spark_powder': (220, 60, 50),
    'goo_ball': (140, 220, 120),
    'pearl': (235, 240, 245),
    'flint': (50, 50, 55),
    'coal': (30, 30, 30),
    'iron_ingot': (220, 215, 210),
    'gold_ingot': (240, 205, 70),
    'gem': (95, 230, 215),
    'emerald': (60, 210, 110),
    'lapis_dust': (40, 70, 180),
    'tool_wood': (160, 115, 70),
    'tool_stone': (130, 130, 130),
    'tool_iron': (220, 215, 210),
    'tool_gold': (240, 205, 70),
    'tool_gem': (95, 230, 215),
    'bow_wood': (160, 115, 70),
    'bow_string': (230, 230, 230),
    'arrow_shaft': (160, 115, 70),
    'arrow_head': (130, 130, 130),
    'arrow_fletch': (230, 230, 230),
    'shield': (160, 115, 70),
    'shield_boss': (220, 215, 210),
    'armor_leather': (130, 90, 60),
    'armor_iron': (220, 215, 210),
    'armor_gold': (240, 205, 70),
    'armor_gem': (95, 230, 215),
    'bread': (190, 145, 80),
    'cooked_beef': (140, 90, 60),
    'cooked_pork': (200, 130, 130),
    'cooked_chicken': (220, 195, 165),
    'apple': (200, 50, 50),
    'carrot': (230, 130, 50),
    'potato': (200, 175, 130),
    'baked_potato': (155, 115, 65),
    'melon_slice': (200, 70, 70),
    'berries': (140, 50, 80),
    'bucket': (180, 180, 185),
    'bucket_water': (60, 110, 200),
    'bucket_lava': (230, 95, 25),
    'flint_and_steel': (50, 50, 55),
    'compass': (220, 215, 210),
    'map': (220, 200, 160),
    'clock': (220, 215, 210),
}


def make_atlas():
    atlas = Image.new('RGBA', (ATLAS_W, ATLAS_H), (0, 0, 0, 0))
    return atlas


def noise_fill(img, base_color, variation=20, seed_offset=0):
    """Fill image with base color plus per-pixel brightness variation."""
    px = img.load()
    rng = random.Random(seed_offset)
    if len(base_color) == 3:
        r, g, b = base_color
        a = 255
    else:
        r, g, b, a = base_color
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            v = rng.randint(-variation, variation)
            r2 = max(0, min(255, r + v))
            g2 = max(0, min(255, g + v))
            b2 = max(0, min(255, b + v))
            px[x, y] = (r2, g2, b2, a)


def add_specks(img, color, count=20, seed_offset=0):
    """Randomly scatter specks of color."""
    d = ImageDraw.Draw(img)
    rng = random.Random(seed_offset)
    for _ in range(count):
        x = rng.randint(0, TILE_SIZE - 1)
        y = rng.randint(0, TILE_SIZE - 1)
        d.point((x, y), fill=color)


def paste_tile(atlas, tile_idx, tile_img):
    """Paste a 16x16 tile into the atlas at tile_idx."""
    tx = tile_idx % ATLAS_COLS
    ty = tile_idx // ATLAS_COLS
    atlas.paste(tile_img, (tx * TILE_SIZE, ty * TILE_SIZE))


def make_tile(idx, draw_fn):
    img = Image.new('RGBA', (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0))
    draw_fn(img, idx)
    return img


def draw_grass_top(img, idx):
    noise_fill(img, COL['grass_top'], 15, idx)
    add_specks(img, COL['grass_overlay'], 8, idx + 1)


def draw_grass_side(img, idx):
    noise_fill(img, COL['dirt'], 12, idx)
    # Grass overlay on top 4 pixels
    px = img.load()
    rng = random.Random(idx + 100)
    for y in range(4):
        for x in range(TILE_SIZE):
            if rng.random() < 0.7 or y < 3:
                v = rng.randint(-10, 10)
                c = COL['grass_overlay']
                px[x, y] = (max(0, min(255, c[0] + v)), max(0, min(255, c[1] + v)), max(0, min(255, c[2] + v)), 255)


def draw_dirt(img, idx):
    noise_fill(img, COL['dirt'], 12, idx)
    add_specks(img, COL['dirt_dark'], 12, idx + 1)


def draw_stone(img, idx):
    noise_fill(img, COL['stone'], 10, idx)
    add_specks(img, COL['stone_dark'], 8, idx + 1)


def draw_cobble(img, idx):
    noise_fill(img, COL['cobble_dark'], 8, idx)
    # Draw cobble stones as bumps
    d = ImageDraw.Draw(img)
    rng = random.Random(idx + 2)
    for _ in range(7):
        x = rng.randint(0, TILE_SIZE - 4)
        y = rng.randint(0, TILE_SIZE - 4)
        w = rng.randint(3, 5)
        h = rng.randint(3, 5)
        for dy in range(h):
            for dx in range(w):
                if 0 <= x + dx < TILE_SIZE and 0 <= y + dy < TILE_SIZE:
                    v = rng.randint(-5, 10)
                    c = COL['cobble']
                    img.putpixel((x + dx, y + dy), (c[0] + v, c[1] + v, c[2] + v, 255))


def draw_sand(img, idx):
    noise_fill(img, COL['sand'], 8, idx)
    add_specks(img, COL['sand_dark'], 10, idx + 1)


def draw_gravel(img, idx):
    noise_fill(img, COL['gravel'], 10, idx)
    add_specks(img, COL['gravel_dark'], 18, idx + 1)


def draw_clay(img, idx):
    noise_fill(img, COL['clay'], 6, idx)
    add_specks(img, COL['clay_dark'], 6, idx + 1)


def draw_snow(img, idx):
    noise_fill(img, COL['snow'], 5, idx)
    add_specks(img, COL['snow_dark'], 4, idx + 1)


def draw_ice(img, idx):
    noise_fill(img, COL['ice'], 10, idx)
    add_specks(img, COL['ice_dark'], 6, idx + 1)


def draw_sandstone(img, idx):
    noise_fill(img, COL['sandstone'], 8, idx)
    d = ImageDraw.Draw(img)
    d.line([(0, 4), (15, 4)], fill=COL['sandstone_dark'], width=1)
    d.line([(0, 11), (15, 11)], fill=COL['sandstone_dark'], width=1)


def draw_bedrock(img, idx):
    noise_fill(img, COL['bedrock'], 10, idx)
    add_specks(img, COL['bedrock_dark'], 15, idx + 1)


def draw_mycel(img, idx):
    noise_fill(img, COL['mycel'], 8, idx)
    add_specks(img, COL['mycel_dark'], 10, idx + 1)


def draw_ore(img, idx, base, spot):
    noise_fill(img, base, 10, idx)
    rng = random.Random(idx + 5)
    for _ in range(8):
        x = rng.randint(1, TILE_SIZE - 3)
        y = rng.randint(1, TILE_SIZE - 3)
        s = rng.randint(2, 3)
        for dy in range(s):
            for dx in range(s):
                v = rng.randint(-15, 5)
                img.putpixel((min(x + dx, TILE_SIZE - 1), min(y + dy, TILE_SIZE - 1)),
                             (max(0, min(255, spot[0] + v)),
                              max(0, min(255, spot[1] + v)),
                              max(0, min(255, spot[2] + v)),
                              spot[3] if len(spot) > 3 else 255))


def draw_log_top(img, idx, base, dark):
    noise_fill(img, base, 8, idx)
    # Concentric rings
    d = ImageDraw.Draw(img)
    d.ellipse([(4, 4), (11, 11)], outline=dark, width=1)
    d.ellipse([(6, 6), (9, 9)], outline=dark, width=1)


def draw_log_side(img, idx, base, dark, bark_streaks=True):
    noise_fill(img, base, 10, idx)
    if bark_streaks:
        px = img.load()
        rng = random.Random(idx + 7)
        for y in range(TILE_SIZE):
            for x in range(TILE_SIZE):
                if rng.random() < 0.15:
                    v = rng.randint(-25, -10)
                    r, g, b, a = px[x, y]
                    px[x, y] = (max(0, r + v), max(0, g + v), max(0, b + v), 255)


def draw_planks(img, idx, base, dark):
    noise_fill(img, base, 8, idx)
    d = ImageDraw.Draw(img)
    # Horizontal planks
    for y in [0, 4, 8, 12]:
        d.line([(0, y), (15, y)], fill=dark, width=1)
    # Vertical seams offset
    d.line([(7, 0), (7, 3)], fill=dark, width=1)
    d.line([(3, 4), (3, 7)], fill=dark, width=1)
    d.line([(11, 8), (11, 11)], fill=dark, width=1)
    d.line([(5, 12), (5, 15)], fill=dark, width=1)


def draw_leaves(img, idx, base, dark):
    noise_fill(img, base, 18, idx)
    add_specks(img, dark, 25, idx + 1)
    add_specks(img, base, 20, idx + 2)


def draw_sapling(img, idx, color):
    # Transparent background, small plant
    px = img.load()
    rng = random.Random(idx + 11)
    # Stem
    for y in range(8, 16):
        v = rng.randint(-10, 10)
        c = (60 + v, 100 + v, 40 + v, 255)
        px[7, y] = c
        px[8, y] = c
    # Leaves top
    for y in range(4, 9):
        for x in range(5, 11):
            if rng.random() < 0.6:
                v = rng.randint(-15, 10)
                px[x, y] = (max(0, min(255, color[0] + v)),
                            max(0, min(255, color[1] + v)),
                            max(0, min(255, color[2] + v)), 255)


def draw_water(img, idx):
    noise_fill(img, COL['water'], 8, idx)
    # Wavy ripple
    d = ImageDraw.Draw(img)
    d.line([(0, 5), (15, 5)], fill=COL['water_dark'], width=1)
    d.line([(0, 10), (15, 10)], fill=COL['water_dark'], width=1)


def draw_lava(img, idx):
    noise_fill(img, COL['lava'], 15, idx)
    add_specks(img, COL['lava_bright'], 12, idx + 1)
    add_specks(img, COL['lava_dark'], 8, idx + 2)


def draw_bricks(img, idx):
    noise_fill(img, COL['bricks'], 6, idx)
    d = ImageDraw.Draw(img)
    # Brick pattern: rows of 4px height, offset every other row
    for y in [0, 4, 8, 12]:
        d.line([(0, y), (15, y)], fill=COL['bricks_mortar'], width=1)
    # Vertical mortar, offset
    for y_start in [0, 8]:
        d.line([(7, y_start), (7, y_start + 3)], fill=COL['bricks_mortar'], width=1)
    for y_start in [4, 12]:
        d.line([(3, y_start), (3, y_start + 3)], fill=COL['bricks_mortar'], width=1)
        d.line([(11, y_start), (11, y_start + 3)], fill=COL['bricks_mortar'], width=1)


def draw_stone_bricks(img, idx):
    noise_fill(img, COL['stone_bricks'], 6, idx)
    d = ImageDraw.Draw(img)
    d.line([(0, 7), (15, 7)], fill=COL['stone_bricks_dark'], width=1)
    d.line([(7, 0), (7, 7)], fill=COL['stone_bricks_dark'], width=1)
    d.line([(3, 8), (3, 15)], fill=COL['stone_bricks_dark'], width=1)
    d.line([(11, 8), (11, 15)], fill=COL['stone_bricks_dark'], width=1)


def draw_glass(img, idx):
    # Mostly transparent, with a border
    px = img.load()
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            px[x, y] = COL['glass']
    d = ImageDraw.Draw(img)
    d.rectangle([(0, 0), (15, 15)], outline=COL['glass_border'], width=1)
    # A diagonal highlight streak
    d.line([(2, 12), (12, 2)], fill=(255, 255, 255, 220), width=1)


def draw_wool(img, idx, color=None):
    if color is None:
        color = (220, 220, 220, 255)
    base = color
    noise_fill(img, base, 8, idx)
    add_specks(img, (max(0, base[0] - 25), max(0, base[1] - 25), max(0, base[2] - 25), 255), 15, idx + 1)
    add_specks(img, (min(255, base[0] + 25), min(255, base[1] + 25), min(255, base[2] + 25), 255), 10, idx + 2)


def draw_terracotta(img, idx, color):
    noise_fill(img, color, 8, idx)
    d = ImageDraw.Draw(img)
    d.rectangle([(1, 1), (14, 14)], outline=(max(0, color[0] - 30), max(0, color[1] - 30), max(0, color[2] - 30), 255), width=1)


def draw_bookshelf(img, idx):
    # Top: planks; books in middle
    noise_fill(img, COL['planks_oak'], 6, idx)
    d = ImageDraw.Draw(img)
    d.rectangle([(0, 0), (15, 3)], fill=COL['planks_oak_dark'])
    d.rectangle([(0, 12), (15, 15)], fill=COL['planks_oak_dark'])
    books = [COL['bookshelf_books_red'], COL['bookshelf_books_blue'],
             COL['bookshelf_books_green'], COL['bookshelf_books_yellow']]
    rng = random.Random(idx + 3)
    x = 1
    while x < 15:
        c = rng.choice(books)
        w = rng.randint(1, 2)
        for y in range(4, 12):
            for dx in range(w):
                if x + dx < 15:
                    img.putpixel((x + dx, y), c)
        x += w + (1 if rng.random() < 0.3 else 0)


def draw_hay(img, idx):
    noise_fill(img, COL['hay'], 10, idx)
    d = ImageDraw.Draw(img)
    d.line([(0, 5), (15, 5)], fill=COL['hay_dark'], width=1)
    d.line([(0, 10), (15, 10)], fill=COL['hay_dark'], width=1)


def draw_ladder(img, idx):
    # Transparent background; wooden frame
    px = img.load()
    for x in [2, 3, 12, 13]:
        for y in range(TILE_SIZE):
            px[x, y] = COL['ladder']
    d = ImageDraw.Draw(img)
    for y in [3, 7, 11]:
        d.line([(2, y), (13, y)], fill=COL['ladder_dark'], width=1)


def draw_crafting(img, idx):
    noise_fill(img, COL['crafting_top'], 8, idx)
    d = ImageDraw.Draw(img)
    # Grid pattern
    d.line([(5, 0), (5, 15)], fill=COL['crafting_top_dark'], width=1)
    d.line([(10, 0), (10, 15)], fill=COL['crafting_top_dark'], width=1)
    d.line([(0, 5), (15, 5)], fill=COL['crafting_top_dark'], width=1)
    d.line([(0, 10), (15, 10)], fill=COL['crafting_top_dark'], width=1)


def draw_furnace_front(img, idx, lit=False):
    noise_fill(img, COL['furnace_side'], 6, idx)
    d = ImageDraw.Draw(img)
    # Opening (furnace mouth)
    d.rectangle([(4, 6), (11, 12)], fill=COL['furnace_front_lit'] if lit else (20, 20, 20, 255))


def draw_furnace_side(img, idx):
    noise_fill(img, COL['furnace_side'], 6, idx)
    add_specks(img, COL['stone_dark'], 6, idx + 1)


def draw_chest_front(img, idx):
    noise_fill(img, COL['chest_front'], 6, idx)
    d = ImageDraw.Draw(img)
    d.line([(0, 5), (15, 5)], fill=(110, 80, 50, 255), width=1)  # lid line
    d.rectangle([(7, 6), (8, 9)], fill=(80, 60, 30, 255))  # lock


def draw_chest_side(img, idx):
    noise_fill(img, COL['chest_side'], 6, idx)
    d = ImageDraw.Draw(img)
    d.line([(0, 5), (15, 5)], fill=(110, 80, 50, 255), width=1)


def draw_chest_top(img, idx):
    noise_fill(img, COL['chest_top'], 6, idx)
    d = ImageDraw.Draw(img)
    d.rectangle([(2, 2), (13, 13)], outline=(140, 100, 60, 255), width=1)


def draw_door(img, idx):
    px = img.load()
    # Wooden door, planks pattern
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            v = random.randint(-10, 10) if (y == 0 or y == 15) else 0
            px[x, y] = (max(0, min(255, 160 + v)),
                        max(0, min(255, 110 + v)),
                        max(0, min(255, 60 + v)), 255)
    d = ImageDraw.Draw(img)
    d.rectangle([(0, 0), (15, 15)], outline=(110, 75, 40, 255), width=1)
    d.rectangle([(3, 3), (12, 12)], outline=(110, 75, 40, 255), width=1)


def draw_trapdoor(img, idx):
    noise_fill(img, COL['trapdoor'], 8, idx)
    d = ImageDraw.Draw(img)
    d.rectangle([(0, 0), (15, 15)], outline=(95, 65, 35, 255), width=1)
    d.line([(0, 5), (15, 5)], fill=(95, 65, 35, 255), width=1)
    d.line([(0, 10), (15, 10)], fill=(95, 65, 35, 255), width=1)


def draw_bed_top(img, idx):
    noise_fill(img, COL['bed_top'], 6, idx)
    d = ImageDraw.Draw(img)
    d.rectangle([(2, 2), (13, 6)], fill=COL['bed_top_pillow'])
    d.rectangle([(0, 8), (15, 15)], outline=(140, 40, 50, 255), width=1)


def draw_torch(img, idx):
    px = img.load()
    # Transparent background
    # Handle (vertical stick)
    for y in range(7, 16):
        px[7, y] = COL['torch_handle']
        px[8, y] = COL['torch_handle']
    # Flame on top
    for y in range(2, 7):
        for x in range(6, 9):
            v = random.randint(-15, 15)
            px[x, y] = (max(0, min(255, 245 + v)),
                        max(0, min(255, 195 + v)),
                        max(0, min(255, 70 + v)), 255)
    # Hot center
    px[7, 4] = COL['torch_flame_hot']
    px[7, 5] = COL['torch_flame_hot']


def draw_rune_altar(img, idx):
    noise_fill(img, COL['rune_altar'], 8, idx)
    d = ImageDraw.Draw(img)
    d.ellipse([(3, 3), (12, 12)], outline=COL['rune_altar_glow'], width=1)
    d.point((7, 7), fill=COL['rune_altar_glow'])
    d.point((8, 8), fill=COL['rune_altar_glow'])


def draw_brew_stand(img, idx):
    noise_fill(img, COL['brew_stand'], 6, idx)
    d = ImageDraw.Draw(img)
    d.ellipse([(5, 2), (10, 7)], fill=COL['brew_stand_glow'])
    d.line([(7, 7), (7, 14)], fill=(50, 50, 55, 255), width=2)
    d.line([(3, 14), (12, 14)], fill=(50, 50, 55, 255), width=2)


def draw_cross_plant(img, idx, color, dark_color):
    px = img.load()
    rng = random.Random(idx + 200)
    # Diagonal cross of plant pixels
    for i in range(16):
        for j, (x, y) in enumerate([(i, i), (15 - i, i)]):
            if rng.random() < 0.55:
                v = rng.randint(-15, 10)
                px[x, y] = (max(0, min(255, color[0] + v)),
                            max(0, min(255, color[1] + v)),
                            max(0, min(255, color[2] + v)), 255)


def draw_tall_grass(img, idx):
    px = img.load()
    rng = random.Random(idx + 201)
    for x in range(3, 13):
        h = rng.randint(4, 9)
        for y in range(16 - h, 16):
            v = rng.randint(-15, 10)
            px[x, y] = (max(0, min(255, 105 + v)),
                        max(0, min(255, 145 + v)),
                        max(0, min(255, 60 + v)), 255)


def draw_flower(img, idx, petal_color, stem_color):
    px = img.load()
    # Stem
    for y in range(8, 16):
        px[7, y] = stem_color
        px[8, y] = stem_color
    # Petals (flower head)
    d = ImageDraw.Draw(img)
    d.ellipse([(4, 3), (11, 9)], fill=petal_color)
    d.point((7, 6), fill=(255, 230, 100, 255))
    d.point((8, 6), fill=(255, 230, 100, 255))


def draw_mushroom(img, idx, cap_color, stem_color):
    px = img.load()
    # Stem
    for y in range(8, 16):
        for x in range(6, 10):
            px[x, y] = stem_color
    # Cap
    d = ImageDraw.Draw(img)
    d.ellipse([(2, 1), (13, 9)], fill=cap_color)
    # Spots
    d.point((5, 4), fill=(255, 255, 255, 255))
    d.point((9, 5), fill=(255, 255, 255, 255))
    d.point((7, 3), fill=(255, 255, 255, 255))


def draw_cactus(img, idx):
    noise_fill(img, COL['cactus'], 10, idx)
    d = ImageDraw.Draw(img)
    d.rectangle([(0, 0), (15, 15)], outline=COL['cactus_dark'], width=1)
    d.line([(0, 4), (15, 4)], fill=COL['cactus_dark'], width=1)
    d.line([(0, 11), (15, 11)], fill=COL['cactus_dark'], width=1)


def draw_reed(img, idx):
    px = img.load()
    rng = random.Random(idx + 300)
    for x in range(3, 13):
        h = rng.randint(8, 14)
        for y in range(16 - h, 16):
            v = rng.randint(-10, 10)
            px[x, y] = (max(0, min(255, 165 + v)),
                        max(0, min(255, 175 + v)),
                        max(0, min(255, 95 + v)), 255)


def draw_vines(img, idx):
    px = img.load()
    rng = random.Random(idx + 400)
    for x in range(16):
        if rng.random() < 0.3:
            h = rng.randint(3, 9)
            for y in range(h):
                v = rng.randint(-10, 10)
                px[x, y] = (max(0, min(255, 55 + v)),
                            max(0, min(255, 100 + v)),
                            max(0, min(255, 40 + v)), 255)


def draw_lily_pad(img, idx):
    noise_fill(img, COL['lily_pad'], 8, idx)
    d = ImageDraw.Draw(img)
    # Hexagonal pad
    d.polygon([(8, 1), (14, 4), (14, 11), (8, 14), (2, 11), (2, 4)], fill=COL['lily_pad'])
    d.line([(8, 1), (8, 7)], fill=COL['lily_pad_dark'], width=1)


def draw_snow_layer(img, idx):
    # Top is snow, bottom is transparent
    px = img.load()
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            if y < 5:
                v = random.randint(-5, 5)
                px[x, y] = (245 + v, 248 + v, 252 + v, 255)
            else:
                px[x, y] = (0, 0, 0, 0)


# ---- Item icons (16x16, simplified) ----

def draw_item_icon(img, idx, base_color, shape='generic'):
    """Draw a generic item icon: small inset rectangle in the base color."""
    d = ImageDraw.Draw(img)
    if shape == 'tool':
        # Tool head + handle
        d.line([(3, 13), (10, 6)], fill=COL.get('planks_oak_dark', (90, 65, 40)), width=2)  # handle
        d.rectangle([(8, 2), (13, 7)], fill=base_color)  # head
    elif shape == 'pickaxe':
        d.line([(3, 13), (10, 6)], fill=(90, 65, 40), width=2)
        d.line([(6, 3), (13, 3)], fill=base_color, width=2)
    elif shape == 'axe':
        d.line([(3, 13), (10, 6)], fill=(90, 65, 40), width=2)
        d.polygon([(8, 2), (13, 4), (12, 8), (8, 7)], fill=base_color)
    elif shape == 'shovel':
        d.line([(3, 13), (10, 6)], fill=(90, 65, 40), width=2)
        d.rectangle([(8, 2), (12, 7)], fill=base_color)
    elif shape == 'sword':
        d.line([(3, 13), (9, 7)], fill=(90, 65, 40), width=2)  # handle
        d.line([(8, 8), (13, 3)], fill=base_color, width=2)  # blade
        d.line([(3, 13), (5, 14)], fill=(180, 130, 80), width=2)  # pommel
    elif shape == 'hoe':
        d.line([(3, 13), (10, 6)], fill=(90, 65, 40), width=2)
        d.line([(10, 5), (13, 5)], fill=base_color, width=2)
    elif shape == 'ingot':
        d.rectangle([(3, 6), (12, 9)], fill=base_color)
        d.rectangle([(4, 7), (11, 8)], fill=(min(255, base_color[0]+30), min(255, base_color[1]+30), min(255, base_color[2]+30), 255))
    elif shape == 'gem':
        d.polygon([(8, 2), (13, 7), (8, 13), (3, 7)], fill=base_color)
        d.line([(8, 2), (8, 13)], fill=(255, 255, 255, 150), width=1)
    elif shape == 'dust':
        for _ in range(20):
            x = random.randint(2, 13)
            y = random.randint(2, 13)
            img.putpixel((x, y), base_color)
    elif shape == 'stick':
        d.line([(3, 13), (13, 3)], fill=base_color, width=2)
    elif shape == 'bow':
        d.arc([(2, 2), (13, 13)], 200, 340, fill=base_color, width=2)
        d.line([(11, 2), (11, 13)], fill=(230, 230, 230, 255), width=1)
    elif shape == 'arrow':
        d.line([(3, 13), (12, 4)], fill=base_color, width=1)  # shaft
        d.polygon([(12, 4), (10, 4), (12, 6)], fill=(130, 130, 130, 255))  # head
        d.line([(3, 13), (5, 12)], fill=(230, 230, 230, 255))  # fletch
        d.line([(4, 13), (6, 12)], fill=(230, 230, 230, 255))
    elif shape == 'shield':
        d.polygon([(3, 3), (12, 3), (12, 9), (7, 13), (3, 9)], fill=base_color)
        d.ellipse([(6, 6), (9, 9)], fill=(220, 215, 210, 255))
    elif shape == 'armor':
        d.rectangle([(4, 3), (11, 12)], fill=base_color)
        d.rectangle([(5, 4), (10, 11)], fill=(min(255, base_color[0]+25), min(255, base_color[1]+25), min(255, base_color[2]+25), 255))
    elif shape == 'food':
        d.ellipse([(3, 5), (12, 12)], fill=base_color)
    elif shape == 'bread':
        d.ellipse([(3, 6), (12, 11)], fill=base_color)
        d.line([(4, 8), (11, 8)], fill=(130, 90, 50, 255), width=1)
    elif shape == 'apple':
        d.ellipse([(3, 5), (12, 13)], fill=base_color)
        d.line([(8, 4), (10, 2)], fill=(90, 60, 30, 255), width=1)
    elif shape == 'carrot':
        d.polygon([(8, 3), (5, 13), (11, 13)], fill=base_color)
        d.line([(8, 3), (8, 13)], fill=(60, 110, 40, 255), width=1)
    elif shape == 'potato':
        d.ellipse([(4, 5), (11, 11)], fill=base_color)
    elif shape == 'melon':
        d.ellipse([(3, 3), (12, 12)], fill=base_color)
        d.line([(3, 7), (12, 7)], fill=(40, 20, 20, 255), width=1)
    elif shape == 'berries':
        d.ellipse([(4, 4), (8, 8)], fill=base_color)
        d.ellipse([(8, 5), (12, 9)], fill=base_color)
        d.ellipse([(5, 8), (9, 12)], fill=base_color)
    elif shape == 'bucket':
        d.rectangle([(3, 4), (12, 12)], outline=base_color, width=2)
        d.line([(3, 5), (12, 5)], fill=base_color, width=1)
    elif shape == 'compass':
        d.ellipse([(3, 3), (12, 12)], outline=base_color, width=1)
        d.line([(7, 4), (8, 11)], fill=(200, 50, 50, 255), width=1)
    elif shape == 'map':
        d.rectangle([(2, 2), (13, 13)], fill=(220, 200, 160, 255))
        d.line([(2, 7), (13, 7)], fill=(180, 160, 120, 255), width=1)
        d.line([(7, 2), (7, 13)], fill=(180, 160, 120, 255), width=1)
    elif shape == 'clock':
        d.ellipse([(3, 3), (12, 12)], outline=base_color, width=2)
        d.line([(7, 7), (7, 4)], fill=base_color, width=1)
        d.line([(7, 7), (10, 7)], fill=base_color, width=1)
    elif shape == 'flint':
        d.polygon([(5, 5), (11, 4), (13, 10), (7, 12)], fill=base_color)
    else:
        d.rectangle([(3, 3), (12, 12)], fill=base_color)


def build_atlas():
    atlas = make_atlas()

    # Block tiles (16x16, indices 0..15 for terrain, 16..23 for ores,
    # 24..59 for wood variants, 60..61 for fluids, 64..120 for build/decor)

    # Terrain
    paste_tile(atlas, 0, make_tile(0, draw_grass_top))         # 0 grass top
    paste_tile(atlas, 1, make_tile(1, lambda img, idx: draw_wool(img, idx, (255, 200, 100, 255))))  # 1 (unused reserve)
    paste_tile(atlas, 2, make_tile(2, draw_grass_side))        # 2 grass side
    paste_tile(atlas, 3, make_tile(3, draw_dirt))              # 3 dirt
    paste_tile(atlas, 4, make_tile(4, draw_stone))             # 4 stone
    paste_tile(atlas, 5, make_tile(5, draw_cobble))            # 5 cobble
    paste_tile(atlas, 6, make_tile(6, draw_sand))              # 6 sand
    paste_tile(atlas, 7, make_tile(7, draw_gravel))            # 7 gravel
    paste_tile(atlas, 8, make_tile(8, draw_clay))              # 8 clay
    paste_tile(atlas, 9, make_tile(9, draw_snow))              # 9 snow
    paste_tile(atlas, 10, make_tile(10, draw_ice))             # 10 ice
    paste_tile(atlas, 11, make_tile(11, draw_sandstone))       # 11 sandstone
    paste_tile(atlas, 12, make_tile(12, draw_bedrock))         # 12 bedrock
    paste_tile(atlas, 13, make_tile(13, draw_mycel))           # 13 mycel
    paste_tile(atlas, 14, make_tile(14, draw_dirt))            # 14 reserve
    paste_tile(atlas, 15, make_tile(15, draw_dirt))            # 15 reserve

    # Ores (16..22)
    paste_tile(atlas, 16, make_tile(16, lambda img, idx: draw_ore(img, idx, COL['coal_ore'], COL['coal_spot'])))
    paste_tile(atlas, 17, make_tile(17, lambda img, idx: draw_ore(img, idx, COL['iron_ore'], COL['iron_spot'])))
    paste_tile(atlas, 18, make_tile(18, lambda img, idx: draw_ore(img, idx, COL['gold_ore'], COL['gold_spot'])))
    paste_tile(atlas, 19, make_tile(19, lambda img, idx: draw_ore(img, idx, COL['gem_ore'], COL['gem_spot'])))
    paste_tile(atlas, 20, make_tile(20, lambda img, idx: draw_ore(img, idx, COL['emerald_ore'], COL['emerald_spot'])))
    paste_tile(atlas, 21, make_tile(21, lambda img, idx: draw_ore(img, idx, COL['lapis_ore'], COL['lapis_spot'])))
    paste_tile(atlas, 22, make_tile(22, lambda img, idx: draw_ore(img, idx, COL['spark_ore'], COL['spark_spot'])))

    # OAK (24 log top, 25 log side, 26 planks, 27 leaves, 28 sapling)
    paste_tile(atlas, 24, make_tile(24, lambda img, idx: draw_log_top(img, idx, COL['log_top_oak'], COL['log_top_oak_dark'])))
    paste_tile(atlas, 25, make_tile(25, lambda img, idx: draw_log_side(img, idx, COL['log_side_oak'], COL['log_side_oak_dark'])))
    paste_tile(atlas, 26, make_tile(26, lambda img, idx: draw_planks(img, idx, COL['planks_oak'], COL['planks_oak_dark'])))
    paste_tile(atlas, 27, make_tile(27, lambda img, idx: draw_leaves(img, idx, COL['leaves_oak'], COL['leaves_oak_dark'])))
    paste_tile(atlas, 28, make_tile(28, lambda img, idx: draw_sapling(img, idx, COL['sapling_oak'])))

    # BIRCH (30 log side, 31 planks, 32 leaves, 33 sapling)
    paste_tile(atlas, 30, make_tile(30, lambda img, idx: draw_log_side(img, idx, COL['log_side_birch'], COL['log_side_birch_dark'])))
    paste_tile(atlas, 31, make_tile(31, lambda img, idx: draw_planks(img, idx, COL['planks_birch'], COL['log_side_birch_dark'])))
    paste_tile(atlas, 32, make_tile(32, lambda img, idx: draw_leaves(img, idx, COL['leaves_birch'], COL['leaves_oak_dark'])))
    paste_tile(atlas, 33, make_tile(33, lambda img, idx: draw_sapling(img, idx, COL['sapling_birch'])))

    # SPRUCE (35, 36, 37, 38)
    paste_tile(atlas, 35, make_tile(35, lambda img, idx: draw_log_side(img, idx, COL['log_side_spruce'], COL['log_side_oak_dark'])))
    paste_tile(atlas, 36, make_tile(36, lambda img, idx: draw_planks(img, idx, COL['planks_spruce'], COL['planks_oak_dark'])))
    paste_tile(atlas, 37, make_tile(37, lambda img, idx: draw_leaves(img, idx, COL['leaves_spruce'], COL['leaves_oak_dark'])))
    paste_tile(atlas, 38, make_tile(38, lambda img, idx: draw_sapling(img, idx, COL['sapling_spruce'])))

    # JUNGLE (40, 41, 42, 43)
    paste_tile(atlas, 40, make_tile(40, lambda img, idx: draw_log_side(img, idx, COL['log_side_jungle'], COL['log_side_oak_dark'])))
    paste_tile(atlas, 41, make_tile(41, lambda img, idx: draw_planks(img, idx, COL['planks_jungle'], COL['planks_oak_dark'])))
    paste_tile(atlas, 42, make_tile(42, lambda img, idx: draw_leaves(img, idx, COL['leaves_jungle'], COL['leaves_oak_dark'])))
    paste_tile(atlas, 43, make_tile(43, lambda img, idx: draw_sapling(img, idx, COL['sapling_jungle'])))

    # ACACIA (45, 46, 47, 48)
    paste_tile(atlas, 45, make_tile(45, lambda img, idx: draw_log_side(img, idx, COL['log_side_acacia'], COL['log_side_oak_dark'])))
    paste_tile(atlas, 46, make_tile(46, lambda img, idx: draw_planks(img, idx, COL['planks_acacia'], COL['planks_oak_dark'])))
    paste_tile(atlas, 47, make_tile(47, lambda img, idx: draw_leaves(img, idx, COL['leaves_acacia'], COL['leaves_oak_dark'])))
    paste_tile(atlas, 48, make_tile(48, lambda img, idx: draw_sapling(img, idx, COL['sapling_acacia'])))

    # DARK OAK (50, 51, 52, 53)
    paste_tile(atlas, 50, make_tile(50, lambda img, idx: draw_log_side(img, idx, COL['log_side_dark_oak'], COL['log_side_oak_dark'])))
    paste_tile(atlas, 51, make_tile(51, lambda img, idx: draw_planks(img, idx, COL['planks_dark_oak'], COL['planks_oak_dark'])))
    paste_tile(atlas, 52, make_tile(52, lambda img, idx: draw_leaves(img, idx, COL['leaves_dark_oak'], COL['leaves_oak_dark'])))
    paste_tile(atlas, 53, make_tile(53, lambda img, idx: draw_sapling(img, idx, COL['sapling_dark_oak'])))

    # Fluids (60, 61)
    paste_tile(atlas, 60, make_tile(60, draw_water))
    paste_tile(atlas, 61, make_tile(61, draw_lava))

    # Build/decor (64+)
    paste_tile(atlas, 64, make_tile(64, draw_bricks))
    paste_tile(atlas, 65, make_tile(65, draw_stone_bricks))
    paste_tile(atlas, 66, make_tile(66, draw_glass))
    paste_tile(atlas, 67, make_tile(67, lambda img, idx: draw_wool(img, idx, COL['wool_white'])))
    paste_tile(atlas, 68, make_tile(68, lambda img, idx: draw_wool(img, idx, COL['wool_red'])))
    paste_tile(atlas, 69, make_tile(69, lambda img, idx: draw_wool(img, idx, COL['wool_green'])))
    paste_tile(atlas, 70, make_tile(70, lambda img, idx: draw_wool(img, idx, COL['wool_blue'])))
    paste_tile(atlas, 71, make_tile(71, lambda img, idx: draw_wool(img, idx, COL['wool_yellow'])))
    paste_tile(atlas, 72, make_tile(72, lambda img, idx: draw_wool(img, idx, COL['wool_black'])))
    paste_tile(atlas, 73, make_tile(73, lambda img, idx: draw_wool(img, idx, COL['wool_gray'])))
    paste_tile(atlas, 74, make_tile(74, lambda img, idx: draw_wool(img, idx, COL['wool_brown'])))
    paste_tile(atlas, 75, make_tile(75, lambda img, idx: draw_wool(img, idx, COL['wool_pink'])))
    paste_tile(atlas, 76, make_tile(76, lambda img, idx: draw_wool(img, idx, COL['wool_cyan'])))
    paste_tile(atlas, 77, make_tile(77, lambda img, idx: draw_wool(img, idx, COL['wool_magenta'])))
    paste_tile(atlas, 78, make_tile(78, lambda img, idx: draw_wool(img, idx, COL['wool_orange'])))
    paste_tile(atlas, 79, make_tile(79, lambda img, idx: draw_wool(img, idx, COL['wool_lime'])))
    paste_tile(atlas, 80, make_tile(80, lambda img, idx: draw_wool(img, idx, COL['wool_purple'])))

    # Terracotta (81..94)
    paste_tile(atlas, 81, make_tile(81, lambda img, idx: draw_terracotta(img, idx, COL['terracotta_white'])))
    paste_tile(atlas, 82, make_tile(82, lambda img, idx: draw_terracotta(img, idx, COL['terracotta_red'])))
    paste_tile(atlas, 83, make_tile(83, lambda img, idx: draw_terracotta(img, idx, COL['terracotta_orange'])))
    paste_tile(atlas, 84, make_tile(84, lambda img, idx: draw_terracotta(img, idx, COL['terracotta_yellow'])))
    paste_tile(atlas, 85, make_tile(85, lambda img, idx: draw_terracotta(img, idx, COL['terracotta_green'])))
    paste_tile(atlas, 86, make_tile(86, lambda img, idx: draw_terracotta(img, idx, COL['terracotta_blue'])))
    paste_tile(atlas, 87, make_tile(87, lambda img, idx: draw_terracotta(img, idx, COL['terracotta_purple'])))
    paste_tile(atlas, 88, make_tile(88, lambda img, idx: draw_terracotta(img, idx, COL['terracotta_pink'])))
    paste_tile(atlas, 89, make_tile(89, lambda img, idx: draw_terracotta(img, idx, COL['terracotta_brown'])))
    paste_tile(atlas, 90, make_tile(90, lambda img, idx: draw_terracotta(img, idx, COL['terracotta_cyan'])))
    paste_tile(atlas, 91, make_tile(91, lambda img, idx: draw_terracotta(img, idx, COL['terracotta_gray'])))
    paste_tile(atlas, 92, make_tile(92, lambda img, idx: draw_terracotta(img, idx, COL['terracotta_black'])))
    paste_tile(atlas, 93, make_tile(93, lambda img, idx: draw_terracotta(img, idx, COL['terracotta_magenta'])))
    paste_tile(atlas, 94, make_tile(94, lambda img, idx: draw_terracotta(img, idx, COL['terracotta_lime'])))

    paste_tile(atlas, 95, make_tile(95, draw_bookshelf))
    paste_tile(atlas, 96, make_tile(96, draw_hay))
    paste_tile(atlas, 97, make_tile(97, draw_ladder))
    paste_tile(atlas, 98, make_tile(98, draw_crafting))
    paste_tile(atlas, 99, make_tile(99, lambda img, idx: draw_furnace_front(img, idx, True)))
    paste_tile(atlas, 100, make_tile(100, draw_chest_front))
    paste_tile(atlas, 101, make_tile(101, draw_door))
    paste_tile(atlas, 102, make_tile(102, draw_trapdoor))
    paste_tile(atlas, 103, make_tile(103, draw_bed_top))
    paste_tile(atlas, 104, make_tile(104, draw_torch))
    paste_tile(atlas, 105, make_tile(105, draw_rune_altar))
    paste_tile(atlas, 106, make_tile(106, draw_brew_stand))

    paste_tile(atlas, 107, make_tile(107, draw_tall_grass))
    paste_tile(atlas, 108, make_tile(108, lambda img, idx: draw_flower(img, idx, COL['flower_red_petal'], COL['flower_red_stem'])))
    paste_tile(atlas, 109, make_tile(109, lambda img, idx: draw_flower(img, idx, COL['flower_yellow_petal'], COL['flower_yellow_stem'])))
    paste_tile(atlas, 110, make_tile(110, lambda img, idx: draw_flower(img, idx, COL['flower_white_petal'], COL['flower_white_stem'])))
    paste_tile(atlas, 111, make_tile(111, lambda img, idx: draw_flower(img, idx, COL['flower_purple_petal'], COL['flower_purple_stem'])))
    paste_tile(atlas, 112, make_tile(112, lambda img, idx: draw_flower(img, idx, COL['flower_pink_petal'], COL['flower_pink_stem'])))
    paste_tile(atlas, 113, make_tile(113, lambda img, idx: draw_flower(img, idx, COL['flower_blue_petal'], COL['flower_blue_stem'])))
    paste_tile(atlas, 114, make_tile(114, lambda img, idx: draw_mushroom(img, idx, COL['mushroom_red_cap'], COL['mushroom_red_stem'])))
    paste_tile(atlas, 115, make_tile(115, lambda img, idx: draw_mushroom(img, idx, COL['mushroom_brown_cap'], COL['mushroom_brown_stem'])))
    paste_tile(atlas, 116, make_tile(116, draw_cactus))
    paste_tile(atlas, 117, make_tile(117, draw_reed))
    paste_tile(atlas, 118, make_tile(118, draw_vines))
    paste_tile(atlas, 119, make_tile(119, draw_lily_pad))
    paste_tile(atlas, 120, make_tile(120, draw_snow_layer))

    # ---- Item icons (tiles 200+) ----
    paste_tile(atlas, 200, make_tile(200, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['stick'], 'stick')))
    paste_tile(atlas, 201, make_tile(201, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['string'], 'generic')))
    paste_tile(atlas, 202, make_tile(202, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['feather'], 'generic')))
    paste_tile(atlas, 203, make_tile(203, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['leather'], 'food')))
    paste_tile(atlas, 204, make_tile(204, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['bone'], 'generic')))
    paste_tile(atlas, 205, make_tile(205, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['spark_powder'], 'dust')))
    paste_tile(atlas, 206, make_tile(206, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['goo_ball'], 'food')))
    paste_tile(atlas, 207, make_tile(207, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['pearl'], 'gem')))
    paste_tile(atlas, 208, make_tile(208, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['flint'], 'flint')))
    paste_tile(atlas, 209, make_tile(209, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['coal'], 'gem')))
    paste_tile(atlas, 210, make_tile(210, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['iron_ingot'], 'ingot')))
    paste_tile(atlas, 211, make_tile(211, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['gold_ingot'], 'ingot')))
    paste_tile(atlas, 212, make_tile(212, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['gem'], 'gem')))
    paste_tile(atlas, 213, make_tile(213, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['emerald'], 'gem')))
    paste_tile(atlas, 214, make_tile(214, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['lapis_dust'], 'dust')))

    # Pickaxes (220..224)
    paste_tile(atlas, 220, make_tile(220, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_wood'], 'pickaxe')))
    paste_tile(atlas, 221, make_tile(221, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_stone'], 'pickaxe')))
    paste_tile(atlas, 222, make_tile(222, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_iron'], 'pickaxe')))
    paste_tile(atlas, 223, make_tile(223, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_gold'], 'pickaxe')))
    paste_tile(atlas, 224, make_tile(224, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_gem'], 'pickaxe')))
    # Axes (225..229)
    paste_tile(atlas, 225, make_tile(225, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_wood'], 'axe')))
    paste_tile(atlas, 226, make_tile(226, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_stone'], 'axe')))
    paste_tile(atlas, 227, make_tile(227, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_iron'], 'axe')))
    paste_tile(atlas, 228, make_tile(228, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_gold'], 'axe')))
    paste_tile(atlas, 229, make_tile(229, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_gem'], 'axe')))
    # Shovels (230..234)
    paste_tile(atlas, 230, make_tile(230, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_wood'], 'shovel')))
    paste_tile(atlas, 231, make_tile(231, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_stone'], 'shovel')))
    paste_tile(atlas, 232, make_tile(232, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_iron'], 'shovel')))
    paste_tile(atlas, 233, make_tile(233, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_gold'], 'shovel')))
    paste_tile(atlas, 234, make_tile(234, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_gem'], 'shovel')))
    # Swords (235..239)
    paste_tile(atlas, 235, make_tile(235, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_wood'], 'sword')))
    paste_tile(atlas, 236, make_tile(236, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_stone'], 'sword')))
    paste_tile(atlas, 237, make_tile(237, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_iron'], 'sword')))
    paste_tile(atlas, 238, make_tile(238, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_gold'], 'sword')))
    paste_tile(atlas, 239, make_tile(239, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_gem'], 'sword')))
    # Hoes (240..244)
    paste_tile(atlas, 240, make_tile(240, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_wood'], 'hoe')))
    paste_tile(atlas, 241, make_tile(241, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_stone'], 'hoe')))
    paste_tile(atlas, 242, make_tile(242, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_iron'], 'hoe')))
    paste_tile(atlas, 243, make_tile(243, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_gold'], 'hoe')))
    paste_tile(atlas, 244, make_tile(244, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['tool_gem'], 'hoe')))

    # Bow/Arrow/Shield (250..252)
    paste_tile(atlas, 250, make_tile(250, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['bow_wood'], 'bow')))
    paste_tile(atlas, 251, make_tile(251, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['arrow_shaft'], 'arrow')))
    paste_tile(atlas, 252, make_tile(252, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['shield'], 'shield')))

    # Armor (260..275)
    armor_order = ['leather', 'leather', 'leather', 'leather',
                   'iron', 'iron', 'iron', 'iron',
                   'gold', 'gold', 'gold', 'gold',
                   'gem', 'gem', 'gem', 'gem']
    for i, kind in enumerate(armor_order):
        paste_tile(atlas, 260 + i, make_tile(260 + i, lambda idx, _, k=kind: draw_item_icon(idx, idx, ITEM_COL['armor_' + k], 'armor')))

    # Food (280..289)
    paste_tile(atlas, 280, make_tile(280, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['bread'], 'bread')))
    paste_tile(atlas, 281, make_tile(281, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['cooked_beef'], 'food')))
    paste_tile(atlas, 282, make_tile(282, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['cooked_pork'], 'food')))
    paste_tile(atlas, 283, make_tile(283, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['cooked_chicken'], 'food')))
    paste_tile(atlas, 284, make_tile(284, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['apple'], 'apple')))
    paste_tile(atlas, 285, make_tile(285, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['carrot'], 'carrot')))
    paste_tile(atlas, 286, make_tile(286, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['potato'], 'potato')))
    paste_tile(atlas, 287, make_tile(287, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['baked_potato'], 'potato')))
    paste_tile(atlas, 288, make_tile(288, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['melon_slice'], 'melon')))
    paste_tile(atlas, 289, make_tile(289, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['berries'], 'berries')))

    # Misc items (300..306)
    paste_tile(atlas, 300, make_tile(300, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['bucket'], 'bucket')))
    paste_tile(atlas, 301, make_tile(301, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['bucket_water'], 'bucket')))
    paste_tile(atlas, 302, make_tile(302, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['bucket_lava'], 'bucket')))
    paste_tile(atlas, 303, make_tile(303, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['flint_and_steel'], 'flint')))
    paste_tile(atlas, 304, make_tile(304, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['compass'], 'compass')))
    paste_tile(atlas, 305, make_tile(305, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['map'], 'map')))
    paste_tile(atlas, 306, make_tile(306, lambda img, idx: draw_item_icon(img, idx, ITEM_COL['clock'], 'clock')))

    return atlas


if __name__ == '__main__':
    atlas = build_atlas()
    out_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                            'assets', 'textures', 'atlas.png')
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    atlas.save(out_path)
    print(f"Atlas saved to: {out_path}")
    print(f"Atlas size: {atlas.size}")
