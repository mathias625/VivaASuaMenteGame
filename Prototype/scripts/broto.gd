extends Node2D
## Broto: o companheiro que nasce da semente. Segue o Wander e dá humor.

var _player: Node2D
var _time := 0.0
var _active := false


func setup(player: Node2D) -> void:
    _player = player
    visible = false


func activate() -> void:
    _active = true
    visible = true
    global_position = _player.global_position + Vector2(0.0, -30.0)


func _process(delta: float) -> void:
    if not _active:
        return
    _time += delta
    var side := -float(_player.get("facing"))
    var target := _player.global_position + Vector2(side * 18.0, -26.0 + sin(_time * 3.0) * 4.0)
    global_position = global_position.lerp(target, 1.0 - pow(0.01, delta))
    queue_redraw()


func _draw() -> void:
    draw_line(Vector2(0.0, 6.0), Vector2(0.0, -2.0), Color(0.3, 0.7, 0.3), 2.0)
    draw_circle(Vector2(-4.0, -3.0), 3.5, Color(0.45, 0.85, 0.4))
    draw_circle(Vector2(4.0, -3.0), 3.5, Color(0.45, 0.85, 0.4))
    draw_rect(Rect2(-2.5, 1.0, 1.5, 2.0), Color(0.1, 0.1, 0.1))
    draw_rect(Rect2(1.0, 1.0, 1.5, 2.0), Color(0.1, 0.1, 0.1))
