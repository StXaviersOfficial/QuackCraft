# QuackCraft - Day/night cycle
# Controls sun direction, sky color, ambient light, and moon/sun visuals.
# ~20 minutes per full cycle.
extends DirectionalLight3D

const CYCLE_LENGTH_SEC := 1200.0 # 20 minutes
var time_of_day: float = 0.25 # 0=midnight, 0.25=sunrise, 0.5=noon, 0.75=sunset
var day_count: int = 1

var world: Node = null
var player: Node = null

# Sky gradient (top color over time of day)
var sky_gradient: Gradient
var ambient_gradient: Gradient
var sun_color: Gradient

var environment: Environment
var sun: DirectionalLight3D
var sky: ProceduralSkyMaterial

signal time_changed(day: int, hour: int, minute: int)
signal night_started
signal day_started

func setup(w: Node, p: Node) -> void:
        world = w
        player = p
        # Add ourselves to the world environment
        var env_node: WorldEnvironment = WorldEnvironment.new()
        env_node.name = "WorldEnv"
        env_node.environment = Environment.new()
        env_node.environment.background_mode = Environment.BG_SKY
        sky = ProceduralSkyMaterial.new()
        sky.sun_curve_max = 1.0
        sky.sun_curve_min = 0.1
        var sky_box: Sky = Sky.new()
        sky_box.sky_material = sky
        env_node.environment.sky = sky_box
        env_node.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
        env_node.environment.ambient_light_energy = 0.6
        env_node.environment.fog_enabled = true
        env_node.environment.fog_light_color = Color(0.7, 0.8, 0.95)
        env_node.environment.fog_density = 0.005
        env_node.environment.fog_aerial_perspective = 0.5
        env_node.environment.glow_enabled = false
        env_node.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
        add_child(env_node)
        environment = env_node.environment

        # Add a directional light (the sun) — that's this node
        light_energy = 1.0
        light_color = Color(1, 0.95, 0.85)
        shadow_enabled = true
        directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL

        _build_gradients()
        _update_sky()

func _build_gradients() -> void:
        sky_gradient = Gradient.new()
        # Night -> dawn -> day -> dusk -> night
        sky_gradient.set_color(0, Color(0.05, 0.05, 0.12)) # midnight
        sky_gradient.add_point(0.20, Color(0.1, 0.1, 0.2))  # pre-dawn
        sky_gradient.add_point(0.25, Color(0.6, 0.4, 0.3))  # dawn
        sky_gradient.add_point(0.30, Color(0.5, 0.7, 0.95)) # morning
        sky_gradient.add_point(0.50, Color(0.55, 0.78, 0.98)) # noon
        sky_gradient.add_point(0.70, Color(0.55, 0.7, 0.95)) # afternoon
        sky_gradient.add_point(0.78, Color(0.9, 0.4, 0.3))  # sunset
        sky_gradient.add_point(0.85, Color(0.1, 0.1, 0.25)) # dusk
        sky_gradient.add_point(1.0, Color(0.05, 0.05, 0.12)) # midnight

        ambient_gradient = Gradient.new()
        ambient_gradient.set_color(0, Color(0.15, 0.18, 0.25))
        ambient_gradient.add_point(0.25, Color(0.4, 0.35, 0.35))
        ambient_gradient.add_point(0.50, Color(0.85, 0.85, 0.85))
        ambient_gradient.add_point(0.75, Color(0.4, 0.35, 0.35))
        ambient_gradient.add_point(1.0, Color(0.15, 0.18, 0.25))

func _process(delta: float) -> void:
        time_of_day += delta / CYCLE_LENGTH_SEC
        if time_of_day >= 1.0:
                time_of_day -= 1.0
                day_count += 1
                day_started.emit()
        # Emit hourly signal
        var hour: int = int(time_of_day * 24)
        var minute: int = int((time_of_day * 24 - hour) * 60)
        time_changed.emit(day_count, hour, minute)
        # Night started (when crossing into <0.22 or >0.78)
        if time_of_day > 0.78 or time_of_day < 0.22:
                night_started.emit()
        # Update visuals
        _update_sky()

func _update_sky() -> void:
        if environment == null: return
        var t := time_of_day
        var sky_col: Color = sky_gradient.sample(t)
        sky.sky_top_color = sky_col
        sky.sky_horizon_color = sky_col * 0.95
        var sun_angle: float = (t - 0.25) * 360.0 # sunrise at t=0.25
        # DirectionalLight3D direction is set via rotation, not a direct property.
        # Sun at sunrise (angle=0) should point from east (X+) to west.
        # We rotate the light so its -Z axis (default direction) points toward the sun.
        rotation = Vector3(deg_to_rad(sun_angle - 90), deg_to_rad(45), 0)
        # Light intensity: bright at noon, dim at night
        var elevation: float = sin(deg_to_rad(sun_angle))
        light_energy = clamp(elevation, 0, 1) * 1.1 + 0.05
        if elevation > 0:
                light_color = Color(1, 0.95, 0.85)
        else:
                # Moonlight
                light_color = Color(0.5, 0.55, 0.7)
                light_energy = 0.15
        # Ambient
        environment.ambient_light_color = ambient_gradient.sample(t)
        environment.ambient_light_energy = 0.4 + 0.3 * sin(deg_to_rad(sun_angle))
        # Sky colors
        sky.sky_top_color = sky_col
        sky.sky_horizon_color = sky_col * 0.9
        sky.ground_bottom_color = sky_col * 0.3
        sky.ground_horizon_color = sky_col * 0.6

func is_daytime() -> bool:
        var elevation: float = sin(deg_to_rad((time_of_day - 0.25) * 360.0))
        return elevation > 0
