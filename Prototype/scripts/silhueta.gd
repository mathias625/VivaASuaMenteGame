extends Node2D
## Silhueta sentada num banco da praça (luta contra o Eco da Solidão).
## Quando a Solidão "pede" uma conexão, uma silhueta brilha; acolher (J) faz
## ela se abrir. A origem fica no chão, no centro do banco.

signal connected

const SaturationShader := preload("res://shaders/saturation.gdshader")

var love_radius := 18.0
var pending := false
var facing := 1.0

var _lit := 0.0
var _time := 0.0
var _material: ShaderMaterial


func _ready() -> void:
    add_to_group("lovable")
    _material = ShaderMaterial.new()
    _material.shader = SaturationShader
    _material.set_shader_parameter("saturation", 0.0)
    material = _material


func set_pending(on: bool) -> void:
    pending = on
    var target := 0.45 if on else (0.9 if _lit > 0.5 else 0.0)
    var tween := create_tween()
    tween.tween_property(_material, "shader_parameter/saturation", target, 0.8)


func receive_love(_amount: int, _from_pos: Vector2) -> void:
    if not pending:
        return
    pending = false
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "_lit", 1.0, 1.0)
    tween.tween_property(_material, "shader_parameter/saturation", 0.9, 1.0)
    connected.emit()


func dim() -> void:
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "_lit", 0.0, 2.0)
    tween.tween_property(_material, "shader_parameter/saturation", 0.0, 2.0)


func finish() -> void:
    pending = false
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "_lit", 1.0, 2.0)
    tween.tween_property(_material, "shader_parameter/saturation", 1.0, 3.0)


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()


func _draw() -> void:
    var tone := Color(0.2, 0.2, 0.26).lerp(Color(0.95, 0.7, 0.5), _lit)
    var f := facing
    draw_rect(Rect2(-6.0, -28.0, 12.0, 14.0), tone)
    draw_circle(Vector2(0.0, -33.0), 5.0, tone)
    draw_rect(Rect2(-6.0, -14.0, 14.0 * f if f > 0.0 else -14.0, 4.0), tone)
    draw_rect(Rect2(6.0 * f - 2.0, -10.0, 4.0, 10.0), tone)
    if _lit > 0.3:
        draw_rect(Rect2(f * 2.0 - 1.0, -34.0, 1.5, 1.5), Color(0.15, 0.1, 0.1))
        draw_arc(Vector2(f * 1.0, -31.0), 2.0, 0.3, PI - 0.3, 6, Color(0.5, 0.2, 0.2), 1.0)
    if pending:
        var pulse := 0.5 + 0.5 * sin(_time * 4.0)
        draw_arc(Vector2(0.0, -20.0), 22.0 + pulse * 3.0, 0.0, TAU, 28, Color(1.0, 0.9, 0.6, 0.8), 2.0)
        draw_arc(Vector2(0.0, -20.0), 28.0 + pulse * 4.0, 0.0, TAU, 28, Color(1.0, 0.9, 0.6, 0.3), 1.0)
