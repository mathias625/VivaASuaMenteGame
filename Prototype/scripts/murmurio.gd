extends CharacterBody2D
## Murmúrio: um bichinho cinza e solitário que faz barulho para chamar atenção.
## Não se derrota: acolhe-se (J). Quando a hostilidade zera, ele vira amigo,
## ganha cor e passa a seguir o Wander.

signal befriended(who: Node2D)
signal noticed

const SaturationShader := preload("res://shaders/saturation.gdshader")
const GRAVITY := 900.0
const PATROL_SPEED := 34.0
const CHASE_SPEED := 62.0
const WHISPERS_HOSTILE := ["sozinho...", "psiu...", "me vê?", "..."]
const WHISPERS_FRIEND := ["oi!", "amigo!", "vamos?", "que cor é essa?"]
const FRIEND_COLORS := [Color(0.98, 0.62, 0.55), Color(0.55, 0.8, 0.95), Color(0.98, 0.85, 0.45)]

var love_radius := 12.0
var hostility := 3
var friend := false
var friend_index := 0

var _left := 0.0
var _right := 0.0
var _dir := 1.0
var _stun := 0.0
var _hit_cooldown := 0.0
var _flash := 0.0
var _time := 0.0
var _whisper_timer := 2.0
var _whisper_show := 0.0
var _whisper := ""
var _player: Node2D
var _material: ShaderMaterial
var _noticed := false


func setup(player: Node2D, left: float, right: float) -> void:
    _player = player
    _left = left
    _right = right
    _dir = 1.0 if randf() > 0.5 else -1.0


func _ready() -> void:
    collision_layer = 4   # inimigos
    collision_mask = 1    # só colide com o cenário
    add_to_group("lovable")
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(16.0, 14.0)
    shape.shape = rect
    add_child(shape)
    _material = ShaderMaterial.new()
    _material.shader = SaturationShader
    _material.set_shader_parameter("saturation", 0.0)
    material = _material
    _whisper_timer = randf_range(1.0, 3.0)


func _physics_process(delta: float) -> void:
    _time += delta
    _flash = maxf(_flash - delta, 0.0)
    _stun = maxf(_stun - delta, 0.0)
    _hit_cooldown = maxf(_hit_cooldown - delta, 0.0)
    _whisper_show = maxf(_whisper_show - delta, 0.0)
    _update_whisper(delta)
    if friend:
        _follow_player(delta)
    else:
        _hostile_behaviour(delta)
    queue_redraw()


func _hostile_behaviour(delta: float) -> void:
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    var dx := _player.global_position.x - global_position.x
    var dy := _player.global_position.y - global_position.y
    var speed := PATROL_SPEED
    if not _noticed and absf(dx) < 100.0 and absf(dy) < 40.0:
        _noticed = true
        noticed.emit()
    if _stun > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
    else:
        var chasing := absf(dx) < 110.0 and absf(dy) < 36.0
        if chasing:
            _dir = signf(dx)
            speed = CHASE_SPEED
        elif global_position.x <= _left:
            _dir = 1.0
        elif global_position.x >= _right:
            _dir = -1.0
        var blocked := (global_position.x <= _left and _dir < 0.0) or (global_position.x >= _right and _dir > 0.0)
        velocity.x = 0.0 if blocked else _dir * speed
    move_and_slide()

    # Contato: um encontrão tira um ponto de Fôlego
    if _stun <= 0.0 and _hit_cooldown <= 0.0 and absf(dx) < 12.0 and absf(dy) < 16.0:
        _hit_cooldown = 1.0
        _player.call("take_hit", global_position.x)


func _follow_player(delta: float) -> void:
    var side := -float(_player.get("facing"))
    var target := _player.global_position + Vector2(side * (24.0 + 20.0 * float(friend_index)), 4.0)
    target.y -= absf(sin(_time * 7.0 + float(friend_index))) * 5.0
    global_position = global_position.lerp(target, 1.0 - pow(0.002, delta))


func receive_love(amount: int, from_pos: Vector2) -> void:
    if friend:
        return
    hostility -= amount
    _flash = 0.25
    _stun = 0.5
    velocity.x = signf(global_position.x - from_pos.x) * 80.0
    _say("...")
    if hostility <= 0:
        _become_friend()


func _become_friend() -> void:
    friend = true
    remove_from_group("lovable")
    add_to_group("friends")
    set_deferred("collision_mask", 0)
    var tween := create_tween()
    tween.tween_property(_material, "shader_parameter/saturation", 1.0, 1.2)
    _say("oi!")
    _hearts()
    befriended.emit(self)


func _hearts() -> void:
    var p := CPUParticles2D.new()
    p.one_shot = true
    p.amount = 10
    p.lifetime = 0.9
    p.explosiveness = 1.0
    p.direction = Vector2(0.0, -1.0)
    p.spread = 80.0
    p.gravity = Vector2(0.0, -20.0)
    p.initial_velocity_min = 25.0
    p.initial_velocity_max = 55.0
    p.scale_amount_min = 2.0
    p.scale_amount_max = 3.5
    p.color = Color(1.0, 0.45, 0.6)
    p.emitting = true
    add_child(p)


func _say(text: String) -> void:
    _whisper = text
    _whisper_show = 1.5


func _update_whisper(delta: float) -> void:
    _whisper_timer -= delta
    if _whisper_timer > 0.0:
        return
    _whisper_timer = randf_range(2.5, 4.5)
    if not friend and absf(_player.global_position.x - global_position.x) > 160.0:
        return
    var pool: Array = WHISPERS_FRIEND if friend else WHISPERS_HOSTILE
    _say(pool[randi() % pool.size()])


func _draw() -> void:
    var squish := 1.0 + sin(_time * 6.0) * 0.06
    var body := Color(0.3, 0.3, 0.38)
    if friend:
        body = FRIEND_COLORS[friend_index % FRIEND_COLORS.size()]
    if _flash > 0.0:
        body = body.lightened(0.5)
    draw_set_transform(Vector2(0.0, 7.0), 0.0, Vector2(1.0 / squish, squish))
    draw_circle(Vector2(0.0, -7.0), 8.0, body)
    if friend:
        draw_circle(Vector2(-3.0, -9.0), 1.6, Color(0.1, 0.1, 0.1))
        draw_circle(Vector2(3.0, -9.0), 1.6, Color(0.1, 0.1, 0.1))
        draw_arc(Vector2(0.0, -6.0), 3.5, 0.3, PI - 0.3, 8, Color(0.1, 0.1, 0.1), 1.0)
    else:
        draw_circle(Vector2(-3.0, -9.0), 2.2, Color(0.95, 0.95, 0.95))
        draw_circle(Vector2(3.0, -9.0), 2.2, Color(0.95, 0.95, 0.95))
        draw_circle(Vector2(-3.0, -9.0), 1.0, Color(0.1, 0.1, 0.1))
        draw_circle(Vector2(3.0, -9.0), 1.0, Color(0.1, 0.1, 0.1))
        draw_line(Vector2(-5.5, -12.5), Vector2(-1.5, -11.0), Color(0.1, 0.1, 0.1), 1.0)
        draw_line(Vector2(5.5, -12.5), Vector2(1.5, -11.0), Color(0.1, 0.1, 0.1), 1.0)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    if _whisper_show > 0.0:
        draw_string(ThemeDB.fallback_font, Vector2(-24.0, -18.0), _whisper, HORIZONTAL_ALIGNMENT_CENTER, 48.0, 8, Color(1.0, 1.0, 1.0, 0.9))
