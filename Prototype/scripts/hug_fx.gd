extends Node2D
## Efeito visual do abraço (provisório, até termos uma animação de abraço):
## brilho quente, "braços" em volta do casal, anel de cor e corações.

var _t := -1.0


func play(center: Vector2) -> void:
    global_position = center
    _t = 0.0
    var hearts := CPUParticles2D.new()
    hearts.one_shot = true
    hearts.amount = 16
    hearts.lifetime = 1.6
    hearts.explosiveness = 0.8
    hearts.direction = Vector2(0.0, -1.0)
    hearts.spread = 70.0
    hearts.gravity = Vector2(0.0, -15.0)
    hearts.initial_velocity_min = 15.0
    hearts.initial_velocity_max = 40.0
    hearts.scale_amount_min = 2.5
    hearts.scale_amount_max = 4.0
    hearts.color = Color(1.0, 0.5, 0.65)
    hearts.emitting = true
    add_child(hearts)
    get_tree().create_timer(3.0).timeout.connect(hearts.queue_free)


func _process(delta: float) -> void:
    if _t < 0.0:
        return
    _t += delta
    if _t > 3.5:
        _t = -1.0
    queue_redraw()


func _draw() -> void:
    if _t < 0.0:
        return
    var k := clampf(_t / 1.2, 0.0, 1.0)
    var fade := 1.0 - clampf(_t / 3.5, 0.0, 1.0)
    draw_circle(Vector2(0.0, 0.0), 26.0 + sin(_t * 6.0) * 2.0, Color(1.0, 0.9, 0.6, 0.2 * k * fade))
    # "braços" passando por cima dos ombros dos dois
    draw_arc(Vector2(0.0, -2.0), 18.0, PI * 1.1, PI * 1.9, 14, Color(1.0, 0.6, 0.65, k * fade), 3.0)
    draw_arc(Vector2(0.0, 4.0), 14.0, PI * 1.15, PI * 1.85, 14, Color(1.0, 0.75, 0.6, k * fade), 2.0)
    var ring := clampf(_t / 3.0, 0.0, 1.0)
    draw_arc(Vector2.ZERO, lerpf(4.0, 150.0, ring), 0.0, TAU, 48, Color(1.0, 0.85, 0.5, (1.0 - ring) * 0.9), 3.0)
