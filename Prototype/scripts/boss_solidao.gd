extends Node2D
## Eco da Solidão (segundo chefe), na praça abandonada.
##
## Ela se afasta de quem chega perto: não adianta correr atrás. O jeito é
## CONECTAR: uma silhueta sentada num banco brilha e pede companhia. Acolher (J)
## essa pessoa abre uma janela em que a Solidão para de fugir, e só então dá
## para acolhê-la (J) também. Nada desaparece de uma vez: a Solidão se encolhe
## e senta junto, sem prometer que não volta amanhã.
##
## Ataques (todos com aviso visual antes do dano):
##   - Onda de sombra no chão (pule ou use a esquiva)
##   - Vazio: manchas no chão que aparecem e somem (saia de cima ou suba numa caixa)
##   - Fase 2: ela some e reaparece do outro lado; fase 3: ondas dos dois lados

signal activated
signal defeated

const SaturationShader := preload("res://shaders/saturation.gdshader")
const HazardScript := preload("res://scripts/hazard.gd")

enum State { WAITING, FIGHT, OPEN, DONE }

const WINDOW_TIME := 6.0

var love_radius := 46.0
var hp := 15
var max_hp := 15

var _state := State.WAITING
var _player: Node2D
var _hud
var _left := 0.0
var _right := 0.0
var _floor_y := 400.0
var _home := Vector2.ZERO
var _silhouettes: Array = []
var _rotation := 0
var _connected := false
var _pattern_index := 0
var _pending_time := 0.0
var _time := 0.0
var _flash := 0.0
var _shake := 0.0
var _alpha := 1.0
var _tint := 0.0
var _lean := 0.0
var _hinted_pending := false
var _hinted_far := false
var _hinted_open := false
var _said_phase2 := false
var _said_phase3 := false
var _fight_started := false
var _material: ShaderMaterial


func setup(player: Node2D, hud, left: float, right: float, floor_y: float, silhouettes: Array) -> void:
    _player = player
    _hud = hud
    _left = left
    _right = right
    _floor_y = floor_y
    _home = Vector2((left + right) / 2.0, floor_y - 52.0)
    position = Vector2(right - 60.0, floor_y - 74.0)
    _silhouettes = silhouettes
    for s in _silhouettes:
        s.connect("connected", _on_silhouette_connected)
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
    _hud.call("show_title", "ECO DA SOLIDÃO", 2.4)
    _hud.call("show_boss", "Eco da Solidão", [10.0 / 15.0, 5.0 / 15.0])
    _hud.call("set_boss", 1.0)
    _fight_loop()


func colorize() -> void:
    var tween := create_tween()
    tween.tween_property(_material, "shader_parameter/saturation", 1.0, 4.0)


func _phase() -> int:
    if hp > 10:
        return 1
    if hp > 5:
        return 2
    return 3


func _phase_floor() -> int:
    if hp > 10:
        return 10
    if hp > 5:
        return 5
    return 0


# ---------- Estrutura da luta ----------

func _fight_loop() -> void:
    _state = State.FIGHT
    await _wait(1.8)
    while hp > 0:
        var floor_hp := _phase_floor()
        _begin_connection()
        while hp > floor_hp and hp > 0:
            if _connected:
                await _open_window(floor_hp)
                _connected = false
                if hp > floor_hp and hp > 0:
                    _begin_connection()
            else:
                await _next_pattern()


func _wait(seconds: float) -> void:
    await get_tree().create_timer(seconds).timeout


func _move_to(target: Vector2, seconds: float) -> void:
    var tween := create_tween()
    tween.tween_property(self, "position", target, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    await tween.finished


func _blink_to(target: Vector2) -> void:
    Sfx.play("shadow", -10.0)
    var fade_out := create_tween()
    fade_out.tween_property(self, "_alpha", 0.0, 0.25)
    await fade_out.finished
    position = target
    var fade_in := create_tween()
    fade_in.tween_property(self, "_alpha", 1.0, 0.35)
    await fade_in.finished


func _far_side() -> Vector2:
    var x := _right - 60.0 if _player.global_position.x < _home.x else _left + 60.0
    return Vector2(x, _floor_y - 74.0)


func _begin_connection() -> void:
    _connected = false
    _pending_time = 0.0
    for s in _silhouettes:
        s.call("set_pending", false)
    var index := _rotation % _silhouettes.size()
    _rotation += 1
    _silhouettes[index].call("set_pending", true)


func _on_silhouette_connected() -> void:
    _connected = true
    Sfx.play("pickup")


func _open_window(floor_hp: int) -> void:
    _state = State.OPEN
    for s in _silhouettes:
        s.call("set_pending", false)
    Sfx.play("color")
    if not _hinted_open:
        _hinted_open = true
        _hud.call("show_message", "Broto: Ela parou de fugir! Agora, acolher (J)!", 5.0)
    var warm := create_tween()
    warm.tween_property(self, "_tint", 0.6, 0.6)
    await _move_to(_home, 0.7)
    var t := 0.0
    while t < WINDOW_TIME and hp > floor_hp and hp > 0:
        await get_tree().create_timer(0.1).timeout
        t += 0.1
    if hp <= 0:
        return
    _state = State.FIGHT
    for s in _silhouettes:
        s.call("dim")
    var cool := create_tween()
    cool.tween_property(self, "_tint", 0.0, 0.8)
    await _blink_to(_far_side())


func _next_pattern() -> void:
    # Quem corre atrás dela só a faz recuar
    if absf(_player.global_position.x - global_position.x) < 140.0:
        if not _hinted_far:
            _hinted_far = true
            _hud.call("show_message", "A Solidão se afasta de quem chega com pressa. Dá pra ser alcançada só com ajuda.", 5.0)
        await _blink_to(_far_side())
    _pattern_index += 1
    match _phase():
        1:
            if _pattern_index % 2 == 0:
                await _pattern_voids(2)
            else:
                await _pattern_wave(1, false)
        2:
            match _pattern_index % 3:
                0:
                    await _pattern_voids(3)
                1:
                    await _pattern_wave(2, true)
                _:
                    await _pattern_blink_wave()
        _:
            match _pattern_index % 3:
                0:
                    await _pattern_double_wave()
                1:
                    await _pattern_voids(4)
                _:
                    await _pattern_wave(3, true)
    await _wait(0.8)


# ---------- Ataques ----------

func _spawn_wave(x: float, dir: float, warn: float) -> void:
    var wave: Node2D = HazardScript.new()
    wave.call("setup_wave", _player, x, dir, 105.0 + 12.0 * float(_phase()), _floor_y, _left - 40.0, _right + 40.0, warn)
    get_parent().add_child(wave)


func _pattern_wave(count: int, alternate: bool) -> void:
    for i in range(count):
        var from_right := (i % 2 == 0) if alternate else (_player.global_position.x < _home.x)
        var start_x := _right - 20.0 if from_right else _left + 20.0
        var dir := -1.0 if from_right else 1.0
        await _move_to(Vector2(start_x, _floor_y - 74.0), 0.5)
        _lean = dir
        Sfx.play("warn")
        _spawn_wave(start_x, dir, 0.8)
        await _wait(1.0)
        _lean = 0.0


func _pattern_voids(count: int) -> void:
    await _move_to(Vector2(_home.x, _floor_y - 96.0), 0.5)
    var xs: Array = [clampf(_player.global_position.x, _left + 40.0, _right - 40.0)]
    var tries := 0
    while xs.size() < count and tries < 60:
        tries += 1
        var candidate := randf_range(_left + 50.0, _right - 50.0)
        var ok := true
        for other in xs:
            if absf(candidate - float(other)) < 100.0:
                ok = false
        if ok:
            xs.append(candidate)
    var warn := 1.0 if _phase() == 1 else 0.85
    Sfx.play("warn")
    for px in xs:
        var zone: Node2D = HazardScript.new()
        zone.call("setup_void", _player, float(px), 38.0, _floor_y, warn, 1.4)
        get_parent().add_child(zone)
    await _wait(warn + 1.6)


func _pattern_blink_wave() -> void:
    for i in range(2):
        await _blink_to(_far_side())
        var from_right := position.x > _home.x
        var start_x := _right - 20.0 if from_right else _left + 20.0
        var dir := -1.0 if from_right else 1.0
        _lean = dir
        Sfx.play("warn")
        _spawn_wave(start_x, dir, 0.7)
        await _wait(1.0)
        _lean = 0.0


func _pattern_double_wave() -> void:
    await _move_to(Vector2(_home.x, _floor_y - 96.0), 0.5)
    Sfx.play("warn")
    _spawn_wave(_left + 20.0, 1.0, 1.0)
    _spawn_wave(_right - 20.0, -1.0, 1.0)
    await _wait(2.4)
    Sfx.play("warn")
    _spawn_wave(_left + 20.0, 1.0, 0.8)
    await _wait(1.4)


# ---------- Dano, fases e fim ----------

func receive_love(amount: int, _from_pos: Vector2) -> void:
    if _state == State.OPEN:
        hp = maxi(hp - amount, 0)
        _flash = 0.2
        _shake = 0.12
        Sfx.play("boss_hit")
        _hud.call("set_boss", float(hp) / float(max_hp))
        if hp == 10 and not _said_phase2:
            _said_phase2 = true
            _hud.call("show_message", "Ela fica mais inquieta e foge mais longe. Mas os bancos continuam esperando.", 5.0)
        elif hp == 5 and not _said_phase3:
            _said_phase3 = true
            _hud.call("show_message", "Broto: Falta pouco. Ela já nem tem forças pra fugir direito.", 5.0)
        if hp <= 0:
            _defeat()
    elif _state == State.FIGHT and not _hinted_pending:
        _hinted_pending = true
        _hud.call("show_message", "Broto: Ela está longe demais. Alguém precisa abrir caminho...", 5.0)


func _defeat() -> void:
    _state = State.DONE
    _lean = 0.0
    Sfx.play("sleep")
    _hud.call("hide_boss")
    for node in get_tree().get_nodes_in_group("hazard"):
        node.queue_free()
    for s in _silhouettes:
        s.call("finish")
    var seat: Node2D = _silhouettes[_silhouettes.size() / 2]
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "scale", Vector2(0.4, 0.4), 2.0)
    tween.tween_property(self, "position", Vector2(seat.position.x + 30.0, _floor_y - 22.0), 2.0)
    tween.tween_property(self, "_tint", 1.0, 2.0)
    defeated.emit()


func _process(delta: float) -> void:
    _time += delta
    _flash = maxf(_flash - delta, 0.0)
    _shake = maxf(_shake - delta, 0.0)
    if _state == State.FIGHT and not _connected:
        _pending_time += delta
        if _pending_time > 24.0 and not _hinted_pending:
            _hinted_pending = true
            _hud.call("show_message", "Broto: Tem alguém brilhando ali num banco. Parece esperar que alguém chegue perto.", 6.0)
    queue_redraw()


func _draw() -> void:
    var a := _alpha
    var bob := sin(_time * 1.6) * 3.0
    var jitter := Vector2.ZERO
    if _shake > 0.0:
        jitter = Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))

    # sombra no chão
    draw_set_transform(Vector2(0.0, _floor_y - global_position.y), 0.0, Vector2(1.0, 0.2))
    draw_circle(Vector2.ZERO, 28.0, Color(0.0, 0.0, 0.0, 0.3 * a))

    draw_set_transform(Vector2(0.0, bob) + jitter, _lean * 0.08, Vector2.ONE)
    var body := Color(0.2, 0.22, 0.3).lerp(Color(0.62, 0.55, 0.75), _tint)
    if _flash > 0.0:
        body = body.lightened(0.5)
    body.a = a

    # manto de sombra, com a barra se desfazendo em fragmentos
    draw_colored_polygon(PackedVector2Array([
        Vector2(-14.0, -40.0), Vector2(0.0, -60.0), Vector2(14.0, -40.0), Vector2(24.0, -8.0),
        Vector2(20.0, 24.0), Vector2(10.0, 34.0), Vector2(0.0, 28.0), Vector2(-10.0, 34.0),
        Vector2(-20.0, 24.0), Vector2(-24.0, -8.0)]), body)
    draw_circle(Vector2(0.0, -40.0), 10.0, Color(0.05, 0.05, 0.09, a))

    var phase_two := _phase() >= 2 and _state != State.DONE
    var eye_col := Color(0.6, 0.9, 0.95, a)
    if phase_two:
        eye_col = Color(0.8, 1.0, 1.0, a)
    var eye_y := -38.0 if _state == State.OPEN else -41.0
    draw_circle(Vector2(-4.0, eye_y), 1.6, eye_col)
    draw_circle(Vector2(4.0, eye_y), 1.6, eye_col)

    # braços longos que alcançam e se encolhem
    for side in [-1.0, 1.0]:
        var sd := float(side)
        var shoulder := Vector2(sd * 16.0, -28.0)
        var elbow := Vector2(sd * 30.0, -14.0 + sin(_time * 1.4 + sd) * 3.0)
        var hand := Vector2(sd * 38.0 + _lean * 14.0, 2.0 + sin(_time * 1.8 + sd) * 4.0)
        if _state == State.OPEN or _state == State.DONE:
            elbow.y += 6.0
            hand.y += 14.0
        draw_line(shoulder, elbow, body, 5.0)
        draw_line(elbow, hand, body, 4.0)
        draw_circle(hand, 3.0, body)

    # fragmentos de cenário (tábuas de banco, molduras de janela) em órbita
    for i in range(10):
        var ang := _time * 0.6 + float(i) * 0.63
        var rad := 44.0 + float(i % 3) * 8.0
        var fp := Vector2(cos(ang) * rad, sin(ang) * rad * 0.55 + 6.0)
        var fcol := Color(0.45, 0.48, 0.58, 0.8 * a)
        match i % 3:
            0:
                draw_rect(Rect2(fp - Vector2(5.0, 1.5), Vector2(10.0, 3.0)), fcol)
            1:
                draw_rect(Rect2(fp - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), fcol, false, 1.0)
            _:
                draw_rect(Rect2(fp - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), fcol)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
