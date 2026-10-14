extends CharacterBody2D
## Wander, o protagonista (skin: Ozzbit Games, veja CREDITS.txt).
## Andar, pular (coyote time + jump buffer), Esquiva (K), Acolher (J)
## e Descansar (segurar S). As habilidades são liberadas pela história.

signal breath_changed(current: int, maximum: int)
signal fainted

const FRAME_SIZE := 128
const TEX_IDLE := preload("res://assets/hero/male_hero_template-idle.png")
const TEX_WALK := preload("res://assets/hero/male_hero_template-walk.png")
const TEX_RUN := preload("res://assets/hero/male_hero_template-run.png")
const TEX_JUMP := preload("res://assets/hero/male_hero_template-jump.png")
const TEX_FALL := preload("res://assets/hero/male_hero_template-fall.png")
const TEX_FALL_LOOP := preload("res://assets/hero/male_hero_template-fall_loop.png")
const TEX_LOVE := preload("res://assets/hero/male_hero_template-combo_1.png")

const HALF_HEIGHT := 15.0        # a caixa de colisão tem 14 x 30
const SPEED := 170.0
const ACCEL := 1300.0
const FRICTION := 1500.0
const JUMP_VELOCITY := -310.0
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
var _time := 0.0
var _squash := Vector2.ONE
var _cutscene_anim := ""
var _visual: Node2D
var _sprite: AnimatedSprite2D
var _dust: CPUParticles2D
var _love_fx: CPUParticles2D


func _ready() -> void:
    add_to_group("player")
    collision_layer = 2   # jogador
    collision_mask = 1    # só colide com o cenário
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(14.0, HALF_HEIGHT * 2.0)
    shape.shape = rect
    add_child(shape)

    # Visual: um nó nos pés (para o squash & stretch) com o sprite dentro.
    # O sprite usa o material do jogador, então continua obedecendo ao
    # shader de cinza -> cor.
    _visual = Node2D.new()
    _visual.position = Vector2(0.0, HALF_HEIGHT)
    _visual.use_parent_material = true
    add_child(_visual)
    _sprite = AnimatedSprite2D.new()
    _sprite.sprite_frames = _build_frames()
    _sprite.position = Vector2(0.0, -16.0)   # os pés estão 16 px abaixo do centro do quadro
    _sprite.use_parent_material = true
    _visual.add_child(_sprite)
    _sprite.play("idle")

    _dust = _make_particles(8, 0.35, Color(0.85, 0.85, 0.85, 0.8), 20.0, 50.0, 70.0, Vector2(0.0, 200.0))
    _dust.position = Vector2(0.0, HALF_HEIGHT)
    _love_fx = _make_particles(7, 0.45, Color(1.0, 0.45, 0.6), 40.0, 80.0, 180.0, Vector2(0.0, -30.0))
    breath = GameState.max_breath()


func _build_frames() -> SpriteFrames:
    var frames := SpriteFrames.new()
    frames.remove_animation("default")
    _add_anim(frames, "idle", TEX_IDLE, 8.0, true)
    _add_anim(frames, "walk", TEX_WALK, 12.0, true)
    _add_anim(frames, "run", TEX_RUN, 14.0, true)
    _add_anim(frames, "jump", TEX_JUMP, 14.0, false)
    _add_anim(frames, "fall", TEX_FALL, 12.0, false)
    _add_anim(frames, "fall_loop", TEX_FALL_LOOP, 10.0, true)
    _add_anim(frames, "love", TEX_LOVE, 12.0, false)
    return frames


func _add_anim(frames: SpriteFrames, anim: String, sheet: Texture2D, fps: float, loop: bool) -> void:
    frames.add_animation(anim)
    frames.set_animation_speed(anim, fps)
    frames.set_animation_loop(anim, loop)
    var count := sheet.get_width() / FRAME_SIZE
    for i in range(count):
        var tex := AtlasTexture.new()
        tex.atlas = sheet
        tex.region = Rect2(float(i * FRAME_SIZE), 0.0, float(FRAME_SIZE), float(FRAME_SIZE))
        frames.add_frame(anim, tex)


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


## Usado em cenas (ex.: o abraço): força uma animação. "" devolve o controle.
func set_cutscene_anim(anim: String) -> void:
    _cutscene_anim = anim


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
        _squash = Vector2(0.8, 1.25)
        _puff()
        Sfx.play("jump", -14.0)

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
    _squash = Vector2(1.3, 0.8)
    _puff()
    Sfx.play("dash", -8.0)


func love_range() -> float:
    # Depois do fio dourado do Tarcísio (estágio 4), o alcance aumenta.
    if GameState.stage >= 6:
        return LOVE_BASE_RANGE + 18.0
    if GameState.stage >= 4:
        return LOVE_BASE_RANGE + 12.0
    return LOVE_BASE_RANGE


func _do_love() -> void:
    _love_cooldown = LOVE_COOLDOWN
    _love_anim = LOVE_ANIM_TIME
    Sfx.play("love", -8.0)
    _sprite.stop()
    _sprite.play("love")
    _love_fx.position = Vector2(facing * 16.0, 0.0)
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
    Sfx.play("hit")
    _hurt_lock = 0.25
    var push := signf(global_position.x - from_x)
    if push == 0.0:
        push = -facing
    velocity = Vector2(push * 200.0, -170.0)
    _squash = Vector2(1.25, 0.8)
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
    _visual.scale = _squash
    var blink := _invuln > 0.0 and _dash_time <= 0.0 and int(_invuln * 16.0) % 2 == 0
    _sprite.modulate.a = 0.35 if blink else 1.0
    _update_animation()


func _update_animation() -> void:
    _sprite.flip_h = facing < 0.0   # o sprite original olha para a direita
    var anim := "idle"
    var speed_scale := 1.0
    if _cutscene_anim != "":
        anim = _cutscene_anim
    elif _love_anim > 0.0:
        anim = "love"
    elif _dash_time > 0.0:
        anim = "run"
        speed_scale = 2.0
    elif not is_on_floor():
        if velocity.y < 0.0:
            anim = "jump"
        elif _sprite.animation == "fall" and not _sprite.is_playing():
            anim = "fall_loop"
        elif _sprite.animation == "fall_loop":
            anim = "fall_loop"
        else:
            anim = "fall"
    elif _resting:
        speed_scale = 0.4
    elif absf(velocity.x) > 110.0:
        anim = "run"
    elif absf(velocity.x) > 12.0:
        anim = "walk"
    _sprite.speed_scale = speed_scale
    if _sprite.animation != anim:
        _sprite.play(anim)


func _draw() -> void:
    # Efeitos desenhados ATRÁS do sprite
    if _love_anim > 0.0:
        var t := 1.0 - _love_anim / LOVE_ANIM_TIME
        var radius := lerpf(6.0, love_range() + 8.0, t)
        var start_angle := -1.1 if facing > 0.0 else PI - 1.1
        draw_arc(Vector2(facing * 14.0, 0.0), radius, start_angle, start_angle + 2.2, 14, Color(1.0, 0.55, 0.65, 1.0 - t), 2.0)
    if _resting:
        draw_circle(Vector2(0.0, 2.0), 20.0, Color(1.0, 0.9, 0.5, 0.18))
    # Estágio 4 (fio dourado): uma aura dourada discreta
    if GameState.stage >= 4:
        draw_circle(Vector2(0.0, 0.0), 20.0 + sin(_time * 3.0) * 1.5, Color(1.0, 0.85, 0.4, 0.12))
    # Estágio 6 (depois da Solidão): uma pequena lanterna de luz própria
    if GameState.stage >= 6:
        draw_circle(Vector2(0.0, -4.0), 30.0 + sin(_time * 2.0) * 2.0, Color(1.0, 0.9, 0.55, 0.1))
        draw_arc(Vector2(0.0, -4.0), 24.0, 0.0, TAU, 28, Color(1.0, 0.9, 0.55, 0.35), 1.0)
    # Depois de aprender a acolher, uma luzinha passa a orbitar o Wander
    if GameState.can_love:
        draw_circle(Vector2(sin(_time * 2.0) * 16.0, -26.0 + cos(_time * 2.0) * 4.0), 2.5, Color(1.0, 0.9, 0.4))
