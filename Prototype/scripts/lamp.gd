extends Node2D
## Poste, abajur ou lampião. Quando aceso, ganha um brilho quente
## (o brilho fica fora do shader de cinza, então aparece colorido).
## kind: 0 poste de rua, 1 abajur de mesa, 2 lampião de praça. A origem fica no chão.

class Glow extends Node2D:
    var amount := 0.0
    var radius := 40.0
    var _time := 0.0
    var _prev := 0.0

    func _process(delta: float) -> void:
        _time += delta
        if amount > 0.01 or _prev > 0.01:
            queue_redraw()
        _prev = amount

    func _draw() -> void:
        if amount <= 0.01:
            return
        var flick := 1.0 + sin(_time * 5.0) * 0.03
        for i in range(5):
            var r := radius * (1.0 - float(i) * 0.18) * flick
            draw_circle(Vector2.ZERO, r, Color(1.0, 0.85, 0.5, 0.05 * amount))

var kind := 0
var lit := false

var _glow := 0.0
var _glow_node: Glow


func _ready() -> void:
    _glow_node = Glow.new()
    match kind:
        0:
            _glow_node.position = Vector2(0.0, -48.0)
            _glow_node.radius = 46.0
        1:
            _glow_node.position = Vector2(0.0, -16.0)
            _glow_node.radius = 30.0
        _:
            _glow_node.position = Vector2(0.0, -34.0)
            _glow_node.radius = 40.0
    add_child(_glow_node)


func set_lit(on: bool, seconds: float = 1.5) -> void:
    lit = on
    var tween := create_tween()
    tween.tween_property(self, "_glow", 1.0 if on else 0.0, seconds)


func _process(_delta: float) -> void:
    _glow_node.amount = _glow


func _draw() -> void:
    var dark := Color(0.25, 0.25, 0.3)
    var glass := Color(1.0, 0.92, 0.6)
    match kind:
        0:
            draw_rect(Rect2(-1.5, -46.0, 3.0, 46.0), dark)
            draw_rect(Rect2(-5.0, -52.0, 10.0, 7.0), dark)
            draw_rect(Rect2(-3.0, -50.0, 6.0, 4.0), glass)
        1:
            draw_rect(Rect2(-4.0, -2.0, 8.0, 2.0), dark)
            draw_rect(Rect2(-1.0, -12.0, 2.0, 10.0), dark)
            draw_colored_polygon(PackedVector2Array([Vector2(-6.0, -12.0), Vector2(6.0, -12.0), Vector2(3.0, -20.0), Vector2(-3.0, -20.0)]), Color(0.85, 0.75, 0.55))
        _:
            draw_rect(Rect2(-1.0, -30.0, 2.0, 30.0), dark)
            draw_rect(Rect2(-4.0, -38.0, 8.0, 8.0), dark)
            draw_rect(Rect2(-2.5, -36.0, 5.0, 5.0), glass)
