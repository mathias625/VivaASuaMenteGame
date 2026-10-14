extends Area2D
## Bilhete deixado por um morador. Prova de que o mundo nunca esteve vazio.

signal collected(note_id: int, who: String, text: String)

var note_id := 0
var who := ""
var text := ""

var _time := 0.0


func setup(id: int, from_who: String, message: String) -> void:
    note_id = id
    who = from_who
    text = message


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
    var glow := 0.5 + 0.5 * sin(_time * 3.0)
    draw_circle(Vector2(0.0, bob), 11.0 + glow * 2.0, Color(1.0, 0.95, 0.7, 0.2))
    draw_rect(Rect2(-6.0, -5.0 + bob, 12.0, 10.0), Color(0.98, 0.95, 0.85))
    draw_line(Vector2(-4.0, -2.0 + bob), Vector2(4.0, -2.0 + bob), Color(0.5, 0.45, 0.4), 1.0)
    draw_line(Vector2(-4.0, 1.0 + bob), Vector2(2.0, 1.0 + bob), Color(0.5, 0.45, 0.4), 1.0)


func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        collected.emit(note_id, who, text)
        queue_free()
