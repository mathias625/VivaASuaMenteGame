extends Area2D
## Objeto que alguém perdeu (por enquanto, o chapéu do Seu Bento).

signal collected(kind: String)

var kind := ""

var _time := 0.0


func setup(item_kind: String) -> void:
    kind = item_kind


func _ready() -> void:
    collision_layer = 0
    collision_mask = 2   # camada do jogador
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
    var bob := sin(_time * 2.5) * 2.0
    draw_circle(Vector2(0.0, bob), 12.0 + sin(_time * 3.0) * 1.5, Color(1.0, 0.95, 0.7, 0.2))
    if kind == "hat":
        draw_rect(Rect2(-9.0, -1.0 + bob, 18.0, 3.0), Color(0.9, 0.78, 0.4))
        draw_rect(Rect2(-5.0, -7.0 + bob, 10.0, 6.0), Color(0.92, 0.8, 0.45))
        draw_rect(Rect2(-5.0, -3.0 + bob, 10.0, 2.0), Color(0.6, 0.35, 0.3))


func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        collected.emit(kind)
        queue_free()
