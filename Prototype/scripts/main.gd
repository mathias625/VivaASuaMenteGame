extends Node2D
## MATIZ - protótipo, passo 1: movimentação + primeira cor.
## O nível é montado por código só para você ver tudo num arquivo.
## Mais tarde, vamos trocar por TileMap e cenas separadas.

const PlayerScript := preload("res://scripts/player.gd")
const SeedScript := preload("res://scripts/seed.gd")
const SaturationShader := preload("res://shaders/saturation.gdshader")

const SPAWN_POINT := Vector2(0, 388)
const SEED_POINT := Vector2(1275, 222)

var world_material: ShaderMaterial   # o mundo inteiro, começa cinza
var patch_material: ShaderMaterial   # o trecho que ganha cor primeiro
var message_label: Label
var message_tween: Tween


func _ready() -> void:
    _setup_input()
    world_material = _make_material(0.0)
    patch_material = _make_material(0.0)
    _build_world()
    _build_patch()
    _spawn_seed()
    _spawn_player()
    _build_hud()
    _show_message("Tudo está em silêncio.", 4.0)


# ---------- Entrada (teclas) ----------

func _setup_input() -> void:
    _add_action("move_left", [KEY_A, KEY_LEFT])
    _add_action("move_right", [KEY_D, KEY_RIGHT])
    _add_action("jump", [KEY_SPACE, KEY_W, KEY_UP])


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


func _on_seed_collected() -> void:
    _show_message("Broto: Ei! Você me acordou! ...Espera. Aquilo ali é COR?!", 6.0)
    var tween := create_tween()
    tween.tween_property(patch_material, "shader_parameter/saturation", 1.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ---------- Construção do mundo ----------

func _build_world() -> void:
    var world := Node2D.new()
    world.name = "World"
    add_child(world)

    var sky := ColorRect.new()
    sky.position = Vector2(-600, -400)
    sky.size = Vector2(2800, 1200)
    sky.color = Color(0.55, 0.75, 0.95)
    sky.material = world_material
    sky.z_index = -10
    world.add_child(sky)

    var ground_color := Color(0.45, 0.33, 0.22)
    _add_platform(world, Rect2(-300, 400, 1000, 300), ground_color, world_material)
    _add_platform(world, Rect2(790, 400, 900, 300), ground_color, world_material)

    var step_color := Color(0.5, 0.4, 0.3)
    _add_platform(world, Rect2(420, 350, 90, 16), step_color, world_material)
    _add_platform(world, Rect2(560, 300, 90, 16), step_color, world_material)
    _add_platform(world, Rect2(950, 350, 90, 16), step_color, world_material)
    _add_platform(world, Rect2(1090, 300, 90, 16), step_color, world_material)
    _add_platform(world, Rect2(1230, 250, 90, 16), step_color, world_material)

    # Paredes invisíveis nas bordas da fase
    var invisible := Color(0, 0, 0, 0)
    _add_platform(world, Rect2(-320, -200, 20, 900), invisible, world_material)
    _add_platform(world, Rect2(1690, -200, 20, 900), invisible, world_material)


func _build_patch() -> void:
    var patch := Node2D.new()
    patch.name = "Patch"
    add_child(patch)

    var grass := Color(0.35, 0.75, 0.35)
    _add_visual(patch, Rect2(1110, 396, 340, 6), grass, patch_material)
    _add_visual(patch, Rect2(1230, 246, 90, 5), grass, patch_material)

    var flower_colors := [Color(0.95, 0.4, 0.5), Color(0.98, 0.85, 0.3), Color(0.6, 0.5, 0.95)]
    var xs := [1140, 1190, 1245, 1300, 1355, 1410]
    for i in xs.size():
        var x: float = xs[i]
        _add_visual(patch, Rect2(x, 384, 3, 12), Color(0.25, 0.6, 0.3), patch_material)
        _add_visual(patch, Rect2(x - 3, 379, 9, 6), flower_colors[i % flower_colors.size()], patch_material)


func _add_visual(parent: Node, rect: Rect2, color: Color, mat: Material) -> void:
    var vis := ColorRect.new()
    vis.position = rect.position
    vis.size = rect.size
    vis.color = color
    vis.material = mat
    parent.add_child(vis)


func _add_platform(parent: Node, rect: Rect2, color: Color, mat: Material) -> void:
    var body := StaticBody2D.new()
    body.position = rect.position
    var shape := CollisionShape2D.new()
    var rect_shape := RectangleShape2D.new()
    rect_shape.size = rect.size
    shape.shape = rect_shape
    shape.position = rect.size / 2.0
    body.add_child(shape)
    _add_visual(body, Rect2(Vector2.ZERO, rect.size), color, mat)
    parent.add_child(body)


# ---------- Personagens e objetos ----------

func _spawn_seed() -> void:
    var seed_node: Node2D = SeedScript.new()
    seed_node.position = SEED_POINT
    seed_node.connect("collected", _on_seed_collected)
    add_child(seed_node)


func _spawn_player() -> void:
    var player: CharacterBody2D = PlayerScript.new()
    player.position = SPAWN_POINT
    player.material = world_material   # Wander também começa em tons de cinza
    add_child(player)

    var cam := Camera2D.new()
    cam.position_smoothing_enabled = true
    cam.position_smoothing_speed = 8.0
    cam.limit_left = -300
    cam.limit_right = 1690
    cam.limit_top = -200
    cam.limit_bottom = 520
    player.add_child(cam)
    cam.make_current()


# ---------- Interface ----------

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    var help := Label.new()
    help.text = "A/D ou setas: mover   |   Espaço: pular"
    help.position = Vector2(12, 8)
    layer.add_child(help)

    message_label = Label.new()
    message_label.position = Vector2(12, 325)
    message_label.size = Vector2(616, 30)
    layer.add_child(message_label)


func _show_message(text: String, seconds: float) -> void:
    message_label.text = text
    message_label.modulate.a = 1.0
    if message_tween and message_tween.is_valid():
        message_tween.kill()
    message_tween = create_tween()
    message_tween.tween_interval(seconds)
    message_tween.tween_property(message_label, "modulate:a", 0.0, 1.0)
