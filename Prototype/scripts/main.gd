extends Node2D
## MATIZ - protótipo, passo 2.
## Junta tudo: nível, NPC, Murmúrios, chefe, HUD e a evolução do Wander.
## O nível é montado por código para você ver tudo num lugar só.
## Mais tarde, trocamos por TileMap, cenas separadas e pixel art.

const PlayerScript := preload("res://scripts/player.gd")
const SeedScript := preload("res://scripts/seed.gd")
const BrotoScript := preload("res://scripts/broto.gd")
const TarcisioScript := preload("res://scripts/tarcisio.gd")
const MurmurioScript := preload("res://scripts/murmurio.gd")
const BossScript := preload("res://scripts/boss_insonia.gd")
const HudScript := preload("res://scripts/hud.gd")
const DialogueScript := preload("res://scripts/dialogue_box.gd")
const SaturationShader := preload("res://shaders/saturation.gdshader")

const GROUND_Y := 400.0
const LEVEL_LEFT := -300.0
const LEVEL_RIGHT := 3820.0
const GATE_X := 3000.0
const ARENA_LEFT := 3030.0
const ARENA_RIGHT := 3790.0
const SEED_POINT := Vector2(1275.0, 264.0)

var mats: Dictionary = {}
var player: CharacterBody2D
var player_material: ShaderMaterial
var night: CanvasModulate
var gate: StaticBody2D
var gate_fog: ColorRect
var boss_started := false

# Nós com scripts próprios (sem tipo fixo para chamarmos os métodos deles)
var hud
var dialogue
var broto
var tarcisio
var boss


func _ready() -> void:
    _setup_input()
    for key in ["world", "seed", "garden", "meadow", "arena"]:
        mats[key] = _make_material(0.0)
    player_material = _make_material(0.0)

    night = CanvasModulate.new()
    add_child(night)

    player = PlayerScript.new()
    hud = HudScript.new()
    dialogue = DialogueScript.new()
    add_child(hud)
    add_child(dialogue)

    _build_world()
    _build_decor()
    _spawn_seed()
    _spawn_tarcisio()
    _spawn_murmurios()
    _spawn_boss()
    _spawn_player()
    _spawn_broto()
    _connect_signals()
    _refresh_help()
    hud.call("show_message", "Tudo está em silêncio.", 4.0)


func _process(_delta: float) -> void:
    # Entrou na arena: começa a conversa com a Insônia
    if not boss_started and player.global_position.x > ARENA_LEFT + 60.0:
        boss_started = true
        GameState.checkpoint = Vector2(ARENA_LEFT + 20.0, 388.0)
        dialogue.call("start", _boss_intro_lines(), Callable(self, "_start_boss_fight"))


# ---------- Entrada (teclas) ----------

func _setup_input() -> void:
    _add_action("move_left", [KEY_A, KEY_LEFT])
    _add_action("move_right", [KEY_D, KEY_RIGHT])
    _add_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
    _add_action("attack", [KEY_J, KEY_Z])
    _add_action("dash", [KEY_K, KEY_X, KEY_SHIFT])
    _add_action("interact", [KEY_E, KEY_ENTER])
    _add_action("rest", [KEY_S, KEY_DOWN])


func _add_action(action: String, keys: Array) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    for key in keys:
        var event := InputEventKey.new()
        event.physical_keycode = key as Key
        InputMap.action_add_event(action, event)


# ---------- Cor ----------

func _make_material(amount: float) -> ShaderMaterial:
    var mat := ShaderMaterial.new()
    mat.shader = SaturationShader
    mat.set_shader_parameter("saturation", amount)
    return mat


func _tween_sat(key: String, value: float, seconds: float) -> void:
    var mat: ShaderMaterial = mats[key]
    var tween := create_tween()
    tween.tween_property(mat, "shader_parameter/saturation", value, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ---------- Construção do mundo ----------

func _build_world() -> void:
    var world := Node2D.new()
    world.name = "World"
    add_child(world)

    var sky := ColorRect.new()
    sky.position = Vector2(-600.0, -400.0)
    sky.size = Vector2(5000.0, 1200.0)
    sky.color = Color(0.55, 0.75, 0.95)
    sky.material = mats["world"]
    sky.z_index = -10
    world.add_child(sky)

    var ground := Color(0.45, 0.33, 0.22)
    _add_platform(world, Rect2(LEVEL_LEFT, GROUND_Y, 1000.0, 300.0), ground)
    _add_platform(world, Rect2(770.0, GROUND_Y, 1330.0, 300.0), ground)
    _add_platform(world, Rect2(2170.0, GROUND_Y, LEVEL_RIGHT - 2170.0, 300.0), ground)

    var step_color := Color(0.5, 0.4, 0.3)
    var steps := [
        Rect2(420.0, 364.0, 90.0, 16.0), Rect2(560.0, 328.0, 90.0, 16.0),
        Rect2(950.0, 364.0, 90.0, 16.0), Rect2(1090.0, 328.0, 90.0, 16.0), Rect2(1230.0, 292.0, 90.0, 16.0),
        Rect2(2290.0, 364.0, 60.0, 16.0), Rect2(2380.0, 330.0, 150.0, 16.0), Rect2(2560.0, 364.0, 70.0, 16.0),
        Rect2(3250.0, 364.0, 100.0, 16.0), Rect2(3500.0, 364.0, 100.0, 16.0),
    ]
    for r in steps:
        _add_platform(world, r, step_color)

    # Paredes invisíveis nas bordas da fase
    var invisible := Color(0.0, 0.0, 0.0, 0.0)
    _add_platform(world, Rect2(LEVEL_LEFT - 20.0, -200.0, 20.0, 900.0), invisible)
    _add_platform(world, Rect2(LEVEL_RIGHT, -200.0, 20.0, 900.0), invisible)

    # Portão de névoa: abre depois que o Tarcísio entrega o fio dourado
    gate = StaticBody2D.new()
    gate.position = Vector2(GATE_X, -200.0)
    var shape := CollisionShape2D.new()
    var rect_shape := RectangleShape2D.new()
    rect_shape.size = Vector2(20.0, 900.0)
    shape.shape = rect_shape
    shape.position = Vector2(10.0, 450.0)
    gate.add_child(shape)
    gate_fog = ColorRect.new()
    gate_fog.position = Vector2(-30.0, 0.0)
    gate_fog.size = Vector2(80.0, 900.0)
    gate_fog.color = Color(0.35, 0.35, 0.42, 0.85)
    gate.add_child(gate_fog)
    world.add_child(gate)


func _build_decor() -> void:
    var grass := Color(0.35, 0.75, 0.35)

    var seed_patch := _new_layer("SeedPatch")
    _add_visual(seed_patch, Rect2(1110.0, 396.0, 340.0, 6.0), grass, "seed")
    _add_visual(seed_patch, Rect2(1230.0, 288.0, 90.0, 5.0), grass, "seed")
    _add_flowers(seed_patch, 1140.0, 1440.0, 55.0, 384.0, "seed")

    var garden := _new_layer("Garden")
    _add_visual(garden, Rect2(1470.0, 396.0, 260.0, 6.0), grass, "garden")
    for i in range(6):
        _add_visual(garden, Rect2(1480.0 + float(i) * 16.0, 378.0, 3.0, 18.0), Color(0.6, 0.45, 0.3), "garden")
    _add_visual(garden, Rect2(1480.0, 383.0, 83.0, 3.0), Color(0.6, 0.45, 0.3), "garden")
    for i in range(7):
        var x := 1560.0 + float(i) * 10.0
        _add_visual(garden, Rect2(x, 389.0, 5.0, 7.0), Color(0.3, 0.7, 0.3), "garden")
        _add_visual(garden, Rect2(x + 1.0, 386.0, 3.0, 4.0), Color(0.95, 0.5, 0.2), "garden")

    var meadow := _new_layer("Meadow")
    _add_visual(meadow, Rect2(1750.0, 396.0, 350.0, 6.0), grass, "meadow")
    _add_visual(meadow, Rect2(2170.0, 396.0, 820.0, 6.0), grass, "meadow")
    _add_visual(meadow, Rect2(2290.0, 360.0, 60.0, 5.0), grass, "meadow")
    _add_visual(meadow, Rect2(2380.0, 326.0, 150.0, 5.0), grass, "meadow")
    _add_visual(meadow, Rect2(2560.0, 360.0, 70.0, 5.0), grass, "meadow")
    _add_flowers(meadow, 1780.0, 2090.0, 40.0, 384.0, "meadow")
    _add_flowers(meadow, 2190.0, 2980.0, 45.0, 384.0, "meadow")

    var arena := _new_layer("ArenaDecor")
    _add_visual(arena, Rect2(3030.0, 396.0, 790.0, 6.0), grass, "arena")
    _add_visual(arena, Rect2(3250.0, 360.0, 100.0, 5.0), grass, "arena")
    _add_visual(arena, Rect2(3500.0, 360.0, 100.0, 5.0), grass, "arena")
    _add_flowers(arena, 3050.0, 3780.0, 50.0, 384.0, "arena")


func _new_layer(layer_name: String) -> Node2D:
    var layer := Node2D.new()
    layer.name = layer_name
    add_child(layer)
    return layer


func _add_flowers(parent: Node, x0: float, x1: float, spacing: float, y: float, key: String) -> void:
    var colors := [Color(0.95, 0.4, 0.5), Color(0.98, 0.85, 0.3), Color(0.6, 0.5, 0.95), Color(0.95, 0.6, 0.3)]
    var x := x0
    var i := 0
    while x < x1:
        _add_visual(parent, Rect2(x, y, 3.0, 12.0), Color(0.25, 0.6, 0.3), key)
        _add_visual(parent, Rect2(x - 3.0, y - 5.0, 9.0, 6.0), colors[i % colors.size()], key)
        x += spacing + float((i * 7) % 5) * 4.0
        i += 1


func _add_visual(parent: Node, rect: Rect2, color: Color, key: String) -> void:
    var vis := ColorRect.new()
    vis.position = rect.position
    vis.size = rect.size
    vis.color = color
    vis.material = mats[key]
    parent.add_child(vis)


func _add_platform(parent: Node, rect: Rect2, color: Color) -> void:
    var body := StaticBody2D.new()
    body.position = rect.position
    var shape := CollisionShape2D.new()
    var rect_shape := RectangleShape2D.new()
    rect_shape.size = rect.size
    shape.shape = rect_shape
    shape.position = rect.size / 2.0
    body.add_child(shape)
    _add_visual(body, Rect2(Vector2.ZERO, rect.size), color, "world")
    parent.add_child(body)


# ---------- Personagens e objetos ----------

func _spawn_seed() -> void:
    var seed_node: Node2D = SeedScript.new()
    seed_node.position = SEED_POINT
    seed_node.connect("collected", _on_seed_collected)
    add_child(seed_node)


func _spawn_tarcisio() -> void:
    tarcisio = TarcisioScript.new()
    tarcisio.position = Vector2(1650.0, GROUND_Y)
    tarcisio.call("setup", player, dialogue, hud)
    add_child(tarcisio)


func _spawn_murmurios() -> void:
    # [limite esquerdo, limite direito, altura do chão]
    var spots := [
        [1740.0, 1950.0, GROUND_Y],
        [2392.0, 2518.0, 330.0],
        [2710.0, 2920.0, GROUND_Y],
    ]
    for s in spots:
        var m: CharacterBody2D = MurmurioScript.new()
        m.position = Vector2((float(s[0]) + float(s[1])) / 2.0, float(s[2]) - 8.0)
        m.call("setup", player, float(s[0]), float(s[1]))
        m.connect("befriended", _on_befriended)
        add_child(m)


func _spawn_boss() -> void:
    boss = BossScript.new()
    boss.call("setup", player, hud, ARENA_LEFT, ARENA_RIGHT, GROUND_Y)
    boss.connect("activated", _on_boss_activated)
    boss.connect("defeated", _on_boss_defeated)
    add_child(boss)


func _spawn_player() -> void:
    player.position = GameState.checkpoint
    player.material = player_material   # Wander também começa em tons de cinza
    add_child(player)

    var cam := Camera2D.new()
    cam.position_smoothing_enabled = true
    cam.position_smoothing_speed = 8.0
    cam.limit_left = int(LEVEL_LEFT)
    cam.limit_right = int(LEVEL_RIGHT)
    cam.limit_top = -200
    cam.limit_bottom = 520
    player.add_child(cam)
    cam.make_current()

    player.connect("breath_changed", Callable(hud, "set_breath"))
    player.connect("fainted", _on_player_fainted)
    player.call("refresh_breath", 99)


func _spawn_broto() -> void:
    broto = BrotoScript.new()
    broto.call("setup", player)
    add_child(broto)


func _connect_signals() -> void:
    GameState.stage_changed.connect(_on_stage_changed)
    tarcisio.connect("first_talk_done", _on_first_talk_done)
    tarcisio.connect("reward_given", _on_reward_given)


# ---------- Eventos da história ----------

func _on_seed_collected() -> void:
    GameState.has_seed = true
    GameState.checkpoint = Vector2(1400.0, 388.0)
    broto.call("activate")
    hud.call("show_message", "Broto: Ei! Você me acordou! ...Espera. Aquilo ali é COR?!", 6.0)
    _tween_sat("seed", 1.0, 3.0)


func _on_first_talk_done() -> void:
    GameState.quest = GameState.QUEST_ACTIVE
    GameState.can_love = true
    GameState.set_stage(2)
    _tween_sat("garden", 1.0, 3.0)
    hud.call("show_message", "Você aprendeu ACOLHER! Aperte J perto de um Murmúrio.", 6.0)
    hud.call("set_quest_text", "Missão: acolher 3 Murmúrios")
    hud.call("set_bonds", 0)
    _refresh_help()


func _on_befriended(m: Node2D) -> void:
    GameState.add_bond()
    var n := GameState.bonds
    m.set("friend_index", n - 1)
    hud.call("set_bonds", n)
    _tween_sat("meadow", float(n) / float(GameState.QUEST_GOAL), 2.5)
    player.call("refresh_breath", 1)

    if n == 1:
        GameState.can_dash = true
        GameState.set_stage(3)
        hud.call("show_message", "Seu primeiro laço! Você aprendeu a ESQUIVA (K).", 6.0)
    elif n < GameState.QUEST_GOAL:
        hud.call("show_message", "Mais um amigo. Eles seguem você agora, e cada um dá mais Fôlego.", 5.0)

    if n >= GameState.QUEST_GOAL:
        GameState.quest = GameState.QUEST_DONE
        GameState.checkpoint = Vector2(1600.0, 388.0)
        _tween_sat("world", 0.3, 4.0)
        hud.call("set_quest_text", "Missão cumprida! Volte e fale com o Tarcísio.")
        hud.call("show_message", "Broto: Os três te seguem! Vamos contar isso pro Tarcísio.", 7.0)
    _refresh_help()


func _on_reward_given() -> void:
    GameState.set_stage(4)
    GameState.checkpoint = Vector2(2940.0, 388.0)
    _open_gate()
    hud.call("show_message", "O fio dourado brilha no seu cachecol. Acolher alcança mais longe. A névoa do portão se abriu!", 8.0)
    hud.call("set_quest_text", "Siga a trilha até a torre do relógio.")


func _open_gate() -> void:
    var tween := create_tween()
    tween.tween_property(gate_fog, "modulate:a", 0.0, 2.0)
    tween.tween_callback(gate.queue_free)


func _start_boss_fight() -> void:
    boss.call("start_fight")


func _on_boss_activated() -> void:
    # Anoitece
    var tween := create_tween()
    tween.tween_property(night, "color", Color(0.5, 0.52, 0.78), 2.0)


func _on_boss_defeated() -> void:
    GameState.boss_defeated = true
    GameState.set_stage(5)
    await get_tree().create_timer(2.0).timeout
    dialogue.call("start", _boss_outro_lines(), Callable(self, "_finish_demo"))


func _finish_demo() -> void:
    GameState.can_rest = true
    _refresh_help()
    # Amanhece
    var tween := create_tween()
    tween.tween_property(night, "color", Color(1.0, 1.0, 1.0), 3.0)
    _tween_sat("world", 1.0, 5.0)
    _tween_sat("arena", 1.0, 5.0)
    boss.call("colorize")
    hud.call("set_quest_text", "Fim da demo. Explore e converse com o Tarcísio.")
    hud.call("show_message", "Você aprendeu DESCANSAR (segure S): recupera Fôlego. Descansar não é fraqueza.", 9.0)


func _on_player_fainted() -> void:
    hud.call("show_message", "Wander precisou de uma pausa. Respire e tente de novo.", 4.0)


func _on_stage_changed(new_stage: int) -> void:
    # Wander vai ganhando cor a cada estágio da jornada
    var target := 0.0
    match new_stage:
        2:
            target = 0.3
        3:
            target = 0.55
        4:
            target = 0.8
        5:
            target = 1.0
    var tween := create_tween()
    tween.tween_property(player_material, "shader_parameter/saturation", target, 2.0)


func _refresh_help() -> void:
    var text := "A/D: mover  |  Espaço: pular  |  E: conversar"
    if GameState.can_love:
        text += "  |  J: Acolher"
    if GameState.can_dash:
        text += "  |  K: Esquiva"
    if GameState.can_rest:
        text += "  |  S (segure): Descansar"
    hud.call("set_help", text)


func _boss_intro_lines() -> Array:
    return [
        ["Insônia", "Shh. Estou ocupada. Estou contando... perdi a conta de novo."],
        ["Broto", "Ela está com olheiras do tamanho de uma lua."],
        ["Insônia", "Quatrocentas e doze... quatrocentas e... não. Eu só preciso de mais uma noite."],
        ["Broto", "Wander, ela não quer brigar. Ela só não sabe parar. Desvie das ovelhas e, quando ela bocejar, acolha (J)."],
    ]


func _boss_outro_lines() -> Array:
    return [
        ["Insônia", "...Ah. Que silêncio gostoso. Eu tinha esquecido como era."],
        ["Insônia", "Obrigada por não gritar comigo."],
        ["Broto", "Boa noite, Insônia. A gente passa amanhã com o chá."],
    ]
