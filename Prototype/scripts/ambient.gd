extends Node2D
## Partículas discretas no ar (poeira/pólen). Seguem a câmera e ficam mais
## quentes conforme o mundo recupera as cores.

var cam: Camera2D

var _particles: CPUParticles2D


func _ready() -> void:
    _particles = CPUParticles2D.new()
    _particles.amount = 36
    _particles.lifetime = 9.0
    _particles.local_coords = false
    _particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    _particles.emission_rect_extents = Vector2(340.0, 190.0)
    _particles.direction = Vector2(1.0, -0.2)
    _particles.spread = 180.0
    _particles.gravity = Vector2.ZERO
    _particles.initial_velocity_min = 3.0
    _particles.initial_velocity_max = 9.0
    _particles.scale_amount_min = 1.0
    _particles.scale_amount_max = 2.0
    _particles.color = Color(1.0, 1.0, 1.0, 0.3)
    _particles.emitting = true
    add_child(_particles)


func _process(_delta: float) -> void:
    if cam != null:
        global_position = cam.get_screen_center_position()


func set_warmth(value: float) -> void:
    _particles.color = Color(1.0, 1.0, 1.0, 0.3).lerp(Color(1.0, 0.92, 0.6, 0.5), clampf(value, 0.0, 1.0))
