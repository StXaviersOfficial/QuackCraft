# QuackCraft - Base Mob
# Simple AI: wander + chase + attack. Type-specific behaviors via config.
extends CharacterBody3D

const B = preload("res://scripts/blocks/BlockRegistry.gd")

var mob_type: String = "shambler"
var world = null
var player = null

var health: float = 20.0
var speed: float = 2.5
var damage: float = 3.0
var attack_range: float = 1.5
var detect_range: float = 16.0
var hostile: bool = false
var passive_flee: bool = false

var state: String = "idle"
var state_timer: float = 0.0
var wander_dir: Vector3 = Vector3.ZERO
var gravity: float = 29.4
var attack_cooldown: float = 0.0

# Visual node
var mesh_instance: MeshInstance3D
var hurt_timer: float = 0.0
var death_timer: float = 0.0
var dying: bool = false

func setup(w: Node, p: Node) -> void:
        world = w
        player = p
        collision_layer = 4 # mobs
        collision_mask = 1 # world
        _configure_type()
        _build_visual()

func _configure_type() -> void:
        match mob_type:
                "shambler":
                        health = 20.0; speed = 2.0; damage = 4.0; hostile = true
                "bonewalker":
                        health = 16.0; speed = 2.5; damage = 3.0; hostile = true
                "crawler":
                        health = 14.0; speed = 3.0; damage = 3.0; hostile = true
                "shade":
                        health = 18.0; speed = 3.5; damage = 5.0; hostile = true
                "bomber":
                        health = 14.0; speed = 2.5; damage = 0.0; hostile = true
                "cow":
                        health = 10.0; speed = 1.5; damage = 0.0; hostile = false; passive_flee = true
                "pig":
                        health = 10.0; speed = 1.5; damage = 0.0; hostile = false; passive_flee = true
                "chicken":
                        health = 6.0; speed = 1.7; damage = 0.0; hostile = false; passive_flee = true
                "sheep":
                        health = 8.0; speed = 1.5; damage = 0.0; hostile = false; passive_flee = true
                "rabbit":
                        health = 5.0; speed = 2.5; damage = 0.0; hostile = false; passive_flee = true

func _build_visual() -> void:
        # Simple colored box per mob type
        mesh_instance = MeshInstance3D.new()
        var box: BoxMesh = BoxMesh.new()
        box.size = Vector3(0.8, 1.6, 0.8)
        mesh_instance.mesh = box
        var mat: StandardMaterial3D = StandardMaterial3D.new()
        mat.albedo_color = _mob_color()
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
        mesh_instance.material_override = mat
        mesh_instance.position = Vector3(0, 0.8, 0)
        add_child(mesh_instance)

        # Collision shape
        var col: CollisionShape3D = CollisionShape3D.new()
        var shape: CapsuleShape3D = CapsuleShape3D.new()
        shape.height = 1.6
        shape.radius = 0.4
        col.shape = shape
        col.position = Vector3(0, 0.8, 0)
        add_child(col)

func _mob_color() -> Color:
        match mob_type:
                "shambler": return Color(0.3, 0.5, 0.3)
                "bonewalker": return Color(0.9, 0.9, 0.85)
                "crawler": return Color(0.25, 0.2, 0.25)
                "shade": return Color(0.05, 0.05, 0.15)
                "bomber": return Color(0.55, 0.55, 0.55)
                "cow": return Color(0.35, 0.25, 0.2)
                "pig": return Color(0.9, 0.55, 0.6)
                "chicken": return Color(0.95, 0.9, 0.85)
                "sheep": return Color(0.95, 0.92, 0.9)
                "rabbit": return Color(0.85, 0.75, 0.6)
                _: return Color.WHITE

func _physics_process(delta: float) -> void:
        if dying:
                death_timer += delta
                if death_timer > 1.5:
                        queue_free()
                return
        # Gravity
        if not is_on_floor():
                velocity.y -= gravity * delta
        # Decay timers
        if hurt_timer > 0: hurt_timer -= delta
        if attack_cooldown > 0: attack_cooldown -= delta
        # AI
        if player != null and is_instance_valid(player):
                var to_player := player.position - position
                var dist: float = to_player.length()
                if hostile and dist < detect_range:
                        state = "chase"
                elif passive_flee and hurt_timer > 0 and dist < 12:
                        state = "flee"
                else:
                        state_timer -= delta
                        if state_timer <= 0 or state == "chase" or state == "flee":
                                if randf() < 0.5:
                                        state = "idle"
                                        state_timer = randf_range(1.0, 3.0)
                                        wander_dir = Vector3.ZERO
                                else:
                                        state = "wander"
                                        state_timer = randf_range(2.0, 4.0)
                                        var ang: float = randf() * TAU
                                        wander_dir = Vector3(cos(ang), 0, sin(ang)).normalized()
                # Movement based on state
                var move := Vector3.ZERO
                match state:
                        "chase":
                                move = to_player.normalized() * speed
                                if dist < attack_range and attack_cooldown <= 0:
                                        _attack_player()
                        "flee":
                                move = -to_player.normalized() * speed * 1.5
                        "wander":
                                move = wander_dir * speed * 0.5
                        "idle":
                                move = Vector3.ZERO
                velocity.x = move.x
                velocity.z = move.z
                # Face movement direction
                if velocity.length() > 0.1:
                        var look_target: Vector3 = position + Vector3(velocity.x, 0, velocity.z)
                        if look_target != position:
                                look_at(look_target, Vector3.UP)
        # Bomber special: explode when adjacent to player
        if mob_type == "bomber" and player != null:
                var d: float = position.distance_to(player.position)
                if d < 2.5 and not dying:
                        _explode()
        # Special: crawler can climb walls (disable gravity when adjacent)
        if mob_type == "crawler":
                # Simplified: allow it to walk up walls (velocity.y stays)
                pass
        move_and_slide()

func _attack_player() -> void:
        attack_cooldown = 1.0
        # Face player and play attack anim (just color flash for v1)
        mesh_instance.material_override.albedo_color = _mob_color() * 1.5
        # Damage
        if player.has_method("take_damage"):
                var dir: Vector3 = (player.position - position).normalized()
                player.take_damage(damage, dir)
        await get_tree().create_timer(0.15).timeout
        if is_instance_valid(mesh_instance) and mesh_instance.material_override != null:
                mesh_instance.material_override.albedo_color = _mob_color()

func _explode() -> void:
        dying = true
        # Damage player if close
        if player != null:
                var d: float = position.distance_to(player.position)
                if d < 4.0:
                        var dir: Vector3 = (player.position - position).normalized()
                        player.take_damage(15.0, dir)
        # Spawn explosion particles (simplified: red flash cube)
        mesh_instance.scale = Vector3(2, 2, 2)
        mesh_instance.material_override.albedo_color = Color(1, 0.5, 0.1, 1)
        # Damage blocks around (crater)
        var bx: int = int(position.x)
        var by: int = int(position.y)
        var bz: int = int(position.z)
        for dx in range(-2, 3):
                for dy in range(-2, 3):
                        for dz in range(-2, 3):
                                if dx*dx + dy*dy + dz*dz <= 4:
                                        var b: int = world.get_block(bx + dx, by + dy, bz + dz)
                                        if b != B.AIR and b != B.BEDROCK:
                                                world.set_block(bx + dx, by + dy, bz + dz, B.AIR)

func take_damage(amount: float) -> void:
        health -= amount
        hurt_timer = 0.3
        if mesh_instance != null and mesh_instance.material_override != null:
                mesh_instance.material_override.albedo_color = Color(1, 0.3, 0.3)
        await get_tree().create_timer(0.15).timeout
        if is_instance_valid(mesh_instance) and mesh_instance.material_override != null:
                mesh_instance.material_override.albedo_color = _mob_color()
        if health <= 0 and not dying:
                _die()

func _die() -> void:
        dying = true
        # Drop loot (simplified)
        var drop_id: int = _mob_drop()
        if drop_id != B.AIR:
                # In a full impl we'd spawn a dropped item entity; for v1, give to player
                pass
        # Visual: shrink + fade
        var t: SceneTreeTween = create_tween()
        t.tween_property(mesh_instance, "scale", Vector3(0.01, 0.01, 0.01), 1.0)
        t.parallel().tween_property(mesh_instance, "transparency", 1.0, 1.0)

func _mob_drop() -> int:
        match mob_type:
                "cow": return ItemRegistry.COOKED_BEEF
                "pig": return ItemRegistry.COOKED_PORK
                "chicken": return ItemRegistry.COOKED_CHICKEN
                "sheep": return B.WOOL_WHITE
                "rabbit": return ItemRegistry.COOKED_CHICKEN
                "shambler": return ItemRegistry.BONE
                "bonewalker": return ItemRegistry.BONE
                "crawler": return ItemRegistry.STRING_ITEM
                "bomber": return ItemRegistry.SPARK_POWDER
                "shade": return ItemRegistry.PEARL
                _: return B.AIR
