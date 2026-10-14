extends Node2D
## Árvore ou arbusto desenhado por código. A origem fica no pé do tronco.
## kind: 0 redonda, 1 pinheiro, 2 arbusto, 3 árvore seca (sem folhas)

var kind := 0
var size_factor := 1.0

var _time := 0.0
var _phase := 0.0


func _ready() -> void:
    _phase = randf() * TAU


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()


func _draw() -> void:
    var s := size_factor
    var sway := sin(_time * 1.3 + _phase) * 1.5 * s
    var trunk := Color(0.45, 0.32, 0.22)
    var leaf := Color(0.3, 0.62, 0.32)
    var leaf_light := Color(0.38, 0.72, 0.38)
    match kind:
        0:
            draw_rect(Rect2(-3.0 * s, -34.0 * s, 6.0 * s, 34.0 * s), trunk)
            draw_circle(Vector2(sway, -42.0 * s), 18.0 * s, leaf)
            draw_circle(Vector2(-12.0 * s + sway, -34.0 * s), 12.0 * s, leaf)
            draw_circle(Vector2(12.0 * s + sway, -34.0 * s), 12.0 * s, leaf)
            draw_circle(Vector2(-4.0 * s + sway, -48.0 * s), 9.0 * s, leaf_light)
        1:
            draw_rect(Rect2(-2.5 * s, -16.0 * s, 5.0 * s, 16.0 * s), trunk)
            for i in range(3):
                var y := -14.0 * s - float(i) * 16.0 * s
                var w := (22.0 - float(i) * 5.0) * s
                draw_colored_polygon(PackedVector2Array([Vector2(-w + sway * 0.3, y), Vector2(w + sway * 0.3, y), Vector2(sway * float(i + 1) * 0.4, y - 24.0 * s)]), leaf if i % 2 == 0 else leaf_light)
        2:
            draw_circle(Vector2(-7.0 * s, -6.0 * s), 8.0 * s, leaf)
            draw_circle(Vector2(7.0 * s, -6.0 * s), 8.0 * s, leaf)
            draw_circle(Vector2(sway * 0.5, -11.0 * s), 9.0 * s, leaf_light)
        _:
            draw_rect(Rect2(-3.0 * s, -38.0 * s, 6.0 * s, 38.0 * s), trunk)
            draw_line(Vector2(0.0, -26.0 * s), Vector2(-14.0 * s, -40.0 * s), trunk, 2.0)
            draw_line(Vector2(0.0, -32.0 * s), Vector2(12.0 * s, -48.0 * s), trunk, 2.0)
            draw_line(Vector2(-14.0 * s, -40.0 * s), Vector2(-20.0 * s, -44.0 * s), trunk, 1.0)
            draw_line(Vector2(12.0 * s, -48.0 * s), Vector2(18.0 * s, -50.0 * s), trunk, 1.0)
