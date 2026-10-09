extends CharacterBody2D
## Wander, o protagonista.
## Andar, pular (coyote time + jump buffer), Esquiva (K), Acolher (J)
## e Descansar (segurar S). As habilidades são liberadas pela história.

signal breath_changed(current: int, maximum: int)
signal fainted

const SPEED := 170.0
const ACCEL := 1300.0
const FRICTION := 1500.0
const JUMP_VELOCITY := -310.0    # pulo mais baixo (antes: -340)
const GRAVITY := 1000.0
const MAX_FALL_SPEED := 520.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER_TIME := 0.12
const JUMP_CUT := 0.5
const FALL_LIMIT_Y := 700.0

const DASH_SPEED := 380.0
const DASH_TIME := 0.2
const DASH_COOLDOWN := 0.6
const DASH_IFRAMES := 0.35

const LOVE_COOLDOWN := 0.4
const LOVE_ANIM_TIME := 0.25
const LOVE_BASE_RANGE := 30.0

const INVULN_TIME := 1.2

var facing := 1.0
var breath := 4

var _coyote := 0.0
var _jump_buffer := 0.0
var _dash_time := 0.0
var _dash_cooldown := 0.0
var _love_cooldown := 0.0
var _love_anim := 0.0
var _invuln := 0.0
var _hurt_lock := 0.0
var _rest_time := 0.0
var _resting := false
var _walk_time := 0.0
var _time := 0.0
var _squash := Vector2.ONE
var _dust: CPUParticles2D
var _love_fx: CPUParticles2D


func _ready() -> void:
    add_to_group("player")
    collision_layer = 2   # jogador
    collision_mask = 1    # só colide com o cenário
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(14.0, 24.0)
    shape.shape = rect
    add_child(shape)

    _dust = _make_particles(8, 0.35, Color(0.85, 0.85, 0.85, 0.8), 20.0, 50.0, 70.0, Vector2(0.0, 200.0))
    _dust.position = Vector2(0.0, 12.0)
    _love_fx = _make_particles(7, 0.45, Color(1.0, 0.45, 0.6), 40.0, 80.0, 180.0, Vector2(0.0, -30.0))
    breath = GameState.max_breath()


func _make_particles(amount: int, lifetime: float, color: Color, speed_min: float, speed_max: float, spread: float, gravity: Vector2) -> CPUParticles2D:
    var p := CPUParticles2D.new()
    p.emitting = false
    p.one_shot = true
    p.amount = amount
    p.lifetime = lifetime
    p.explosiveness = 1.0
    p.local_coords = false
    p.direction = Vector2(0.0, -1.0)
    p.spread = spread
    p.gravity = gravity
    p.initial_velocity_min = speed_min
    p.initial_velocity_max = speed_max
    p.scale_amount_min = 1.5
    p.scale_amount_max = 3.0
    p.color = color
    add_child(p)
    return p


func _physics_process(delta: float) -> void:
    _tick_timers(delta)
    var locked := GameState.input_locked
    var dir := 0.0
    if not locked:
        dir = Input.get_axis("move_left", "move_right")

    if _dash_time > 0.0:
        _dash_time -= delta
        velocity = Vector2(facing * DASH_SPEED, 0.0)
    else:
        _move(delta, dir, locked)

    if not locked:
        _handle_actions()

    var was_on_floor := is_on_floor()
    var fall_speed := velocity.y
    move_and_slide()
    if is_on_floor() and not was_on_floor and fall_speed > 120.0:
        _squash = Vector2(1.3, 0.72)
        _puff()

    _animate(delta)
    if position.y > FALL_LIMIT_Y:
        _respawn()
    queue_redraw()


func _tick_timers(delta: float) -> void:
    _invuln = maxf(_invuln - delta, 0.0)
    _dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
    _love_cooldown = maxf(_love_cooldown - delta, 0.0)
    _love_anim = maxf(_love_anim - delta, 0.0)
    _hurt_lock = maxf(_hurt_lock - delta, 0.0)


func _move(delta: float, dir: float, locked: bool) -> void:
    # Descansar: parado no chão, segurando S (liberado depois do chefe)
    var resting := false
    if not locked and GameState.can_rest and is_on_floor() and Input.is_action_pressed("rest") and absf(dir) < 0.1 and _hurt_lock <= 0.0:
        resting = true
    _resting = resting
    if resting:
        dir = 0.0
        _rest_time += delta
        if _rest_time >= 1.0:
            _rest_time = 0.0
            refresh_breath(1)
    else:
        _rest_time = 0.0

    if _hurt_lock > 0.0:
        dir = 0.0
    if dir != 0.0:
        velocity.x = move_toward(velocity.x, dir * SPEED, ACCEL * delta)
        facing = signf(dir)
    else:
        velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

    if is_on_floor():
        _coyote = COYOTE_TIME
    else:
        _coyote = maxf(_coyote - delta, 0.0)
        velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

    if not locked and not resting and Input.is_action_just_pressed("jump"):
        _jump_buffer = JUMP_BUFFER_TIME
    else:
        _jump_buffer = maxf(_jump_buffer - delta, 0.0)

    if _jump_buffer > 0.0 and _coyote > 0.0:
        velocity.y = JUMP_VELOCITY
        _jump_buffer = 0.0
        _coyote = 0.0
        _squash = Vector2(0.75, 1.3)
        _puff()

    # Soltar o botão cedo = pulo mais curto
    if not locked and Input.is_action_just_released("jump") and velocity.y < 0.0:
        velocity.y *= JUMP_CUT


func _handle_actions() -> void:
    if GameState.can_love and Input.is_action_just_pressed("attack") and _love_cooldown <= 0.0:
        _do_love()
    if GameState.can_dash and Input.is_action_just_pressed("dash") and _dash_cooldown <= 0.0 and _dash_time <= 0.0:
        _start_dash()


func _start_dash() -> void:
    _resting = false
    _dash_time = DASH_TIME
    _dash_cooldown = DASH_COOLDOWN
    _invuln = maxf(_invuln, DASH_IFRAMES)
    velocity = Vector2(facing * DASH_SPEED, 0.0)
    _squash = Vector2(1.35, 0.75)
    _puff()


func love_range() -> float:
    # Depois do fio dourado do Tarcísio (estágio 4), o alcance aumenta.
    if GameState.stage >= 4:
        return LOVE_BASE_RANGE + 12.0
    return LOVE_BASE_RANGE


func _do_love() -> void:
    _love_cooldown = LOVE_COOLDOWN
    _love_anim = LOVE_ANIM_TIME
    _love_fx.position = Vector2(facing * 14.0, 0.0)
    _love_fx.restart()
    _love_fx.emitting = true
    var origin := global_position + Vector2(facing * 14.0, 0.0)
    var reach := love_range()
    for node in get_tree().get_nodes_in_group("lovable"):
        var target := node as Node2D
        if target == null:
            continue
        var radius: float = target.get("love_radius")
        if target.global_position.distance_to(origin) <= reach + radius:
            target.call("receive_love", 1, global_position)


func take_hit(from_x: float, damage: int = 1) -> void:
    if _invuln > 0.0 or GameState.input_locked:
        return
    breath -= damage
    _invuln = INVULN_TIME
    _hurt_lock = 0.25
    var push := signf(global_position.x - from_x)
    if push == 0.0:
        push = -facing
    velocity = Vector2(push * 200.0, -170.0)
    _squash = Vector2(1.3, 0.75)
    breath_changed.emit(breath, GameState.max_breath())
    if breath <= 0:
        fainted.emit()
        _respawn()
        refresh_breath(99)


func refresh_breath(heal: int = 0) -> void:
    var maximum := GameState.max_breath()
    breath = clampi(breath + heal, 0, maximum)
    breath_changed.emit(breath, maximum)


func _respawn() -> void:
    # Sem punição: volta ao último checkpoint.
    position = GameState.checkpoint
    velocity = Vector2.ZERO
    _dash_time = 0.0
    _invuln = 1.0


func _puff() -> void:
    _dust.restart()
    _dust.emitting = true


func _animate(delta: float) -> void:
    _time += delta
    _squash = _squash.lerp(Vector2.ONE, minf(delta * 12.0, 1.0))
    if is_on_floor():
        _walk_time += delta * absf(velocity.x) / SPEED


func _draw() -> void:
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    if _love_anim > 0.0:
        var t := 1.0 - _love_anim / LOVE_ANIM_TIME
        var radius := lerpf(6.0, love_range() + 8.0, t)
        var start_angle := -1.1 if facing > 0.0 else PI - 1.1
        draw_arc(Vector2(facing * 14.0, 0.0), radius, start_angle, start_angle + 2.2, 14, Color(1.0, 0.55, 0.65, 1.0 - t), 2.0)
    if _resting:
        draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.9, 0.5, 0.18))
    if _invuln > 0.0 and _dash_time <= 0.0 and int(_invuln * 16.0) % 2 == 0:
        return

    # Corpo desenhado a partir dos pés (para o squash & stretch)
    draw_set_transform(Vector2(0.0, 12.0), 0.0, _squash)
    var f := facing
    var swing := 0.0
    if is_on_floor():
        swing = sin(_walk_time * 14.0) * 3.0
    var leg_color := Color(0.35, 0.28, 0.25)
    draw_rect(Rect2(-5.0 + swing, -6.0, 4.0, 6.0), leg_color)
    draw_rect(Rect2(1.0 - swing, -6.0, 4.0, 6.0), leg_color)
    draw_rect(Rect2(-7.0, -16.0, 14.0, 10.0), Color(0.9, 0.6, 0.35))
    draw_circle(Vector2(0.0, -19.0), 5.5, Color(0.96, 0.82, 0.68))
    draw_rect(Rect2(-5.5, -25.0, 11.0, 3.5), Color(0.25, 0.18, 0.15))
    if _resting:
        draw_line(Vector2(f * 2.5 - 1.5, -19.0), Vector2(f * 2.5 + 1.5, -19.0), Color(0.1, 0.1, 0.1), 1.0)
    else:
        draw_rect(Rect2(f * 2.5 - 1.0, -20.0, 2.0, 2.5), Color(0.1, 0.1, 0.1))

    # Cachecol: cresce a cada laço e fica dourado no estágio 4
    var scarf := Color(0.8, 0.25, 0.25)
    if GameState.stage >= 4:
        scarf = Color(1.0, 0.75, 0.25)
    var tail := 6.0 + float(GameState.bonds) * 4.0
    var wave := sin(_time * 9.0) * 2.0 - clampf(velocity.y * 0.015, -3.0, 3.0)
    draw_rect(Rect2(-7.0, -16.0, 14.0, 3.0), scarf)
    draw_line(Vector2(-f * 5.0, -14.0), Vector2(-f * (5.0 + tail), -14.0 + wave), scarf, 3.0)

    # Pequena luz que orbita Wander depois que ele aprende a acolher
    if GameState.can_love:
        draw_circle(Vector2(sin(_time * 2.0) * 11.0, -32.0 + cos(_time * 2.0) * 3.0), 2.5, Color(1.0, 0.9, 0.4))
