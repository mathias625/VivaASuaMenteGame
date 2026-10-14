extends Node2D
## Marmelada, o gato laranja da padaria. Foge de quem tem pressa
## e se aproxima de quem fica quieto. Não é missão: ninguém avisa nada.
## O jogador percebe que insistir afasta e esperar aproxima.
## A origem do node é nos pés do gato.

signal trusted

const SaturationShader := preload("res://shaders/saturation.gdshader")
const TEX_CAT := preload("res://assets/animals/MeowingCat.png")
const FRAME := 16
const LEFT_LIMIT := 1735.0
const RIGHT_LIMIT := 2000.0
const BENCH_X := 1972.0
const SHY := 0
const APPROACHED := 1
const TRUSTING := 2

var _state := SHY
var _player: Node2D
var _hud
var _sprite: AnimatedSprite2D
var _material: ShaderMaterial
var _time := 0.0
var _still := 0.0
var _target_x := 0.0
var _fleeing := false
var _scared_hint := false
var _trusting_timer := 0.0
var _purr := 0.0
var _prompt_shown := false


func setup(player: Node2D, hud) -> void:
    _player = player
    _hud = hud


func _ready() -> void:
    _target_x = global_position.x
    _material = ShaderMaterial.new()
    _material.shader = SaturationShader
    _material.set_shader_parameter("saturation", 0.0)
    material = _material

    var frames := SpriteFrames.new()
    frames.remove_animation("default")
    frames.add_animation("cat")
    frames.set_animation_speed("cat", 4.0)
    frames.set_animation_loop("cat", true)
    for i in range(4):
        var tex := AtlasTexture.new()
        tex.atlas = TEX_CAT
        tex.region = Rect2(float(i * FRAME), 0.0, float(FRAME), float(FRAME))
        frames.add_frame("cat", tex)
    _sprite = AnimatedSprite2D.new()
    _sprite.sprite_frames = frames
    _sprite.position = Vector2(0.0, -8.0)   # os pés do gato ficam na base do quadro
    _sprite.use_parent_material = true
    add_child(_sprite)
    _sprite.play("cat")


func _process(delta: float) -> void:
    _time += delta
    _purr = maxf(_purr - delta, 0.0)
    queue_redraw()
    if _player == null:
        return
    var body := _player as CharacterBody2D
    var dx := _player.global_position.x - global_position.x
    var dist := absf(dx)
    var locked := GameState.input_locked
    var moving := absf(body.velocity.x) > 20.0 and not locked
    var still := absf(body.velocity.x) < 5.0 and body.is_on_floor() and not locked

    if _state == SHY:
        _update_shy(delta, dx, dist, moving, still)
    elif _state == TRUSTING:
        _trusting_timer += delta
        if _trusting_timer > 6.0:
            _target_x = BENCH_X

    # Movimento do gato
    var before := global_position.x
    var speed := 95.0 if _fleeing else 45.0
    global_position.x = move_toward(before, _target_x, speed * delta)
    var walking := absf(global_position.x - before) > 0.01
    if walking:
        _sprite.flip_h = _target_x < before
    else:
        _fleeing = false
        _sprite.flip_h = dx < 0.0 and dist < 150.0
    _sprite.speed_scale = 2.0 if walking else 0.6

    # Carinho
    var want_prompt := _state >= APPROACHED and dist < 42.0 and not locked
    if want_prompt != _prompt_shown:
        _prompt_shown = want_prompt
        _hud.call("set_prompt_owner", "gato", "E: fazer carinho no gato" if want_prompt else "")
    if want_prompt and Input.is_action_just_pressed("interact"):
        _pet()


func _update_shy(delta: float, dx: float, dist: float, moving: bool, still: bool) -> void:
    if dist < 70.0 and moving:
        # Quem chega com pressa assusta
        _fleeing = true
        _target_x = clampf(global_position.x - signf(dx) * 90.0, LEFT_LIMIT, RIGHT_LIMIT)
        _still = 0.0
        if not _scared_hint:
            _scared_hint = true
            if GameState.has_seed:
                _hud.call("show_message", "Broto: Ele não gostou da pressa. Acho que gato prefere quem fica quieto.", 5.0)
            else:
                _hud.call("show_message", "O gato se afasta. Parece que não gostou da pressa.", 4.0)
    elif dist < 120.0 and still:
        # Quem fica quieto por um tempo é recebido
        _still += delta
        if _still >= 2.5:
            _state = APPROACHED
            _fleeing = false
            _target_x = _player.global_position.x - signf(dx) * 22.0
    else:
        _still = maxf(_still - delta, 0.0)


func _pet() -> void:
    _purr = 2.0
    Sfx.play("purr", -10.0)
    _hearts()
    if _state == APPROACHED:
        _state = TRUSTING
        _trusting_timer = 0.0
        GameState.cat_stage = 2
        var tween := create_tween()
        tween.tween_property(_material, "shader_parameter/saturation", 1.0, 2.0)
        _hud.call("show_message", "O gato fecha os olhos e começa a ronronar.", 5.0)
        trusted.emit()
    else:
        _hud.call("show_message", "Prrrr.", 2.0)


func _hearts() -> void:
    var p := CPUParticles2D.new()
    p.one_shot = true
    p.amount = 6
    p.lifetime = 1.0
    p.explosiveness = 1.0
    p.position = Vector2(0.0, -14.0)
    p.direction = Vector2(0.0, -1.0)
    p.spread = 50.0
    p.gravity = Vector2(0.0, -10.0)
    p.initial_velocity_min = 10.0
    p.initial_velocity_max = 25.0
    p.scale_amount_min = 2.0
    p.scale_amount_max = 3.0
    p.color = Color(1.0, 0.5, 0.65)
    p.emitting = true
    add_child(p)
    get_tree().create_timer(1.5).timeout.connect(p.queue_free)


func _draw() -> void:
    if _purr > 0.0:
        draw_string(ThemeDB.fallback_font, Vector2(-16.0, -22.0), "prrr", HORIZONTAL_ALIGNMENT_CENTER, 32.0, 8, Color(1.0, 1.0, 1.0, minf(_purr, 1.0)))
