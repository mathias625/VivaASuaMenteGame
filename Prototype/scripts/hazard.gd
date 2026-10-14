extends Node2D
## Ataques do Eco da Solidão:
##  - WAVE: onda de sombra que corre pelo chão (pule ou use a esquiva).
##  - VOID: mancha de vazio no chão (saia de cima ou fique numa plataforma).
## Todo ataque mostra um aviso antes de causar dano.

enum Kind { WAVE, VOID }

var kind := Kind.WAVE

var _player: Node2D
var _floor_y := 400.0
var _dir := 1.0
var _speed := 110.0
var _min_x := 0.0
var _max_x := 0.0
var _warn := 0.8
var _active := 1.4
var _radius := 38.0
var _time := 0.0


func _ready() -> void:
    add_to_group("hazard")


func setup_wave(player: Node2D, start_x: float, dir: float, speed: float, floor_y: float, min_x: float, max_x: float, warn: float) -> void:
    kind = Kind.WAVE
    _player = player
    position = Vector2(start_x, floor_y)
    _dir = dir
    _speed = speed
    _floor_y = floor_y
    _min_x = min_x
    _max_x = max_x
    _warn = warn


func setup_void(player: Node2D, x: float, radius: float, floor_y: float, warn: float, active: float) -> void:
    kind = Kind.VOID
    _player = player
    position = Vector2(x, floor_y)
    _radius = radius
    _floor_y = floor_y
    _warn = warn
    _active = active


func _process(delta: float) -> void:
    _time += delta
    if _warn > 0.0:
        _warn -= delta
    elif kind == Kind.WAVE:
        position.x += _dir * _speed * delta
        if position.x < _min_x or position.x > _max_x:
            queue_free()
            return
        _try_hit(16.0)
    else:
        _active -= delta
        _try_hit(_radius)
        if _active <= 0.0:
            queue_free()
            return
    queue_redraw()


func _try_hit(half_width: float) -> void:
    var feet_y: float = _player.global_position.y + 15.0
    var on_ground := feet_y >= _floor_y - 14.0
    if on_ground and absf(_player.global_position.x - global_position.x) < half_width:
        _player.call("take_hit", global_position.x)


func _draw() -> void:
    var dark := Color(0.1, 0.1, 0.16, 0.9)
    if kind == Kind.WAVE:
        if _warn > 0.0:
            var a := 0.4 + 0.4 * sin(_time * 16.0)
            draw_rect(Rect2(-40.0, -4.0, 80.0, 4.0), Color(0.7, 0.8, 1.0, a))
            draw_string(ThemeDB.fallback_font, Vector2(-6.0, -12.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 12.0, 14, Color(1.0, 1.0, 1.0, a + 0.2))
            return
        draw_rect(Rect2(minf(-_dir * 50.0, 0.0), -3.0, 50.0, 3.0), Color(0.1, 0.1, 0.16, 0.5))
        draw_colored_polygon(PackedVector2Array([Vector2(-18.0, 0.0), Vector2(-8.0, -14.0), Vector2(0.0, -18.0), Vector2(8.0, -14.0), Vector2(18.0, 0.0)]), dark)
    else:
        draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.28))
        if _warn > 0.0:
            var b := 0.4 + 0.4 * sin(_time * 14.0)
            draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 32, Color(0.7, 0.8, 1.0, b), 2.0)
        else:
            draw_circle(Vector2.ZERO, _radius, Color(0.08, 0.08, 0.13, 0.85))
            draw_arc(Vector2.ZERO, _radius * 0.6, _time * 2.0, _time * 2.0 + 3.0, 16, Color(0.5, 0.6, 0.8, 0.6), 2.0)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
