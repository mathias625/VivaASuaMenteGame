extends Node2D
## Eco da Insônia (mini-chefe).
## Ela não é vencida com força: só dá para acolher (J) quando ela BOCEJA.
## Entre os bocejos, ela ataca em padrões que dá para aprender:
##   Fase 1: contagem de ovelhas (pule ou use a esquiva)
##   Fase 2: ovelhas dos dois lados, pensamentos acelerados e o relógio
##   Fase 3: relógio duplo e combos de ovelhas + pensamentos (use a ESQUIVA)
## No fim ela adormece, o dia amanhece e o mundo ganha cor.

signal activated
signal defeated

const SaturationShader := preload("res://shaders/saturation.gdshader")
const ProjectileScript := preload("res://scripts/projectile.gd")
const CHARGE_SPEED := 400.0

enum State { WAITING, ATTACK, YAWN, SLEEPING }

var love_radius := 46.0
var hp := 22
var max_hp := 22

var _state := State.WAITING
var _player: Node2D
var _hud
var _left := 0.0
var _right := 0.0
var _floor_y := 400.0
var _home := Vector2.ZERO
var _time := 0.0
var _flash := 0.0
var _shake := 0.0
var _counter_text := ""
var _charging := false
var _cycle := 0
var _fight_started := false
var _hinted_yawn := false
var _hinted_charge := false
var _warned := false
var _material: ShaderMaterial


func setup(player: Node2D, hud, left: float, right: float, floor_y: float) -> void:
    _player = player
    _hud = hud
    _left = left
    _right = right
    _floor_y = floor_y
    _home = Vector2((left + right) / 2.0, floor_y - 50.0)
    position = _home
    _material = ShaderMaterial.new()
    _material.shader = SaturationShader
    _material.set_shader_parameter("saturation", 0.0)
    material = _material
    add_to_group("lovable")


func start_fight() -> void:
    if _fight_started:
        return
    _fight_started = true
    activated.emit()
    _hud.call("show_boss", "Eco da Insônia")
    _hud.call("set_boss", 1.0)
    _fight_loop()


func colorize() -> void:
    var tween := create_tween()
    tween.tween_property(_material, "shader_parameter/saturation", 1.0, 4.0)


func _phase() -> int:
    if hp > 12:
        return 1
    if hp > 6:
        return 2
    return 3


# ---------- Luta ----------

func _fight_loop() -> void:
    await _wait(1.2)
    while hp > 0:
        _state = State.ATTACK
        var phase := _phase()
        if phase == 1:
            await _attack_sheep(4)
        elif phase == 2:
            match _cycle % 3:
                0:
                    await _attack_rain(3, false)
                1:
                    await _attack_sheep(5)
                _:
                    await _attack_charge(1)
        else:
            match _cycle % 3:
                0:
                    await _attack_charge(2)
                1:
                    await _attack_rain(3, true)
                _:
                    await _attack_rain(4, false)
        _cycle += 1
        if hp <= 0:
            break
        # Janela para acolher: fica mais curta a cada fase
        await _yawn(2.2 - 0.25 * float(phase))


func _wait(seconds: float) -> void:
    await get_tree().create_timer(seconds).timeout


func _move_to(target: Vector2, seconds: float) -> void:
    var tween := create_tween()
    tween.tween_property(self, "position", target, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    await tween.finished


func _spawn_sheep(x: float, dir: float) -> void:
    var sheep: Node2D = ProjectileScript.new()
    sheep.call("setup_sheep", _player, Vector2(x, _floor_y - 9.0), dir, 125.0 + 25.0 * float(_phase()), _left - 40.0, _right + 40.0)
    get_parent().add_child(sheep)


func _attack_sheep(count: int) -> void:
    var phase := _phase()
    var from_right := _player.global_position.x < _home.x
    var start_x := _right - 30.0 if from_right else _left + 30.0
    var dir := -1.0 if from_right else 1.0
    await _move_to(Vector2(start_x, _floor_y - 100.0), 0.6)
    for i in range(count):
        _counter_text = str(i + 1)
        await _wait(0.45)
        # A partir da fase 2, algumas ovelhas vêm do lado oposto
        var side_dir := dir
        var x := start_x
        if phase >= 2 and i % 2 == 1:
            side_dir = -dir
            x = _left + 30.0 if dir < 0.0 else _right - 30.0
        _spawn_sheep(x, side_dir)
        # Ritmo irregular: não dá para pular no automático
        await _wait(randf_range(0.3, 0.75))
    _counter_text = ""
    await _wait(1.4)


func _attack_rain(waves: int, with_sheep: bool) -> void:
    await _move_to(_home + Vector2(0.0, -70.0), 0.5)
    var orbs := 2 + _phase()   # fase 1: 3, fase 2: 4, fase 3: 5
    for w in range(waves):
        _counter_text = "..."
        var xs: Array = [clampf(_player.global_position.x, _left + 30.0, _right - 30.0)]
        var tries := 0
        while xs.size() < orbs and tries < 60:
            tries += 1
            var candidate := randf_range(_left + 40.0, _right - 40.0)
            var ok := true
            for other in xs:
                if absf(candidate - float(other)) < 70.0:
                    ok = false
            if ok:
                xs.append(candidate)
        for px in xs:
            var orb: Node2D = ProjectileScript.new()
            orb.call("setup_orb", _player, float(px), _floor_y, 0.65)
            get_parent().add_child(orb)
        if with_sheep:
            var from_left := w % 2 == 0
            _spawn_sheep(_left + 30.0 if from_left else _right - 30.0, 1.0 if from_left else -1.0)
        await _wait(1.3)
    _counter_text = ""
    await _wait(0.5)


func _attack_charge(times: int) -> void:
    var from_right := _player.global_position.x < _home.x
    var start_x := _right - 36.0 if from_right else _left + 36.0
    var end_x := _left + 36.0 if from_right else _right - 36.0
    await _move_to(Vector2(start_x, _floor_y - 36.0), 0.5)
    if not _hinted_charge:
        _hinted_charge = true
        _hud.call("show_message", "Broto: Ela vai investir! Esquiva (K) na hora certa!", 4.0)
    for pass_index in range(times):
        # Tic... tac... (a segunda investida tem aviso mais curto)
        for i in range(3 if pass_index == 0 else 2):
            _counter_text = "tic" if i % 2 == 0 else "tac"
            _shake = 0.15
            await _wait(0.35)
        _counter_text = ""
        _charging = true
        var travel := absf(end_x - start_x) / CHARGE_SPEED
        var tween := create_tween()
        tween.tween_property(self, "position:x", end_x, travel)
        await tween.finished
        _charging = false
        _shake = 0.3
        await _wait(0.25)
        var tmp := start_x
        start_x = end_x
        end_x = tmp
    await _wait(0.3)


func _yawn(seconds: float) -> void:
    await _move_to(_home, 0.6)
    if hp <= 0:
        return
    _state = State.YAWN
    if not _hinted_yawn:
        _hinted_yawn = true
        _hud.call("show_message", "Broto: Ela bocejou! Agora, Acolher (J)!", 4.0)
    await _wait(seconds)
    if _state == State.YAWN:
        _state = State.ATTACK


func receive_love(amount: int, _from_pos: Vector2) -> void:
    if _state != State.YAWN:
        if _state == State.ATTACK and not _warned:
            _warned = true
            _hud.call("show_message", "Broto: Ela está agitada demais. Espere o bocejo!", 4.0)
        return
    hp = maxi(hp - amount, 0)
    _flash = 0.2
    _shake = 0.12
    _hud.call("set_boss", float(hp) / float(max_hp))
    if hp <= 0:
        _defeat()


func _defeat() -> void:
    _state = State.SLEEPING
    _charging = false
    _counter_text = ""
    _hud.call("hide_boss")
    for node in get_tree().get_nodes_in_group("hazard"):
        node.queue_free()
    var tween := create_tween()
    tween.tween_property(self, "position", Vector2(_home.x, _floor_y - 36.0), 2.0).set_trans(Tween.TRANS_SINE)
    defeated.emit()


# ---------- Atualização e desenho ----------

func _process(delta: float) -> void:
    _time += delta
    _flash = maxf(_flash - delta, 0.0)
    _shake = maxf(_shake - delta, 0.0)
    if _charging and _player.global_position.distance_to(global_position) < 40.0:
        _player.call("take_hit", global_position.x, 2)   # a investida dói mais
    queue_redraw()


func _draw() -> void:
    var bob := sin(_time * 2.0) * 3.0
    var shake_off := Vector2.ZERO
    if _shake > 0.0:
        shake_off = Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
    var c := Vector2(0.0, bob) + shake_off
    var sleeping := _state == State.SLEEPING
    var yawning := _state == State.YAWN
    var r := 34.0 if _charging else 46.0

    var body_col := Color(0.27, 0.29, 0.5)
    if sleeping:
        body_col = Color(0.62, 0.55, 0.88)
    elif yawning:
        body_col = Color(0.36, 0.38, 0.6)
    if _flash > 0.0:
        body_col = body_col.lightened(0.5)
    draw_circle(c, r, body_col)
    draw_circle(c + Vector2(-r * 0.25, -r * 0.25), r * 0.62, body_col.lightened(0.07))

    var look := Vector2.ZERO
    if _player != null:
        look = (_player.global_position - global_position).limit_length(1.0) * 3.0
    var eye_dx := r * 0.36
    var eye_y := -r * 0.12
    for side in [-1.0, 1.0]:
        var eye := c + Vector2(float(side) * eye_dx, eye_y)
        if sleeping or yawning:
            draw_line(eye + Vector2(-8.0, 0.0), eye + Vector2(8.0, 0.0), Color(0.08, 0.08, 0.15), 2.0)
        else:
            draw_circle(eye, 11.0, Color(0.97, 0.97, 1.0))
            draw_circle(eye + look, 4.5, Color(0.1, 0.1, 0.2))
        draw_arc(eye + Vector2(0.0, 10.0), 10.0, 0.25, PI - 0.25, 10, Color(0.4, 0.3, 0.6), 3.0)

    if yawning:
        draw_circle(c + Vector2(0.0, r * 0.42), 11.0, Color(0.12, 0.08, 0.18))
    elif sleeping:
        draw_arc(c + Vector2(0.0, r * 0.3), 8.0, 0.3, PI - 0.3, 10, Color(0.15, 0.1, 0.25), 2.0)

    var font := ThemeDB.fallback_font
    if _counter_text != "":
        draw_string(font, c + Vector2(-30.0, -r - 8.0), _counter_text, HORIZONTAL_ALIGNMENT_CENTER, 60.0, 18, Color(1.0, 1.0, 1.0))
    if yawning or sleeping:
        draw_string(font, c + Vector2(r * 0.6, -r * 0.6 + sin(_time * 3.0) * 3.0), "z z", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(1.0, 1.0, 1.0, 0.9))
