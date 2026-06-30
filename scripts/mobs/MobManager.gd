# QuackCraft - Mob manager
# Spawns hostile mobs at night/darkness, passive mobs during day,
# and updates their AI.
extends Node

const B = preload("res://scripts/blocks/BlockRegistry.gd")

var world = null
var player = null
var mobs: Array = []  # active mob nodes
const MAX_MOBS := 24
const SPAWN_DISTANCE := 32.0
const DESPAWN_DISTANCE := 60.0
var spawn_timer: float = 0.0
var day_night: Node = null

# Mob scenes (we'll spawn them as plain Node3Ds with scripts attached)
const MobSceneScript = preload("res://scripts/mobs/Mob.gd")

func setup(w: Node, p: Node) -> void:
        world = w
        player = p
        # Find day_night
        day_night = get_parent().get_node_or_null("DayNight")

func _process(delta: float) -> void:
        spawn_timer -= delta
        if spawn_timer <= 0:
                spawn_timer = 2.5
                _try_spawn()
        # Despawn distant mobs
        var to_remove := []
        for m in mobs:
                if not is_instance_valid(m):
                        to_remove.append(m)
                        continue
                if m.position.distance_to(player.position) > DESPAWN_DISTANCE:
                        to_remove.append(m)
                        m.queue_free()
        for m in to_remove:
                mobs.erase(m)

func _try_spawn() -> void:
        if mobs.size() >= MAX_MOBS:
                return
        var is_night := false
        if day_night != null:
                is_night = not day_night.is_daytime()
        # Pick a spawn position around the player
        var angle := randf() * TAU
        var dist := SPAWN_DISTANCE + randf() * 8.0
        var sx := int(player.position.x + cos(angle) * dist)
        var sz := int(player.position.z + sin(angle) * dist)
        # Find surface Y
        var sy := -1
        for y in range(80, 1, -1):
                var b: int = world.get_block(sx, y, sz)
                if B.is_solid(b) and b != B.WATER and b != B.LAVA:
                        sy = y + 1
                        break
        if sy < 0: return
        # Check light (simplified: spawn only at night for hostiles, anytime for passives)
        var type := _pick_type(is_night)
        if type == "": return
        _spawn_mob(type, Vector3(sx + 0.5, sy + 0.5, sz + 0.5))

func _pick_type(night: bool) -> String:
        if night:
                var r := randf()
                if r < 0.4: return "shambler"
                if r < 0.65: return "bonewalker"
                if r < 0.85: return "crawler"
                if r < 0.95: return "shade"
                return "bomber"
        else:
                var r := randf()
                if r < 0.3: return "cow"
                if r < 0.55: return "pig"
                if r < 0.75: return "chicken"
                if r < 0.9: return "sheep"
                return "rabbit"

func _spawn_mob(type: String, pos: Vector3) -> Node:
        var m := MobSceneScript.new()
        m.mob_type = type
        m.position = pos
        world.add_child(m)
        m.setup(world, player)
        mobs.append(m)
        return m
