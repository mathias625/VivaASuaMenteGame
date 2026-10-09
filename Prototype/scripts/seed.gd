extends Area2D
## A semente brilhante. É a única coisa colorida no começo do jogo.

signal collected

var _time := 0.0


func _ready() -> void:
    var shape := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = 12.0
    shape.shape = circle
    add_child(shape)
    body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()


func _draw() -> void:
    var pulse := 0.5 + 0.5 * sin(_time * 3.0)
    draw_circle(Vector2.ZERO, 14.0 + pulse * 4.0, Color(1.0, 0.9, 0.4, 0.25))
    draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.85, 0.3))


func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        collected.emit()
        queue_free()
