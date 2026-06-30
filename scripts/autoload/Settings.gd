# QuackCraft - Settings (autoload)
# Persisted user settings: render distance, particles, fps cap, sensitivity.
extends Node

const SETTINGS_PATH := "user://settings.cfg"

var render_distance: int = 5:
	set(v): render_distance = clamp(v, 2, 12); _save()
var particle_density: float = 1.0:
	set(v): particle_density = clamp(v, 0.0, 1.0); _save()
var fps_cap: int = 60:
	set(v): fps_cap = clamp(v, 30, 120); _apply_fps(); _save()
var look_sensitivity: float = 0.4:
	set(v): look_sensitivity = clamp(v, 0.1, 2.0); _save()
var sound_volume: float = 1.0:
	set(v): sound_volume = clamp(v, 0.0, 1.0); _apply_volume(); _save()
var world_seed: int = 1337

func _ready() -> void:
	_load()
	_apply_fps()
	_apply_volume()

func _apply_fps() -> void:
	Engine.max_fps = fps_cap

func _apply_volume() -> void:
	var idx: int = AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(sound_volume))

func _save() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("graphics", "render_distance", render_distance)
	cfg.set_value("graphics", "particle_density", particle_density)
	cfg.set_value("graphics", "fps_cap", fps_cap)
	cfg.set_value("controls", "look_sensitivity", look_sensitivity)
	cfg.set_value("audio", "sound_volume", sound_volume)
	cfg.set_value("world", "seed", world_seed)
	cfg.save(SETTINGS_PATH)

func _load() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	render_distance = cfg.get_value("graphics", "render_distance", 5)
	particle_density = cfg.get_value("graphics", "particle_density", 1.0)
	fps_cap = cfg.get_value("graphics", "fps_cap", 60)
	look_sensitivity = cfg.get_value("controls", "look_sensitivity", 0.4)
	sound_volume = cfg.get_value("audio", "sound_volume", 1.0)
	world_seed = cfg.get_value("world", "seed", 1337)
