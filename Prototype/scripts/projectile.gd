extends Node2D
## Projéteis da Insônia: ovelhas (correm no chão, pule ou use a esquiva)
## e pensamentos acelerados (caem do alto, com aviso no chão).

enum Kind { SHEEP, ORB }

const ORB_SPEED := 380.0

var kind := Kind.SHEEP

var _player: Node2D
var _dir := 1.0
var _speed := 120.0
var _min_x := 0.0
var _max_x := 0.0
var _floor_y := 400.0
var _warn := 0.0
var _time := 0.0


func _ready() -> void:
    add_to_group("hazard")


func setup_sheep(player: Node2D, start: Vector2, dir: float, speed: float, min_x: float, max_x: float) -> void:
    kind = Kind.SHEEP
    _player = player
    position = start
    _dir = dir
    _speed = speed
    _min_x = min_x
    _max_x = max_x


func setup_orb(player: Node2D, x: float, floor_y: float, warn_time: float) -> void:
    kind = Kind.ORB
    _player = player
    _floor_y = floor_y
    _warn = warn_time
    position = Vector2(x, floor_y - 300.0)


func _process(delta: float) -> void:
    _time += delta
    if kind == Kind.SHEEP:
        position.x += _dir * _speed * delta
        if position.x < _min_x or position.x > _max_x:
            queue_free()
            return
        if _player.global_position.distance_to(global_position) < 18.0:
            _player.call("take_hit", global_position.x)
    else:
        if _warn > 0.0:
            _warn -= delta
        else:
            position.y += ORB_SPEED * delta
            if position.y >= _floor_y - 8.0:
                queue_free()
                return
            if _player.global_position.distance_to(global_position) < 16.0:
                _player.call("take_hit", global_position.x)
    queue_redraw()


func _draw() -> void:
    if kind == Kind.SHEEP:
        var hop := absf(sin(_time * 8.0)) * 4.0
        var wool := Color(0.96, 0.96, 0.98)
        draw_circle(Vector2(0.0, -hop), 9.0, wool)
        draw_circle(Vector2(-6.0, -hop - 3.0), 6.0, wool)
        draw_circle(Vector2(6.0, -hop - 3.0), 6.0, wool)
        draw_circle(Vector2(_dir * 9.0, -hop + 1.0), 4.0, Color(0.25, 0.22, 0.28))
        draw_rect(Rect2(-5.0, 7.0 - hop, 2.0, 3.0 + hop), Color(0.25, 0.22, 0.28))
        draw_rect(Rect2(3.0, 7.0 - hop, 2.0, 3.0 + hop), Color(0.25, 0.22, 0.28))
    else:
        if _warn > 0.0:
            var marker := Vector2(0.0, _floor_y - position.y)
            draw_arc(marker, 10.0 + sin(_time * 14.0) * 2.0, 0.0, TAU, 16, Color(0.8, 0.6, 1.0, 0.85), 2.0)
        else:
            draw_line(Vector2(0.0, -26.0), Vector2.ZERO, Color(0.5, 0.45, 0.8, 0.5), 4.0)
            draw_circle(Vector2.ZERO, 8.0, Color(0.4, 0.35, 0.7))
            draw_circle(Vector2.ZERO, 4.0, Color(0.8, 0.75, 1.0))
