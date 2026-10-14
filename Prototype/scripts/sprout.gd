extends Node2D
## Broto murcho: acolher (J) faz crescer uma folha onde dá para pular.
## É a primeira mecânica de "cor = habilidade": o verde cria plataformas.
## A origem do node fica no chão, na base do broto.

const SaturationShader := preload("res://shaders/saturation.gdshader")
const LEAF_WIDTH := 56.0
const LEAF_THICKNESS := 6.0

var love_radius := 14.0
var rise := 36.0          # altura da folha acima do chão
var grown := false

var _growth := 0.0        # 0 (murcho) a 1 (crescido)
var _time := 0.0
var _material: ShaderMaterial
var _shape: CollisionShape2D


func _ready() -> void:
    add_to_group("lovable")
    _material = ShaderMaterial.new()
    _material.shader = SaturationShader
    _material.set_shader_parameter("saturation", 0.0)
    material = _material

    # A folha só tem colisão depois que cresce. É "one way": dá para
    # atravessar por baixo e pousar por cima.
    var body := StaticBody2D.new()
    _shape = CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(LEAF_WIDTH, LEAF_THICKNESS)
    _shape.shape = rect
    _shape.position = Vector2(0.0, -rise + LEAF_THICKNESS / 2.0)
    _shape.one_way_collision = true
    _shape.disabled = true
    body.add_child(_shape)
    add_child(body)


func receive_love(_amount: int, _from_pos: Vector2) -> void:
    if grown:
        return
    grown = true
    var tween := create_tween()
    tween.tween_property(self, "_growth", 1.0, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_callback(_enable_leaf)
    var color_tween := create_tween()
    color_tween.tween_property(_material, "shader_parameter/saturation", 1.0, 1.2)


func _enable_leaf() -> void:
    _shape.set_deferred("disabled", false)


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()


func _draw() -> void:
    var green := Color(0.35, 0.75, 0.35)
    var dark := Color(0.25, 0.55, 0.28)
    if not grown:
        # Broto murcho, com a folha caída
        var droop := sin(_time * 1.5) * 1.0
        draw_line(Vector2(0.0, 0.0), Vector2(2.0, -8.0), dark, 2.0)
        draw_line(Vector2(2.0, -8.0), Vector2(8.0, -4.0 + droop), dark, 2.0)
        draw_circle(Vector2(9.0, -3.0 + droop), 3.0, green)
        return
    var top := -rise * _growth
    draw_line(Vector2(0.0, 0.0), Vector2(0.0, top), dark, 3.0)
    draw_rect(Rect2(-LEAF_WIDTH / 2.0, top, LEAF_WIDTH, LEAF_THICKNESS), green)
    draw_rect(Rect2(-LEAF_WIDTH / 2.0, top, LEAF_WIDTH, 2.0), Color(0.5, 0.88, 0.45))
