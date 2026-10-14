extends Node2D
## VIVA A SUA MENTE - Mundo 1.
## Introdução na casa do Wander, vila, pequenas ações cotidianas, Eco da Insônia
## e Eco da Solidão. O nível é montado por código; o visual do cenário mora
## em scenery.gd. Mais tarde, trocamos por TileMap, cenas e pixel art.

const PlayerScript := preload("res://scripts/player.gd")
const SeedScript := preload("res://scripts/seed.gd")
const BrotoScript := preload("res://scripts/broto.gd")
const TarcisioScript := preload("res://scripts/tarcisio.gd")
const TarsilaScript := preload("res://scripts/tarsila.gd")
const MelScript := preload("res://scripts/mel.gd")
const GatoScript := preload("res://scripts/gato.gd")
const BentoScript := preload("res://scripts/bento.gd")
const PickupScript := preload("res://scripts/pickup.gd")
const MurmurioScript := preload("res://scripts/murmurio.gd")
const SproutScript := preload("res://scripts/sprout.gd")
const NoteScript := preload("res://scripts/note.gd")
const HugFxScript := preload("res://scripts/hug_fx.gd")
const BossScript := preload("res://scripts/boss_insonia.gd")
const SilhuetaScript := preload("res://scripts/silhueta.gd")
const BossSolidaoScript := preload("res://scripts/boss_solidao.gd")
const HudScript := preload("res://scripts/hud.gd")
const DialogueScript := preload("res://scripts/dialogue_box.gd")
const ObservableScript := preload("res://scripts/observable.gd")
const SceneryScript := preload("res://scripts/scenery.gd")
const AmbientScript := preload("res://scripts/ambient.gd")
const SaturationShader := preload("res://shaders/saturation.gdshader")

const GROUND_Y := 400.0
const SPAWN_Y := 384.0
const LEVEL_LEFT := -560.0
const LEVEL_RIGHT := 4700.0
const GATE_X := 3000.0
const ARENA_LEFT := 3030.0
const ARENA_RIGHT := 3790.0
const GATE2_X := 3830.0
const PLAZA_LEFT := 3880.0
const PLAZA_RIGHT := 4660.0
const BENCH_XS := [3990.0, 4290.0, 4570.0]
const SEED_POINT := Vector2(1275.0, 264.0)
const TARSILA_X := 1925.0
const MEL_X := 860.0
const CAT_X := 1745.0
const BENTO_X := 1395.0

const MAT_KEYS := ["world", "seed", "garden", "meadow", "arena", "bakery", "fern", "house", "curtain", "desk", "hills", "trees", "street", "plaza", "mel", "bento"]

# Bilhetes deixados pelos moradores: [id, quem, texto]
const NOTES := [
    [1, "Bilhete da Tarsila", "Wander, deixei um pão na sua porta. É de ontem, mas ainda tá bom. A chaleira tá no fogo se quiser café. — T."],
    [2, "Bilhete da Mel", "wander!! aprendi a assobiar!! quando vc aparecer eu mostro. a mamãe disse pra eu não encher a sua paciência mas acho que não tô enchendo. — Mel"],
    [3, "Bilhete do Seu Bento", "Peguei um peixe grande hoje, deixei metade no seu degrau. Não é favor, tinha demais. — Bento"],
    [4, "Bilhete do Tarcísio", "Passei aqui e a samambaia estava seca. Reguei. Ela não tem culpa de nada. — Tarcísio"],
    [5, "Bilhete do Lúcio", "Cheguei bem. A cidade é barulhenta, o apartamento é pequeno e eu já tô com saudade da sua cara emburrada. Me liga quando der. Sem pressa. — L."],
]

var mats: Dictionary = {}
var player: CharacterBody2D
var player_material: ShaderMaterial
var cam: Camera2D
var night: CanvasModulate
var gate: StaticBody2D
var gate_fog: ColorRect
var boss_started := false
var boss2_started := false
var gate_opened := false
var gate2_opened := false
var fog_hinted := false
var murmurio_hinted := false

# Introdução (casa do Wander)
var intro_layer: CanvasLayer
var intro_rect: ColorRect
var intro_label: Label
var intro_hint: Label
var intro_tween: Tween
var intro_done := false
var intro_timer := 0.0
var knocked := false
var door_open := false
var left_house := false
var fern_watered := false
var drawer_seen := false
var cozy_lit := false
var examined: Dictionary = {}
var observables: Dictionary = {}
var silhouettes: Array = []

# Nós com scripts próprios (sem tipo fixo para chamarmos os métodos deles)
var hud
var dialogue
var scenery
var ambient
var broto
var tarcisio
var tarsila
var mel
var cat
var bento
var boss
var boss2
var hug_fx


func _ready() -> void:
    _setup_input()
    for key in MAT_KEYS:
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
    scenery = SceneryScript.new()
    scenery.mats = mats
    add_child(scenery)
    scenery.build_background()
    scenery.build_street()
    scenery.build_house()
    scenery.build_plaza(PLAZA_LEFT, PLAZA_RIGHT, BENCH_XS, GATE2_X)
    scenery.spawn_critters()

    _spawn_seed()
    _spawn_tarcisio()
    _spawn_tarsila()
    _spawn_mel()
    _spawn_cat()
    _spawn_bento()
    _spawn_sprouts()
    _spawn_notes()
    _spawn_murmurios()
    _spawn_boss()
    _spawn_boss2()
    _spawn_player()
    _spawn_observables()
    _spawn_hug_fx()
    _spawn_broto()
    _spawn_ambient()
    _connect_signals()
    _refresh_help()
    _build_intro_overlay()
    _play_intro()


func _process(delta: float) -> void:
    # E pula a introdução
    if intro_tween != null and intro_tween.is_valid() and Input.is_action_just_pressed("interact"):
        intro_tween.custom_step(10.0)

    # Depois de um tempo em casa, alguém bate na porta
    if intro_done and not knocked:
        intro_timer += delta
        if (examined.size() >= 3 or intro_timer > 45.0) and not dialogue.is_open:
            _knock()

    # Saiu de casa: o checkpoint passa a ser a porta
    if not left_house and player.global_position.x > 0.0:
        left_house = true
        GameState.checkpoint = Vector2(30.0, SPAWN_Y)

    # Entrou na arena da Insônia
    if not boss_started and player.global_position.x > ARENA_LEFT + 60.0:
        boss_started = true
        GameState.checkpoint = Vector2(ARENA_LEFT + 20.0, SPAWN_Y)
        dialogue.call("start", _boss_intro_lines(), Callable(self, "_start_boss_fight"))

    # Entrou na praça: conversa com a Solidão
    if not boss2_started and gate2_opened and player.global_position.x > PLAZA_LEFT + 70.0:
        boss2_started = true
        GameState.checkpoint = Vector2(PLAZA_LEFT + 20.0, SPAWN_Y)
        dialogue.call("start", _boss2_intro_lines(), Callable(self, "_start_boss2_fight"))

    _update_fog()


# Atalhos de teste (só funcionam quando o jogo roda pelo editor da Godot)
func _unhandled_input(event: InputEvent) -> void:
    var key := event as InputEventKey
    if key == null or not key.pressed or not OS.is_debug_build():
        return
    match key.keycode:
        KEY_F1:
            _debug_go(ARENA_LEFT + 20.0, false)
        KEY_F2:
            _debug_go(PLAZA_LEFT + 20.0, true)
        KEY_F3:
            player.call("refresh_breath", 99)


func _debug_go(x: float, after_boss1: bool) -> void:
    GameState.can_love = true
    GameState.can_dash = true
    GameState.set_stage(4)
    while GameState.bonds < 3:
        GameState.add_bond()
    knocked = true
    door_open = true
    intro_done = true
    if is_instance_valid(gate):
        gate.queue_free()
    gate_opened = true
    if after_boss1:
        boss_started = true
        GameState.boss_defeated = true
        GameState.can_rest = true
        if not gate2_opened:
            gate2_opened = true
            scenery.gate2.queue_free()
            scenery.gate2_fog.visible = false
    player.position = Vector2(x, SPAWN_Y)
    player.velocity = Vector2.ZERO
    _refresh_help()


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


# ---------- Cor e música ----------

func _make_material(amount: float) -> ShaderMaterial:
    var mat := ShaderMaterial.new()
    mat.shader = SaturationShader
    mat.set_shader_parameter("saturation", amount)
    return mat


func _tween_sat(key: String, value: float, seconds: float) -> void:
    var mat: ShaderMaterial = mats[key]
    var current: float = mat.get_shader_parameter("saturation")
    if value > current + 0.05:
        Sfx.play("color", -10.0)
    var tween := create_tween()
    tween.tween_property(mat, "shader_parameter/saturation", value, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Só aumenta a cor (nunca diminui), para os marcos não se atropelarem.
func _raise_sat(key: String, value: float, seconds: float) -> void:
    var mat: ShaderMaterial = mats[key]
    var current: float = mat.get_shader_parameter("saturation")
    if current < value:
        _tween_sat(key, value, seconds)


## Alimenta a música e as partículas. Nunca vira uma "barra de felicidade".
func _warm(amount: float) -> void:
    GameState.warmth = minf(GameState.warmth + amount, 1.0)
    Sfx.set_progress(GameState.warmth)
    ambient.call("set_warmth", GameState.warmth)


# ---------- Construção do mundo ----------

func _build_world() -> void:
    var world := Node2D.new()
    world.name = "World"
    add_child(world)

    var sky := ColorRect.new()
    sky.position = Vector2(-900.0, -400.0)
    sky.size = Vector2(6200.0, 1200.0)
    sky.color = Color(0.55, 0.75, 0.95)
    sky.material = mats["world"]
    sky.z_index = -10
    world.add_child(sky)

    var ground := Color(0.45, 0.33, 0.22)
    _add_platform(world, Rect2(LEVEL_LEFT, GROUND_Y, 700.0 - LEVEL_LEFT, 300.0), ground)
    _add_platform(world, Rect2(770.0, GROUND_Y, 1330.0, 300.0), ground)
    _add_platform(world, Rect2(2170.0, GROUND_Y, LEVEL_RIGHT - 2170.0, 300.0), ground)

    var step_color := Color(0.5, 0.4, 0.3)
    var steps := [
        # degraus do caminho (cada subida tem no máximo 36 px; o pulo alcança 48)
        Rect2(420.0, 364.0, 90.0, 16.0), Rect2(560.0, 328.0, 90.0, 16.0), Rect2(600.0, 292.0, 80.0, 16.0),
        Rect2(950.0, 364.0, 90.0, 16.0), Rect2(1090.0, 328.0, 90.0, 16.0), Rect2(1230.0, 292.0, 90.0, 16.0),
        Rect2(2290.0, 364.0, 60.0, 16.0), Rect2(2380.0, 330.0, 150.0, 16.0), Rect2(2560.0, 364.0, 70.0, 16.0),
        Rect2(3250.0, 364.0, 100.0, 16.0), Rect2(3500.0, 364.0, 100.0, 16.0),
        # segredos: só dá para chegar crescendo o broto ao lado (acolher, J)
        Rect2(236.0, 326.0, 90.0, 16.0), Rect2(1520.0, 326.0, 90.0, 16.0), Rect2(2810.0, 326.0, 90.0, 16.0),
    ]
    for r in steps:
        _add_platform(world, r, step_color)

    # Paredes invisíveis nas bordas da fase
    var invisible := Color(0.0, 0.0, 0.0, 0.0)
    _add_platform(world, Rect2(LEVEL_LEFT - 20.0, -200.0, 20.0, 900.0), invisible)
    _add_platform(world, Rect2(LEVEL_RIGHT, -200.0, 20.0, 900.0), invisible)

    # Portão de névoa: a névoa não deixa ninguém passar sozinho
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

    # Padaria da Tarsila (ganha cor depois do abraço)
    var bakery := _new_layer("Bakery")
    _add_visual(bakery, Rect2(1790.0, 346.0, 110.0, 54.0), Color(0.93, 0.82, 0.62), "bakery")
    _add_visual(bakery, Rect2(1782.0, 328.0, 126.0, 18.0), Color(0.75, 0.35, 0.3), "bakery")
    _add_visual(bakery, Rect2(1880.0, 306.0, 12.0, 22.0), Color(0.6, 0.35, 0.3), "bakery")
    _add_visual(bakery, Rect2(1832.0, 364.0, 24.0, 36.0), Color(0.55, 0.38, 0.25), "bakery")
    _add_visual(bakery, Rect2(1866.0, 358.0, 20.0, 14.0), Color(0.6, 0.8, 0.95), "bakery")
    _add_visual(bakery, Rect2(1950.0, 386.0, 40.0, 5.0), Color(0.6, 0.45, 0.3), "bakery")
    _add_visual(bakery, Rect2(1953.0, 391.0, 3.0, 9.0), Color(0.5, 0.38, 0.28), "bakery")
    _add_visual(bakery, Rect2(1984.0, 391.0, 3.0, 9.0), Color(0.5, 0.38, 0.28), "bakery")
    _add_visual(bakery, Rect2(1950.0, 372.0, 40.0, 3.0), Color(0.6, 0.45, 0.3), "bakery")
    _add_visual(bakery, Rect2(1790.0, 396.0, 220.0, 6.0), grass, "bakery")
    var sign_label := Label.new()
    sign_label.text = "PADARIA"
    sign_label.position = Vector2(1812.0, 330.0)
    sign_label.add_theme_font_size_override("font_size", 9)
    bakery.add_child(sign_label)

    var meadow := _new_layer("Meadow")
    _add_visual(meadow, Rect2(2010.0, 396.0, 90.0, 6.0), grass, "meadow")
    _add_visual(meadow, Rect2(2170.0, 396.0, 820.0, 6.0), grass, "meadow")
    _add_visual(meadow, Rect2(2290.0, 360.0, 60.0, 5.0), grass, "meadow")
    _add_visual(meadow, Rect2(2380.0, 326.0, 150.0, 5.0), grass, "meadow")
    _add_visual(meadow, Rect2(2560.0, 360.0, 70.0, 5.0), grass, "meadow")
    _add_flowers(meadow, 2020.0, 2090.0, 40.0, 384.0, "meadow")
    _add_flowers(meadow, 2190.0, 2980.0, 45.0, 384.0, "meadow")

    var arena := _new_layer("ArenaDecor")
    _add_visual(arena, Rect2(3030.0, 396.0, 790.0, 6.0), grass, "arena")
    _add_visual(arena, Rect2(3250.0, 360.0, 100.0, 5.0), grass, "arena")
    _add_visual(arena, Rect2(3500.0, 360.0, 100.0, 5.0), grass, "arena")
    _add_flowers(arena, 3050.0, 3780.0, 50.0, 384.0, "arena")


func _new_layer(layer_name: String) -> Node2D:
    var lay := Node2D.new()
    lay.name = layer_name
    add_child(lay)
    return lay


func _add_flowers(parent: Node, x0: float, x1: float, spacing: float, y: float, key: String) -> void:
    var colors := [Color(0.95, 0.4, 0.5), Color(0.98, 0.85, 0.3), Color(0.6, 0.5, 0.95), Color(0.95, 0.6, 0.3)]
    var x := x0
    var i := 0
    while x < x1:
        _add_visual(parent, Rect2(x, y, 3.0, 12.0), Color(0.25, 0.6, 0.3), key)
        _add_visual(parent, Rect2(x - 3.0, y - 5.0, 9.0, 6.0), colors[i % colors.size()], key)
        x += spacing + float((i * 7) % 5) * 4.0
        i += 1


func _add_visual(parent: Node, rect: Rect2, color: Color, key: String) -> ColorRect:
    var vis := ColorRect.new()
    vis.position = rect.position
    vis.size = rect.size
    vis.color = color
    vis.material = mats[key]
    parent.add_child(vis)
    return vis


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


func _spawn_tarsila() -> void:
    tarsila = TarsilaScript.new()
    tarsila.position = Vector2(TARSILA_X, GROUND_Y)
    tarsila.call("setup", player, dialogue, hud)
    tarsila.connect("hug_requested", _on_hug_requested)
    add_child(tarsila)


func _spawn_mel() -> void:
    mel = MelScript.new()
    mel.position = Vector2(MEL_X, GROUND_Y)
    mel.call("setup", player, dialogue, hud)
    mel.connect("complimented", _on_mel_complimented)
    add_child(mel)


func _spawn_cat() -> void:
    cat = GatoScript.new()
    cat.position = Vector2(CAT_X, GROUND_Y)
    cat.call("setup", player, hud)
    cat.connect("trusted", _on_cat_trusted)
    add_child(cat)


func _spawn_bento() -> void:
    bento = BentoScript.new()
    bento.position = Vector2(BENTO_X, GROUND_Y)
    bento.call("setup", player, dialogue, hud)
    bento.connect("hat_given", _on_hat_given)
    add_child(bento)
    # o chapéu que o vento levou: em cima da pedra alta perto da horta
    var hat: Area2D = PickupScript.new()
    hat.call("setup", "hat")
    hat.position = Vector2(1596.0, 312.0)
    hat.connect("collected", _on_pickup)
    add_child(hat)


func _spawn_sprouts() -> void:
    # Cada broto, depois de acolhido, vira uma folha que leva a um segredo.
    for x in [205.0, 1490.0, 2780.0]:
        var sprout: Node2D = SproutScript.new()
        sprout.position = Vector2(x, GROUND_Y)
        add_child(sprout)


func _spawn_notes() -> void:
    var spots := [
        Vector2(22.0, 386.0),     # na porta de casa
        Vector2(281.0, 310.0),    # segredo (broto 1)
        Vector2(1135.0, 312.0),   # em cima de um degrau
        Vector2(1565.0, 310.0),   # segredo (broto 2)
        Vector2(2855.0, 310.0),   # segredo (broto 3), perto da torre
    ]
    for i in range(spots.size()):
        var data: Array = NOTES[i]
        var note: Area2D = NoteScript.new()
        note.call("setup", data[0], data[1], data[2])
        note.position = spots[i]
        note.connect("collected", _on_note_collected)
        add_child(note)


func _spawn_murmurios() -> void:
    # [limite esquerdo, limite direito, altura do chão]
    var spots := [
        [2010.0, 2090.0, GROUND_Y],
        [2392.0, 2518.0, 330.0],
        [2710.0, 2920.0, GROUND_Y],
    ]
    for s in spots:
        var m: CharacterBody2D = MurmurioScript.new()
        m.position = Vector2((float(s[0]) + float(s[1])) / 2.0, float(s[2]) - 8.0)
        m.call("setup", player, float(s[0]), float(s[1]))
        m.connect("befriended", _on_befriended)
        m.connect("noticed", _on_murmurio_noticed)
        add_child(m)


func _spawn_boss() -> void:
    boss = BossScript.new()
    boss.call("setup", player, hud, ARENA_LEFT, ARENA_RIGHT, GROUND_Y)
    boss.connect("activated", _on_boss_activated)
    boss.connect("defeated", _on_boss_defeated)
    add_child(boss)


func _spawn_boss2() -> void:
    for i in range(BENCH_XS.size()):
        var sil: Node2D = SilhuetaScript.new()
        sil.position = Vector2(BENCH_XS[i], GROUND_Y)
        sil.set("facing", -1.0 if i == 1 else 1.0)
        add_child(sil)
        silhouettes.append(sil)
    boss2 = BossSolidaoScript.new()
    boss2.call("setup", player, hud, PLAZA_LEFT + 20.0, PLAZA_RIGHT - 20.0, GROUND_Y, silhouettes)
    boss2.connect("activated", _on_boss2_activated)
    boss2.connect("defeated", _on_boss2_defeated)
    add_child(boss2)


func _spawn_player() -> void:
    player.position = GameState.checkpoint
    player.material = player_material   # Wander também começa em tons de cinza
    add_child(player)

    cam = Camera2D.new()
    cam.position_smoothing_enabled = true
    cam.position_smoothing_speed = 8.0
    cam.limit_left = int(LEVEL_LEFT)
    cam.limit_right = int(LEVEL_RIGHT)
    cam.limit_top = -200
    cam.limit_bottom = 520
    player.add_child(cam)
    cam.make_current()
    scenery.cam = cam

    player.connect("breath_changed", Callable(hud, "set_breath"))
    player.connect("fainted", _on_player_fainted)
    player.call("refresh_breath", 99)


func _spawn_observables() -> void:
    # [id, x, altura dos pés, aviso]
    var specs := [
        ["bed", -517.0, GROUND_Y, "E: olhar a cama"],
        ["phone", -460.0, GROUND_Y, "E: ver o telefone"],
        ["window", -408.0, GROUND_Y, "E: olhar a janela"],
        ["wardrobe", -347.0, GROUND_Y, "E: abrir o armário"],
        ["memory_box", -351.0, 328.0, "E: abrir a caixa"],
        ["boxes", -302.0, GROUND_Y, "E: olhar as caixas"],
        ["desk", -240.0, GROUND_Y, "E: ver a escrivaninha"],
        ["books", -149.0, GROUND_Y, "E: olhar os livros"],
        ["fern", -104.0, GROUND_Y, "E: ver a samambaia"],
        ["calendar", -68.0, GROUND_Y, "E: olhar o calendário"],
        ["door", -26.0, GROUND_Y, "E: porta"],
        ["lookout", 640.0, 292.0, "E: observar a vista"],
    ]
    for spec in specs:
        var obs: Node2D = ObservableScript.new()
        obs.position = Vector2(float(spec[1]), float(spec[2]))
        obs.call("setup", player, dialogue, hud, spec[0], spec[3])
        obs.connect("interacted", _on_observed)
        add_child(obs)
        observables[spec[0]] = obs


func _spawn_hug_fx() -> void:
    hug_fx = HugFxScript.new()
    add_child(hug_fx)


func _spawn_broto() -> void:
    broto = BrotoScript.new()
    broto.call("setup", player)
    add_child(broto)


func _spawn_ambient() -> void:
    ambient = AmbientScript.new()
    ambient.cam = cam
    add_child(ambient)


func _connect_signals() -> void:
    GameState.stage_changed.connect(_on_stage_changed)
    tarcisio.connect("first_talk_done", _on_first_talk_done)
    tarcisio.connect("reward_given", _on_reward_given)


# ---------- A casa e as pequenas ações ----------

func _on_observed(id: String) -> void:
    if id != "door" and id != "lookout":
        examined[id] = true
    match id:
        "bed":
            dialogue.call("start", [["", "A cama está do jeito que você deixou. Ou seja: do jeito que ela ficou."]])
        "phone":
            dialogue.call("start", [
                ["", "Quatro mensagens do Lúcio. Você leu todas. Respondeu todas... na cabeça."],
                ["", "A última: 'Cheguei bem na cidade nova. Me liga quando der.'"],
                ["", "Você coloca o telefone de volta onde estava. Depois."],
            ])
        "window":
            _examine_window()
        "wardrobe":
            dialogue.call("start", [["", "Roupas dobradas há meses. A camisa de cima ainda é a do último verão."]])
        "memory_box":
            _examine_memory_box()
        "boxes":
            dialogue.call("start", [["", "Caixas com etiquetas na letra do Lúcio: 'livros', 'coisas da facul', 'não sei'. A última, ninguém abriu."]])
        "desk":
            _examine_desk()
        "books":
            dialogue.call("start", [["", "Livros pela metade, com marcador na mesma página há meses. Um é de jardinagem, presente do Tarcísio. Ele jura que ajuda."]])
        "fern":
            _examine_fern()
        "calendar":
            dialogue.call("start", [["", "Os dias estão riscados até uma semana atrás. Depois disso, ficou em branco. Ninguém riscou mais."]])
        "door":
            _examine_door()
        "lookout":
            _do_lookout()


func _examine_window() -> void:
    if GameState.curtain_open:
        dialogue.call("start", [["", "Lá fora tem um bairro inteiro. Daqui de cima não parece ter ninguém, mas tem."]])
        return
    dialogue.call("start_choice",
        [["", "A cortina está fechada há dias. Pela fresta, a luz é só uma linha fina no chão."]],
        ["Abrir a cortina", "Deixar como está"],
        Callable(self, "_on_window_choice"))


func _on_window_choice(index: int) -> void:
    if index == 0:
        dialogue.call("start", [["", "A luz entra devagar. Tem poeira flutuando nela. Dá pra ficar olhando um tempo."]], Callable(self, "_open_curtain"))
    else:
        dialogue.call("start", [["", "Você deixa como está. A cortina não vai a lugar nenhum."]])


func _open_curtain() -> void:
    GameState.curtain_open = true
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(scenery.curtain_left, "position:x", -446.0, 1.5)
    tween.tween_property(scenery.curtain_left, "size:x", 14.0, 1.5)
    tween.tween_property(scenery.curtain_right, "position:x", -384.0, 1.5)
    tween.tween_property(scenery.curtain_right, "size:x", 14.0, 1.5)
    tween.tween_property(scenery.beam, "color:a", 0.16, 2.5)
    scenery.beam_dust.emitting = true
    _tween_sat("curtain", 1.0, 3.0)
    _raise_sat("hills", 0.12, 4.0)
    _raise_sat("house", 0.15, 4.0)
    _warm(0.05)
    _cozy_check()


func _examine_desk() -> void:
    if not GameState.desk_tidied:
        dialogue.call("start_choice",
            [["", "Papéis espalhados, um caderno aberto, uma xícara que esfriou faz tempo. A mesa de quem ia fazer alguma coisa."]],
            ["Arrumar um pouco", "Deixar como está"],
            Callable(self, "_on_desk_choice"))
    elif not drawer_seen:
        drawer_seen = true
        dialogue.call("start", [
            ["", "Com a mesa livre, dá pra abrir a gaveta de baixo. Dentro, um desenho antigo seu: uma árvore meio torta, com um sol no canto."],
            ["", "Você não lembra quando desenhou. Mas guarda de volta com cuidado."],
        ])
    else:
        dialogue.call("start", [["", "A mesa continua arrumada. Por enquanto."]])


func _on_desk_choice(index: int) -> void:
    if index == 0:
        dialogue.call("start", [
            ["", "Você junta os papéis, fecha o caderno, leva a xícara pra pia. Uns cinco minutos."],
            ["", "A mesa fica quase a mesma. Mas agora cabe um cotovelo."],
        ], Callable(self, "_tidy_desk"))
    else:
        dialogue.call("start", [["", "Fica pra depois. Os papéis já se acostumaram."]])


func _tidy_desk() -> void:
    GameState.desk_tidied = true
    var tween := create_tween()
    tween.set_parallel(true)
    for item in scenery.desk_mess:
        tween.tween_property(item, "modulate:a", 0.0, 1.2)
    for item in scenery.desk_neat:
        tween.tween_property(item, "modulate:a", 1.0, 1.2)
    scenery.lamps["desk"].call("set_lit", true, 2.0)
    _tween_sat("desk", 1.0, 2.5)
    _raise_sat("house", 0.3, 4.0)
    _warm(0.06)
    _cozy_check()


func _examine_memory_box() -> void:
    if GameState.memory_found:
        dialogue.call("start", [["", "Você fecha a caixa de novo. Dessa vez sem pressa."]])
        return
    dialogue.call("start", [
        ["", "Uma caixa de sapatos escondida no alto do armário."],
        ["", "Dentro: ingressos de um show, uma pulseira de festival e um bilhete: 'no próximo a gente vai de camarote'. Sem assinatura. Você sabe de quem é."],
    ], Callable(self, "_found_memory"))


func _found_memory() -> void:
    GameState.memory_found = true
    _raise_sat("house", 0.4, 4.0)
    _warm(0.05)
    Sfx.play("color", -10.0)


func _examine_fern() -> void:
    if fern_watered:
        dialogue.call("start", [["", "A samambaia parece menos desanimada. Ou é impressão sua. Tudo bem."]])
        return
    dialogue.call("start_choice",
        [["", "A samambaia que o Tarcísio te deu. Está bem seca. Ele disse que era 'impossível de matar'."]],
        ["Regar um pouquinho", "Deixar pra depois"],
        Callable(self, "_on_fern_choice"))


func _on_fern_choice(index: int) -> void:
    if index == 0:
        dialogue.call("start", [
            ["", "Você enche um copo e derrama devagar. A terra escurece. Dá pra ouvir a água sendo aceita."],
            ["", "É só uma planta. Mas é uma coisa que ficou diferente por sua causa."],
        ], Callable(self, "_water_fern"))
    else:
        dialogue.call("start", [["", "Você deixa pra depois. A samambaia não reclama. Ainda."]])


func _water_fern() -> void:
    fern_watered = true
    _tween_sat("fern", 1.0, 3.0)
    var tween := create_tween()
    tween.set_parallel(true)
    for leaf in scenery.fern_leaves:
        tween.tween_property(leaf, "color", Color(0.3, 0.7, 0.35), 2.5)
    _raise_sat("house", 0.2, 4.0)
    _warm(0.08)
    _cozy_check()


## O quarto fica mais acolhedor conforme Wander cuida dele (sem exigir tudo).
func _cozy_check() -> void:
    var count := int(fern_watered) + int(GameState.desk_tidied) + int(GameState.curtain_open)
    var shade_tween := create_tween()
    shade_tween.tween_property(scenery.shade, "color:a", 0.2 - 0.045 * float(count), 3.0)
    if count >= 2 and not cozy_lit:
        cozy_lit = true
        scenery.lamps["night"].call("set_lit", true, 2.0)


func _examine_door() -> void:
    if not knocked:
        dialogue.call("start", [["", "Você encosta a mão na porta. Lá fora tem um dia inteiro esperando. Ele pode esperar mais um pouco."]])
    elif not door_open:
        dialogue.call("start", [["", "Você respira fundo e abre a porta."]], Callable(self, "_open_door"))


func _knock() -> void:
    knocked = true
    GameState.input_locked = true
    await get_tree().create_timer(0.8).timeout
    Sfx.play("knock")
    await get_tree().create_timer(0.9).timeout
    dialogue.call("start", [
        ["", "Toc, toc, toc."],
        ["", "Alguém bate na porta. Você espera. Os passos se afastam, devagar."],
    ])


func _open_door() -> void:
    door_open = true
    observables["door"].set("enabled", false)
    scenery.door_blocker.queue_free()
    Sfx.play("door")
    var tween := create_tween()
    tween.tween_property(scenery.door_visual, "modulate:a", 0.0, 0.6)
    hud.call("show_message", "Tudo está em silêncio.", 4.0)


func _do_lookout() -> void:
    if GameState.lookout_done:
        dialogue.call("start", [["", "Você fica mais um tempo olhando. A vista continua lá, sem pressa."]])
        return
    GameState.input_locked = true
    var zoom_in := create_tween()
    zoom_in.tween_property(cam, "zoom", Vector2(1.5, 1.5), 1.5).set_trans(Tween.TRANS_SINE)
    hud.call("show_message", "Você fica um tempo olhando. Nada acontece. E tudo bem.", 6.0)
    await get_tree().create_timer(4.0).timeout
    GameState.lookout_done = true
    _raise_sat("hills", 0.5, 5.0)
    _raise_sat("trees", 0.3, 5.0)
    _raise_sat("street", 0.15, 5.0)
    _warm(0.1)
    await get_tree().create_timer(2.5).timeout
    var zoom_out := create_tween()
    zoom_out.tween_property(cam, "zoom", Vector2.ONE, 1.2).set_trans(Tween.TRANS_SINE)
    await zoom_out.finished
    GameState.input_locked = false
    hud.call("show_message", "O que estava longe parece um pouco mais perto.", 5.0)


# ---------- Introdução ----------

func _build_intro_overlay() -> void:
    intro_layer = CanvasLayer.new()
    intro_layer.layer = 20
    add_child(intro_layer)
    intro_rect = ColorRect.new()
    intro_rect.size = Vector2(640.0, 360.0)
    intro_rect.color = Color(0.0, 0.0, 0.0, 1.0)
    intro_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    intro_layer.add_child(intro_rect)
    intro_label = Label.new()
    intro_label.position = Vector2(60.0, 150.0)
    intro_label.custom_minimum_size = Vector2(520.0, 0.0)
    intro_label.size = Vector2(520.0, 70.0)
    intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    intro_label.add_theme_font_size_override("font_size", 16)
    intro_label.modulate.a = 0.0
    intro_layer.add_child(intro_label)
    intro_hint = Label.new()
    intro_hint.text = "[E] pular"
    intro_hint.position = Vector2(572.0, 342.0)
    intro_hint.add_theme_font_size_override("font_size", 9)
    intro_hint.modulate = Color(1.0, 1.0, 1.0, 0.45)
    intro_layer.add_child(intro_hint)


func _play_intro() -> void:
    GameState.input_locked = true
    await _intro_line("Faz um tempo que os dias parecem todos o mesmo dia.", 2.0)
    await _intro_line("Wander acorda. O quarto está onde sempre esteve.", 2.0)
    await _intro_line("Só que, faz um tempo, tudo parece ter ficado sem cor.", 2.2)
    intro_label.add_theme_font_size_override("font_size", 26)
    await _intro_line("VIVA A SUA MENTE", 1.8)
    intro_hint.visible = false
    var fade := create_tween()
    fade.tween_property(intro_rect, "color:a", 0.0, 2.0)
    await fade.finished
    intro_layer.queue_free()
    GameState.input_locked = false
    intro_done = true
    hud.call("show_message", "Olhe ao redor. (E: examinar)", 5.0)


func _intro_line(text: String, hold: float) -> void:
    intro_label.text = text
    intro_tween = create_tween()
    intro_tween.tween_property(intro_label, "modulate:a", 1.0, 0.9)
    intro_tween.tween_interval(hold)
    intro_tween.tween_property(intro_label, "modulate:a", 0.0, 0.7)
    await intro_tween.finished


# ---------- Eventos da história ----------

func _on_seed_collected() -> void:
    GameState.has_seed = true
    GameState.checkpoint = Vector2(1400.0, SPAWN_Y)
    Sfx.play("pickup")
    broto.call("activate")
    hud.call("show_message", "Broto: Ei! Você me acordou! ...Espera. Aquilo ali é COR?!", 6.0)
    _tween_sat("seed", 1.0, 3.0)
    _warm(0.06)


func _on_first_talk_done() -> void:
    GameState.quest = GameState.QUEST_ACTIVE
    GameState.can_love = true
    GameState.set_stage(2)
    _tween_sat("garden", 1.0, 3.0)
    _warm(0.06)
    hud.call("show_message", "Você aprendeu ACOLHER (J). Vale para Murmúrios e para brotos murchos.", 7.0)
    _refresh_help()


func _on_befriended(m: Node2D) -> void:
    GameState.add_bond()
    var n := GameState.bonds
    m.set("friend_index", n - 1)
    _tween_sat("meadow", minf(float(n) / 3.0, 1.0), 2.5)
    _warm(0.06)
    player.call("refresh_breath", 1)
    if n == 1:
        GameState.can_dash = true
        GameState.set_stage(3)
        hud.call("show_message", "Brincando de pique com o Murmúrio, você aprendeu a ESQUIVA (K).", 6.0)
    elif n == 2:
        hud.call("show_message", "Eles seguem você agora. Dá até pra ouvir uns passinhos atrás.", 5.0)
    _refresh_help()


func _on_murmurio_noticed() -> void:
    if murmurio_hinted or not GameState.has_seed:
        return
    murmurio_hinted = true
    hud.call("show_message", "Broto: Ele não parece bravo. Parece só... barulhento.", 5.0)


func _on_mel_complimented() -> void:
    _tween_sat("mel", 1.0, 3.0)
    _raise_sat("street", 0.2, 4.0)
    _warm(0.08)


func _on_cat_trusted() -> void:
    _raise_sat("bakery", 0.4, 4.0)
    _warm(0.06)


func _on_pickup(kind: String) -> void:
    if kind == "hat":
        GameState.has_hat = true
        Sfx.play("pickup")
        hud.call("show_message", "Você pegou o chapéu de palha do Seu Bento. Meio amassado, mas inteiro.", 5.0)


func _on_hat_given() -> void:
    GameState.hat_returned = true
    bento.colorize()
    scenery.lamps["bento"].call("set_lit", true, 2.0)
    _tween_sat("bento", 1.0, 3.0)
    _raise_sat("street", 0.4, 4.0)
    _raise_sat("trees", 0.2, 4.0)
    _warm(0.08)


func _on_note_collected(_note_id: int, who: String, text: String) -> void:
    GameState.notes += 1
    Sfx.play("pickup")
    _raise_sat("world", minf(0.04 * float(GameState.notes), 0.2), 2.0)
    _warm(0.04)
    var done := GameState.notes >= GameState.NOTES_TOTAL
    var after := Callable(self, "_all_notes_found") if done else Callable()
    dialogue.call("start", [[who, text]], after)


func _all_notes_found() -> void:
    _raise_sat("world", 0.4, 3.0)
    dialogue.call("start", [
        ["Broto", "Wander... ninguém desistiu de você. Foi um pão, um peixe, uma planta regada. Coisa pequena."],
        ["Broto", "Parece que coisa pequena, quando junta, vira um monte."],
    ])


func _on_reward_given() -> void:
    GameState.set_stage(4)
    hud.call("show_message", "Você amarrou o fio dourado no pulso. Acolher alcança um pouco mais longe.", 6.0)


func _open_gate() -> void:
    var tween := create_tween()
    tween.tween_property(gate_fog, "modulate:a", 0.0, 2.0)
    tween.tween_callback(gate.queue_free)


## A névoa não deixa ninguém passar sozinho: com 2 amigos por perto, ela abre.
func _update_fog() -> void:
    if gate_opened or player.global_position.x < GATE_X - 200.0:
        return
    if GameState.bonds >= 2:
        gate_opened = true
        GameState.checkpoint = Vector2(2940.0, SPAWN_Y)
        _open_gate()
        hud.call("show_message", "A névoa se abre devagar, como se reconhecesse que você não está sozinho.", 7.0)
    elif not fog_hinted:
        fog_hinted = true
        hud.call("show_message", "A névoa parece espessa demais pra atravessar sozinho.", 6.0)


# ---------- O abraço ----------

func _on_hug_requested() -> void:
    _run_hug()


func _run_hug() -> void:
    GameState.input_locked = true
    var tars_x: float = tarsila.global_position.x
    var from_left: bool = player.global_position.x < tars_x
    var target_x := tars_x - 17.0 if from_left else tars_x + 17.0
    player.set("facing", 1.0 if from_left else -1.0)

    # Broto dá privacidade ao casal
    broto.visible = false

    # 1) Wander caminha até ela
    player.call("set_cutscene_anim", "walk")
    var distance := absf(player.global_position.x - target_x)
    var walk := create_tween()
    walk.tween_property(player, "position:x", target_x, maxf(distance / 90.0, 0.1))
    await walk.finished
    player.call("set_cutscene_anim", "idle")
    await get_tree().create_timer(0.4).timeout

    # 2) A câmera se aproxima
    var zoom_in := create_tween()
    zoom_in.tween_property(cam, "zoom", Vector2(1.8, 1.8), 1.2).set_trans(Tween.TRANS_SINE)
    await get_tree().create_timer(0.9).timeout

    # 3) O abraço: brilho, corações e a cor se espalhando
    var mid := Vector2((player.global_position.x + tars_x) / 2.0, GROUND_Y - 18.0)
    hug_fx.call("play", mid)
    tarsila.call("colorize")
    _tween_sat("bakery", 1.0, 3.0)
    _raise_sat("world", 0.45, 4.0)
    _warm(0.15)
    await get_tree().create_timer(3.2).timeout

    # 4) Volta ao normal
    var zoom_out := create_tween()
    zoom_out.tween_property(cam, "zoom", Vector2.ONE, 1.2).set_trans(Tween.TRANS_SINE)
    await zoom_out.finished
    player.call("set_cutscene_anim", "")
    broto.visible = GameState.has_seed
    GameState.input_locked = false
    tarsila.call("after_hug")


# ---------- Eco da Insônia ----------

func _start_boss_fight() -> void:
    boss.call("start_fight")


func _on_boss_activated() -> void:
    Sfx.boss_mode(true)
    var tween := create_tween()
    tween.tween_property(night, "color", Color(0.5, 0.52, 0.78), 2.0)


func _on_boss_defeated() -> void:
    GameState.boss_defeated = true
    GameState.set_stage(5)
    Sfx.boss_mode(false)
    await get_tree().create_timer(2.0).timeout
    dialogue.call("start", _boss_outro_lines(), Callable(self, "_finish_boss1"))


func _finish_boss1() -> void:
    GameState.can_rest = true
    _refresh_help()
    # Amanhece: a consequência da vitória aparece no mundo
    var tween := create_tween()
    tween.tween_property(night, "color", Color(1.0, 1.0, 1.0), 3.0)
    _tween_sat("world", 1.0, 5.0)
    _tween_sat("arena", 1.0, 5.0)
    _raise_sat("street", 0.6, 5.0)
    _raise_sat("hills", 0.7, 5.0)
    _raise_sat("trees", 0.6, 5.0)
    boss.call("colorize")
    scenery.lamps["gate"].call("set_lit", true, 2.0)
    scenery.lamps["gate2"].call("set_lit", true, 2.0)
    _warm(0.2)
    hud.call("show_message", "Você aprendeu DESCANSAR (segure S): recupera Fôlego. Descansar não é fraqueza.", 9.0)
    await get_tree().create_timer(10.0).timeout
    _open_gate2()
    hud.call("show_message", "Mais adiante, a névoa se abriu. Dá pra ver uma praça silenciosa.", 7.0)


func _open_gate2() -> void:
    gate2_opened = true
    GameState.checkpoint = Vector2(GATE2_X - 40.0, SPAWN_Y)
    var tween := create_tween()
    tween.tween_property(scenery.gate2_fog, "modulate:a", 0.0, 2.0)
    tween.tween_callback(scenery.gate2.queue_free)


# ---------- Eco da Solidão ----------

func _start_boss2_fight() -> void:
    boss2.call("start_fight")


func _on_boss2_activated() -> void:
    Sfx.boss_mode(true)
    var tween := create_tween()
    tween.tween_property(night, "color", Color(0.64, 0.68, 0.8), 2.0)


func _on_boss2_defeated() -> void:
    GameState.boss2_defeated = true
    Sfx.boss_mode(false)
    await get_tree().create_timer(2.5).timeout
    dialogue.call("start", _boss2_outro_lines(), Callable(self, "_finish_boss2"))


func _finish_boss2() -> void:
    GameState.set_stage(6)
    var tween := create_tween()
    tween.tween_property(night, "color", Color(1.0, 1.0, 1.0), 3.0)
    _tween_sat("plaza", 1.0, 5.0)
    _raise_sat("world", 0.75, 6.0)
    _raise_sat("street", 0.9, 6.0)
    _raise_sat("hills", 0.9, 6.0)
    boss2.call("colorize")
    for i in range(BENCH_XS.size()):
        scenery.lamps["plaza_%d" % i].call("set_lit", true, 2.5)
    var water := create_tween()
    water.tween_property(scenery.plaza_water, "modulate:a", 1.0, 3.0)
    scenery.plaza_clock.set("running", true)
    _warm(0.25)
    hud.call("show_message", "O relógio da torre voltou a andar. Wander agora carrega uma pequena luz própria.", 9.0)


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
        5, 6:
            target = 1.0
    var tween := create_tween()
    tween.tween_property(player_material, "shader_parameter/saturation", target, 2.0)


func _refresh_help() -> void:
    var text := "A/D: mover  |  Espaço: pular  |  E: interagir"
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
        ["Broto", "Wander, ela não parece querer briga. Parece só cansada demais pra parar. Fica de olho nas ovelhas. Se ela bocejar, talvez seja a hora."],
    ]


func _boss_outro_lines() -> Array:
    return [
        ["Insônia", "...Ah. Que silêncio gostoso. Eu tinha esquecido como era."],
        ["Insônia", "Obrigada por não gritar comigo."],
        ["Broto", "Boa noite, Insônia. A gente passa amanhã com o chá."],
    ]


func _boss2_intro_lines() -> Array:
    return [
        ["Solidão", "...Não precisa chegar perto. Já estou acostumada."],
        ["Broto", "Ela fala como quem pede desculpa por existir."],
        ["Solidão", "Todo mundo vai embora, uma hora. Aí eu fico. É mais fácil quando ninguém chega."],
        ["Broto", "Wander, olha os bancos. Tem gente sentada ali. Gente que também está sozinha. Talvez dê pra chegar perto de quem já está aqui."],
    ]


func _boss2_outro_lines() -> Array:
    return [
        ["Solidão", "...Tem alguém sentado do meu lado."],
        ["Solidão", "Eu acho que amanhã vou estar aqui de novo. Mas hoje não está ruim."],
        ["Broto", "É. Pra gente também. Amanhã a gente passa aqui."],
    ]
