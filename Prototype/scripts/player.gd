extends CharacterBody2D
## Wander. Movimentação com "game feel": aceleração, pulo variável,
## coyote time (pular logo depois de sair da borda) e jump buffer
## (apertar pulo um pouco antes de tocar o chão).

const SPEED := 160.0
const ACCEL := 1200.0
const FRICTION := 1400.0
const JUMP_VELOCITY := -340.0
const GRAVITY := 900.0
const MAX_FALL_SPEED := 500.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER_TIME := 0.12
const JUMP_CUT := 0.45
const FALL_LIMIT_Y := 700.0

var _coyote := 0.0
var _jump_buffer := 0.0
var _facing := 1.0
var _spawn_position := Vector2.ZERO


func _ready() -> void:
    add_to_group("player")
    _spawn_position = position
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(14, 24)
    shape.shape = rect
    add_child(shape)


func _physics_process(delta: float) -> void:
    # --- Horizontal ---
    var dir := Input.get_axis("move_left", "move_right")
    if dir != 0.0:
        velocity.x = move_toward(velocity.x, dir * SPEED, ACCEL * delta)
        _facing = signf(dir)
    else:
        velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

    # --- Gravidade e coyote time ---
    if is_on_floor():
        _coyote = COYOTE_TIME
    else:
        _coyote = maxf(_coyote - delta, 0.0)
        velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

    # --- Pulo (com buffer) ---
    if Input.is_action_just_pressed("jump"):
        _jump_buffer = JUMP_BUFFER_TIME
    else:
        _jump_buffer = maxf(_jump_buffer - delta, 0.0)

    if _jump_buffer > 0.0 and _coyote > 0.0:
        velocity.y = JUMP_VELOCITY
        _jump_buffer = 0.0
        _coyote = 0.0

    # Soltar o botão cedo = pulo mais curto (pulo variável)
    if Input.is_action_just_released("jump") and velocity.y < 0.0:
        velocity.y *= JUMP_CUT

    move_and_slide()

    # Caiu no buraco? Volta ao início, sem punição.
    if position.y > FALL_LIMIT_Y:
        position = _spawn_position
        velocity = Vector2.ZERO

    queue_redraw()


func _draw() -> void:
    # Visual provisório: troque por AnimatedSprite2D quando tiver os assets.
    draw_rect(Rect2(-7, -12, 14, 24), Color(0.9, 0.6, 0.35))
    draw_rect(Rect2(-7, -2, 14, 4), Color(0.8, 0.25, 0.25))
    var eye_x := 2.0 if _facing > 0.0 else -5.0
    draw_rect(Rect2(eye_x, -7, 3, 3), Color(0.1, 0.1, 0.1))
