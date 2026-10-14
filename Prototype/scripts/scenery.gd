extends Node2D
## Cenário: fundo com profundidade, casa do Wander, adereços da vila e a praça.
## Tudo é montado por código a partir de retângulos (pixel art simples), com
## materiais de cor por região: cada região recupera a cor no seu momento.
##
## Regras de colisão: móveis ficam "no fundo" (o Wander passa na frente deles).
## Só o TOPO de alguns móveis é uma plataforma de mão única (dá para pular em
## cima da cama, da escrivaninha, do armário...). Nada trava o caminho.

const TreeScript := preload("res://scripts/tree.gd")
const LampScript := preload("res://scripts/lamp.gd")
const HillsScript := preload("res://scripts/hills.gd")
const CritterScript := preload("res://scripts/critter.gd")
const TEX_CHICKEN := preload("res://assets/animals/CluckingChicken.png")
const TEX_CHICK := preload("res://assets/animals/TinyChick.png")
const TEX_FROG := preload("res://assets/animals/LeapingFrog.png")
const TEX_SHEEP := preload("res://assets/animals/PasturingSheep.png")


class WallClock extends Node2D:
    var running := true
    var _time := 0.0

    func _process(delta: float) -> void:
        if running:
            _time += delta
        queue_redraw()

    func _draw() -> void:
        var dark := Color(0.3, 0.25, 0.2)
        draw_circle(Vector2.ZERO, 10.0, Color(0.92, 0.9, 0.85))
        draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 20, dark, 1.5)
        var minute := _time * 0.1
        var hour := _time * 0.0083 + 1.0
        draw_line(Vector2.ZERO, Vector2(sin(minute), -cos(minute)) * 8.0, dark, 1.0)
        draw_line(Vector2.ZERO, Vector2(sin(hour), -cos(hour)) * 5.0, dark, 1.5)


var mats: Dictionary = {}
var cam: Camera2D

# Peças da casa que o main.gd anima
var door_visual: ColorRect
var door_blocker: StaticBody2D
var fern_leaves: Array = []
var curtain_left: ColorRect
var curtain_right: ColorRect
var beam: Polygon2D
var beam_dust: CPUParticles2D
var shade: ColorRect
var desk_mess: Array = []
var desk_neat: Array = []
var lamps: Dictionary = {}

# Peças da praça
var plaza_clock
var plaza_water: ColorRect
var plaza_windows: Array = []
var gate2: StaticBody2D
var gate2_fog: ColorRect

var _parallax: Array = []
var _clouds: Array = []


func _process(delta: float) -> void:
    if cam != null:
        var cx := cam.get_screen_center_position().x
        for entry in _parallax:
            var node: Node2D = entry[0]
            node.position.x = cx * float(entry[1])
    for cloud in _clouds:
        cloud.position.x += 4.0 * delta
        if cloud.position.x > 4800.0:
            cloud.position.x = -800.0


# ---------- ferramentas de desenho e colisão ----------

func box(parent: Node, r: Rect2, color: Color, key: String = "house") -> ColorRect:
    var vis := ColorRect.new()
    vis.position = r.position
    vis.size = r.size
    vis.color = color
    vis.material = mats[key]
    parent.add_child(vis)
    return vis


func one_way(parent: Node, r: Rect2) -> void:
    var body := StaticBody2D.new()
    body.position = r.position
    var shape := CollisionShape2D.new()
    var rs := RectangleShape2D.new()
    rs.size = Vector2(r.size.x, 4.0)
    shape.shape = rs
    shape.position = Vector2(r.size.x / 2.0, 2.0)
    shape.one_way_collision = true
    body.add_child(shape)
    parent.add_child(body)


func solid(parent: Node, r: Rect2) -> StaticBody2D:
    var body := StaticBody2D.new()
    body.position = r.position
    var shape := CollisionShape2D.new()
    var rs := RectangleShape2D.new()
    rs.size = r.size
    shape.shape = rs
    shape.position = r.size / 2.0
    body.add_child(shape)
    parent.add_child(body)
    return body


func make_layer(layer_name: String) -> Node2D:
    var lay := Node2D.new()
    lay.name = layer_name
    add_child(lay)
    return lay


func add_lamp(parent: Node, lamp_name: String, pos: Vector2, kind: int, key: String) -> void:
    var lamp: Node2D = LampScript.new()
    lamp.set("kind", kind)
    lamp.position = pos
    lamp.material = mats[key]
    parent.add_child(lamp)
    lamps[lamp_name] = lamp


func add_tree(parent: Node, x: float, kind: int, size_factor: float, key: String) -> void:
    var tree: Node2D = TreeScript.new()
    tree.set("kind", kind)
    tree.set("size_factor", size_factor)
    tree.position = Vector2(x, 400.0)
    tree.material = mats[key]
    parent.add_child(tree)


func add_sign(parent: Node, x: float, text: String, key: String) -> void:
    box(parent, Rect2(x, 372.0, 2.0, 28.0), Color(0.5, 0.38, 0.28), key)
    box(parent, Rect2(x - 22.0, 364.0, 46.0, 12.0), Color(0.72, 0.58, 0.4), key)
    var label := Label.new()
    label.text = text
    label.position = Vector2(x - 20.0, 363.0)
    label.add_theme_font_size_override("font_size", 8)
    label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
    parent.add_child(label)


func add_bench(parent: Node, cx: float, y: float, key: String) -> void:
    var wood := Color(0.6, 0.45, 0.3)
    box(parent, Rect2(cx - 22.0, y - 24.0, 44.0, 3.0), wood, key)
    box(parent, Rect2(cx - 22.0, y - 14.0, 44.0, 4.0), wood, key)
    box(parent, Rect2(cx - 20.0, y - 10.0, 3.0, 10.0), Color(0.4, 0.3, 0.22), key)
    box(parent, Rect2(cx + 17.0, y - 10.0, 3.0, 10.0), Color(0.4, 0.3, 0.22), key)


func add_flowers(parent: Node, x0: float, x1: float, spacing: float, key: String) -> void:
    var colors := [Color(0.95, 0.4, 0.5), Color(0.98, 0.85, 0.3), Color(0.6, 0.5, 0.95), Color(0.95, 0.6, 0.3)]
    var x := x0
    var i := 0
    while x < x1:
        box(parent, Rect2(x, 388.0, 2.0, 8.0), Color(0.25, 0.6, 0.3), key)
        box(parent, Rect2(x - 2.0, 385.0, 6.0, 4.0), colors[i % colors.size()], key)
        x += spacing
        i += 1


# ---------- fundo: céu, colinas, vila distante e nuvens ----------

func build_background() -> void:
    var sky := make_layer("SkyBands")
    sky.z_index = -9
    box(sky, Rect2(-900.0, 150.0, 6200.0, 120.0), Color(0.7, 0.83, 0.95, 0.5), "world")
    box(sky, Rect2(-900.0, 250.0, 6200.0, 150.0), Color(0.85, 0.9, 0.95, 0.5), "world")

    var far: Node2D = HillsScript.new()
    far.set("base_y", 290.0)
    far.set("amp", 36.0)
    far.set("color", Color(0.55, 0.65, 0.72))
    far.material = mats["hills"]
    far.z_index = -9
    add_child(far)
    _parallax.append([far, 0.6])

    var town := make_layer("FarTown")
    town.z_index = -8
    town.material = mats["hills"]
    for i in range(26):
        var x := -700.0 + float(i) * 170.0
        var w := 40.0 + float((i * 13) % 30)
        var h := 30.0 + float((i * 17) % 40)
        box(town, Rect2(x, 372.0 - h, w, h + 30.0), Color(0.5, 0.56, 0.64), "hills")
        box(town, Rect2(x - 3.0, 368.0 - h, w + 6.0, 5.0), Color(0.42, 0.46, 0.55), "hills")
        box(town, Rect2(x + 6.0, 380.0 - h, 6.0, 7.0), Color(0.85, 0.85, 0.7), "hills")
    _parallax.append([town, 0.5])

    var near: Node2D = HillsScript.new()
    near.set("base_y", 338.0)
    near.set("amp", 24.0)
    near.set("phase", 2.0)
    near.set("color", Color(0.42, 0.58, 0.5))
    near.material = mats["hills"]
    near.z_index = -7
    add_child(near)
    _parallax.append([near, 0.35])

    for i in range(7):
        var cloud := Node2D.new()
        cloud.position = Vector2(-700.0 + float(i) * 780.0, 50.0 + float((i * 37) % 90))
        cloud.z_index = -8
        box(cloud, Rect2(0.0, 6.0, 46.0, 10.0), Color(1.0, 1.0, 1.0, 0.85), "world")
        box(cloud, Rect2(10.0, 0.0, 24.0, 10.0), Color(1.0, 1.0, 1.0, 0.85), "world")
        add_child(cloud)
        _clouds.append(cloud)


# ---------- a casa do Wander ----------

func build_house() -> void:
    var h := make_layer("House")
    var wall := Color(0.86, 0.78, 0.66)
    var trim := Color(0.72, 0.64, 0.52)
    var wood := Color(0.55, 0.4, 0.28)
    var wood_light := Color(0.68, 0.52, 0.36)
    var wood_dark := Color(0.4, 0.3, 0.22)
    var white := Color(0.93, 0.93, 0.96)
    var terracotta := Color(0.8, 0.45, 0.3)

    # estrutura
    box(h, Rect2(-560, 250, 530, 150), wall)
    box(h, Rect2(-560, 366, 530, 34), trim)
    box(h, Rect2(-560, 364, 530, 2), wood)
    box(h, Rect2(-576, 236, 562, 14), Color(0.35, 0.3, 0.3))
    box(h, Rect2(-576, 250, 16, 150), trim)
    box(h, Rect2(-560, 396, 530, 4), wood)
    box(h, Rect2(-30, 250, 16, 88), Color(0.7, 0.62, 0.52))
    box(h, Rect2(-30, 338, 2, 62), wall)
    box(h, Rect2(-16, 338, 2, 62), wall)
    door_visual = box(h, Rect2(-28, 338, 12, 62), Color(0.5, 0.35, 0.22))
    box(h, Rect2(-480, 394, 100, 3), Color(0.7, 0.3, 0.3))

    # janela com cortinas e cactos no parapeito
    box(h, Rect2(-432, 284, 48, 48), wood)
    box(h, Rect2(-430, 286, 44, 44), Color(0.78, 0.89, 1.0), "world")
    box(h, Rect2(-430, 316, 44, 14), Color(0.5, 0.65, 0.6), "hills")
    box(h, Rect2(-420, 311, 20, 6), Color(0.5, 0.65, 0.6), "hills")
    box(h, Rect2(-409, 286, 2, 44), wood)
    box(h, Rect2(-430, 307, 44, 2), wood)
    box(h, Rect2(-436, 330, 56, 4), wood_light)
    box(h, Rect2(-440, 278, 64, 3), wood)
    curtain_left = box(h, Rect2(-432, 282, 26, 50), Color(0.62, 0.52, 0.72), "curtain")
    curtain_right = box(h, Rect2(-406, 282, 26, 50), Color(0.62, 0.52, 0.72), "curtain")
    box(h, Rect2(-424, 322, 8, 8), terracotta, "fern")
    box(h, Rect2(-423, 312, 6, 10), Color(0.35, 0.65, 0.4), "fern")
    box(h, Rect2(-420, 315, 3, 3), Color(0.35, 0.65, 0.4), "fern")

    # raio de luz da janela (só aparece depois de abrir a cortina)
    beam = Polygon2D.new()
    beam.polygon = PackedVector2Array([Vector2(-430, 330), Vector2(-386, 330), Vector2(-330, 396), Vector2(-420, 396)])
    beam.color = Color(1.0, 0.96, 0.8, 0.0)
    h.add_child(beam)
    beam_dust = CPUParticles2D.new()
    beam_dust.position = Vector2(-385.0, 355.0)
    beam_dust.amount = 14
    beam_dust.lifetime = 6.0
    beam_dust.local_coords = false
    beam_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    beam_dust.emission_rect_extents = Vector2(34.0, 24.0)
    beam_dust.direction = Vector2(0.3, -1.0)
    beam_dust.spread = 60.0
    beam_dust.gravity = Vector2.ZERO
    beam_dust.initial_velocity_min = 1.0
    beam_dust.initial_velocity_max = 4.0
    beam_dust.scale_amount_min = 1.0
    beam_dust.scale_amount_max = 1.6
    beam_dust.color = Color(1.0, 0.97, 0.8, 0.7)
    beam_dust.emitting = false
    h.add_child(beam_dust)

    # cama com quadro e prateleirinha
    box(h, Rect2(-540, 290, 34, 24), wood)
    box(h, Rect2(-538, 292, 30, 20), Color(0.6, 0.7, 0.8))
    box(h, Rect2(-532, 300, 10, 12), Color(0.45, 0.55, 0.5))
    box(h, Rect2(-470, 320, 40, 3), wood)
    box(h, Rect2(-464, 312, 6, 8), Color(0.75, 0.55, 0.4))
    box(h, Rect2(-452, 314, 5, 6), Color(0.6, 0.65, 0.5))
    box(h, Rect2(-556, 352, 6, 44), wood)
    box(h, Rect2(-552, 384, 66, 10), wood)
    box(h, Rect2(-550, 376, 62, 8), white)
    box(h, Rect2(-548, 370, 18, 7), Color(0.95, 0.95, 1.0))
    box(h, Rect2(-528, 370, 42, 14), Color(0.5, 0.6, 0.8))
    box(h, Rect2(-486, 372, 4, 24), wood)
    one_way(h, Rect2(-550, 376, 62, 4))

    # criado-mudo com telefone, livro e abajur
    box(h, Rect2(-476, 376, 28, 24), wood)
    box(h, Rect2(-474, 386, 24, 2), wood_dark)
    box(h, Rect2(-464, 392, 4, 2), wood_dark)
    box(h, Rect2(-472, 372, 10, 4), Color(0.2, 0.2, 0.25))
    box(h, Rect2(-471, 373, 8, 2), Color(0.6, 0.8, 1.0))
    box(h, Rect2(-460, 370, 8, 6), Color(0.7, 0.3, 0.3))
    one_way(h, Rect2(-476, 376, 28, 4))

    # armário, caixas empilhadas e a caixa guardada no alto
    box(h, Rect2(-372, 330, 50, 70), wood)
    box(h, Rect2(-348, 332, 2, 66), wood_dark)
    box(h, Rect2(-352, 362, 2, 6), wood_dark)
    box(h, Rect2(-344, 362, 2, 6), wood_dark)
    box(h, Rect2(-374, 328, 54, 4), wood_light)
    box(h, Rect2(-362, 320, 22, 8), Color(0.75, 0.55, 0.4))
    box(h, Rect2(-363, 318, 24, 3), Color(0.82, 0.62, 0.46))
    one_way(h, Rect2(-374, 328, 54, 4))
    box(h, Rect2(-318, 366, 32, 34), Color(0.72, 0.56, 0.38))
    box(h, Rect2(-318, 378, 32, 2), Color(0.85, 0.72, 0.55))
    box(h, Rect2(-310, 384, 16, 8), white)
    one_way(h, Rect2(-318, 366, 32, 4))

    # escrivaninha, cadeira, papéis bagunçados e xícara
    box(h, Rect2(-278, 372, 78, 5), wood_light)
    box(h, Rect2(-276, 377, 4, 23), wood)
    box(h, Rect2(-206, 377, 4, 23), wood)
    box(h, Rect2(-250, 377, 32, 23), wood)
    box(h, Rect2(-248, 387, 28, 2), wood_dark)
    box(h, Rect2(-236, 382, 4, 2), wood_dark)
    box(h, Rect2(-236, 392, 4, 2), wood_dark)
    one_way(h, Rect2(-278, 372, 78, 4))
    box(h, Rect2(-196, 382, 18, 4), wood_dark)
    box(h, Rect2(-182, 364, 3, 20), wood_dark)
    box(h, Rect2(-194, 386, 2, 14), wood_dark)
    box(h, Rect2(-181, 386, 2, 14), wood_dark)
    desk_mess.append(box(h, Rect2(-272, 370, 14, 2), Color(0.95, 0.95, 0.95), "desk"))
    desk_mess.append(box(h, Rect2(-264, 367, 12, 3), Color(0.9, 0.88, 0.8), "desk"))
    desk_mess.append(box(h, Rect2(-254, 370, 10, 2), Color(0.97, 0.97, 0.97), "desk"))
    desk_mess.append(box(h, Rect2(-241, 368, 16, 4), Color(0.88, 0.88, 0.85), "desk"))
    desk_mess.append(box(h, Rect2(-242, 371, 18, 2), Color(0.75, 0.3, 0.3), "desk"))
    var neat_stack := box(h, Rect2(-268, 364, 14, 8), Color(0.96, 0.96, 0.96), "desk")
    var neat_book := box(h, Rect2(-248, 368, 14, 4), Color(0.75, 0.3, 0.3), "desk")
    neat_stack.modulate.a = 0.0
    neat_book.modulate.a = 0.0
    desk_neat.append(neat_stack)
    desk_neat.append(neat_book)
    box(h, Rect2(-222, 364, 8, 8), white, "desk")
    box(h, Rect2(-221, 365, 6, 2), Color(0.35, 0.22, 0.15), "desk")
    box(h, Rect2(-214, 366, 2, 4), white, "desk")
    box(h, Rect2(-228, 371, 10, 1), Color(0.3, 0.4, 0.8), "desk")

    # estante com livros pela metade
    box(h, Rect2(-168, 296, 38, 104), Color(0.45, 0.32, 0.22))
    box(h, Rect2(-166, 298, 34, 102), Color(0.35, 0.25, 0.18))
    var rows := [326.0, 356.0, 384.0]
    var palette := [Color(0.7, 0.3, 0.3), Color(0.3, 0.5, 0.7), Color(0.8, 0.7, 0.3), Color(0.4, 0.6, 0.4), Color(0.6, 0.4, 0.6), Color(0.85, 0.55, 0.3)]
    for ri in range(rows.size()):
        var row_y: float = rows[ri]
        box(h, Rect2(-166, row_y, 34, 2), wood)
        var x := -165.0
        var i := 0
        while x < -134.0:
            var w := 3.0 + float((i + ri) % 3)
            var book_h := 14.0 + float((i * 5 + ri * 3) % 9)
            box(h, Rect2(x, row_y - book_h, w, book_h), palette[(i + ri * 2) % palette.size()])
            x += w + 0.5
            i += 1

    # mesinha com a samambaia seca e uma planta pendurada murcha
    box(h, Rect2(-124, 372, 40, 4), wood)
    box(h, Rect2(-122, 376, 3, 24), wood)
    box(h, Rect2(-87, 376, 3, 24), wood)
    box(h, Rect2(-111, 358, 14, 14), terracotta, "fern")
    var heights := [10.0, 14.0, 17.0, 13.0, 9.0]
    for i in range(heights.size()):
        var leaf_h: float = heights[i]
        var lx := -109.0 + float(i) * 3.0
        fern_leaves.append(box(h, Rect2(lx, 358.0 - leaf_h, 2.0, leaf_h), Color(0.55, 0.45, 0.3), "fern"))
        fern_leaves.append(box(h, Rect2(lx - 2.0, 358.0 - leaf_h - 1.0, 6.0, 2.0), Color(0.55, 0.45, 0.3), "fern"))
    box(h, Rect2(-100, 296, 1, 18), wood_dark)
    box(h, Rect2(-105, 314, 10, 8), terracotta, "fern")
    for vine in [[-103.0, 10.0], [-100.0, 14.0], [-97.0, 8.0]]:
        fern_leaves.append(box(h, Rect2(float(vine[0]), 322.0, 1.0, float(vine[1])), Color(0.55, 0.45, 0.3), "fern"))

    # calendário riscado e relógio de parede
    box(h, Rect2(-80, 300, 20, 26), Color(0.95, 0.95, 0.92))
    box(h, Rect2(-80, 300, 20, 5), Color(0.75, 0.3, 0.3))
    for idx in range(20):
        var cx := -78.0 + float(idx % 5) * 3.6
        var cy := 307.0 + float(idx / 5) * 4.5
        box(h, Rect2(cx, cy, 2.5, 3.0), Color(0.82, 0.82, 0.8))
        if idx < 16:
            box(h, Rect2(cx + 0.5, cy + 1.0, 1.5, 1.0), Color(0.3, 0.3, 0.35))
    var clock := WallClock.new()
    clock.position = Vector2(-48.0, 296.0)
    clock.material = mats["house"]
    h.add_child(clock)

    # objetos pelo chão: os pequenos sinais da rotina de Wander
    box(h, Rect2(-500, 396, 5, 3), Color(0.4, 0.45, 0.6))
    box(h, Rect2(-493, 396, 5, 3), Color(0.4, 0.45, 0.6))
    box(h, Rect2(-436, 397, 5, 3), Color(0.8, 0.8, 0.85))
    box(h, Rect2(-286, 396, 5, 4), white)
    box(h, Rect2(-428, 382, 16, 18), Color(0.7, 0.55, 0.35))
    box(h, Rect2(-426, 378, 12, 5), Color(0.6, 0.7, 0.85))
    box(h, Rect2(-58, 397, 8, 3), white)
    box(h, Rect2(-50, 396, 8, 3), white)
    box(h, Rect2(-46, 397, 3, 2), Color(0.75, 0.3, 0.3))
    box(h, Rect2(-12, 398, 22, 2), Color(0.5, 0.38, 0.25), "world")
    box(h, Rect2(2, 388, 16, 12), Color(0.9, 0.85, 0.7), "world")
    box(h, Rect2(4, 391, 12, 6), Color(0.78, 0.55, 0.3), "world")

    # penumbra do quarto: clareia quando Wander cuida do espaço
    shade = box(h, Rect2(-560, 250, 530, 150), Color(0.08, 0.08, 0.16, 0.2))
    add_lamp(h, "night", Vector2(-452.0, 376.0), 1, "house")
    add_lamp(h, "desk", Vector2(-208.0, 372.0), 1, "house")

    # a porta só abre depois da batida
    door_blocker = solid(h, Rect2(-30, 250, 16, 150))


# ---------- adereços da vila ----------

func build_street() -> void:
    var s := make_layer("Street")
    var trees := [
        [110.0, 0, 1.0, "trees"], [360.0, 1, 1.1, "trees"], [505.0, 2, 1.0, "trees"],
        [1000.0, 0, 1.0, "trees"], [1075.0, 2, 1.0, "trees"], [1190.0, 1, 1.2, "trees"],
        [2060.0, 2, 1.0, "trees"], [2230.0, 0, 1.1, "trees"], [2650.0, 1, 1.0, "trees"], [2880.0, 0, 1.0, "trees"],
        [3060.0, 3, 1.0, "arena"], [3320.0, 3, 1.0, "arena"], [3700.0, 3, 1.1, "arena"],
        [3895.0, 3, 1.0, "plaza"], [4645.0, 3, 1.0, "plaza"],
    ]
    for t in trees:
        add_tree(s, float(t[0]), int(t[1]), float(t[2]), str(t[3]))

    add_lamp(s, "start", Vector2(70.0, 400.0), 0, "street")
    add_lamp(s, "bento", Vector2(1425.0, 400.0), 0, "bento")
    add_lamp(s, "bakery", Vector2(1998.0, 400.0), 0, "bakery")
    add_lamp(s, "gate", Vector2(2950.0, 400.0), 0, "street")
    add_lamp(s, "gate2", Vector2(3810.0, 400.0), 0, "street")

    add_sign(s, 1700.0, "HORTA", "garden")
    add_sign(s, 2880.0, "PRAÇA", "street")
    add_sign(s, 40.0, "CASA", "street")

    # cerca no começo do caminho
    for i in range(5):
        box(s, Rect2(90.0 + float(i) * 14.0, 380.0, 3.0, 18.0), Color(0.6, 0.45, 0.3), "street")
    box(s, Rect2(90.0, 385.0, 59.0, 3.0), Color(0.6, 0.45, 0.3), "street")

    # casa da Mel (ganha cor quando ela recebe o elogio)
    box(s, Rect2(785.0, 352.0, 60.0, 48.0), Color(0.95, 0.8, 0.55), "mel")
    box(s, Rect2(779.0, 338.0, 72.0, 14.0), Color(0.55, 0.45, 0.65), "mel")
    box(s, Rect2(798.0, 370.0, 12.0, 30.0), Color(0.55, 0.38, 0.25), "mel")
    box(s, Rect2(820.0, 362.0, 14.0, 12.0), Color(0.6, 0.8, 0.95), "mel")
    box(s, Rect2(818.0, 374.0, 18.0, 4.0), Color(0.5, 0.35, 0.25), "mel")
    add_flowers(s, 780.0, 860.0, 10.0, "mel")

    # cantinho do Seu Bento: caixotes, rede e banco
    box(s, Rect2(1368.0, 384.0, 16.0, 16.0), Color(0.65, 0.5, 0.35), "bento")
    box(s, Rect2(1372.0, 372.0, 12.0, 12.0), Color(0.6, 0.45, 0.32), "bento")
    box(s, Rect2(1440.0, 360.0, 2.0, 40.0), Color(0.5, 0.38, 0.28), "bento")
    box(s, Rect2(1442.0, 364.0, 14.0, 12.0), Color(0.8, 0.8, 0.7, 0.8), "bento")
    add_bench(s, 1340.0, 396.0, "bento")

    # puxadinho do Tarcísio
    box(s, Rect2(1696.0, 360.0, 32.0, 40.0), Color(0.7, 0.58, 0.42), "garden")
    box(s, Rect2(1692.0, 352.0, 40.0, 8.0), Color(0.5, 0.3, 0.25), "garden")
    box(s, Rect2(1704.0, 376.0, 10.0, 24.0), Color(0.5, 0.35, 0.25), "garden")

    # mirante: plataforma alta com banco e placa
    add_bench(s, 640.0, 292.0, "street")
    add_sign(s, 668.0, "VISTA", "street")

    # vasos de flores
    for x in [1458.0, 1768.0, 2000.0]:
        box(s, Rect2(x, 388.0, 8.0, 8.0), Color(0.8, 0.45, 0.3), "street")
        box(s, Rect2(x + 1.0, 382.0, 6.0, 6.0), Color(0.95, 0.5, 0.6), "street")


func spawn_critters() -> void:
    _critter(TEX_CHICKEN, 1795.0, 1900.0, 9.0, "bakery")
    _critter(TEX_CHICKEN, 1800.0, 1905.0, 8.0, "bakery")
    _critter(TEX_CHICK, 1690.0, 1735.0, 10.0, "garden")
    _critter(TEX_FROG, 1420.0, 1470.0, 12.0, "seed")
    _critter(TEX_SHEEP, 2200.0, 2380.0, 7.0, "meadow")


func _critter(tex: Texture2D, x0: float, x1: float, walk_speed: float, key: String) -> void:
    var c: Node2D = CritterScript.new()
    c.position = Vector2(x0, 400.0)
    c.call("setup", tex, x0, x1, walk_speed, mats[key])
    add_child(c)


# ---------- a praça abandonada (arena do Eco da Solidão) ----------

func build_plaza(left: float, right: float, bench_xs: Array, gate_x: float) -> void:
    var p := make_layer("Plaza")
    var stone := Color(0.62, 0.62, 0.66)
    var stone_dark := Color(0.48, 0.48, 0.54)

    # prédios ao fundo, com janelas que acendem depois da vitória
    var buildings := [[3890.0, 260.0, 90.0], [3990.0, 230.0, 70.0], [4080.0, 280.0, 60.0], [4310.0, 240.0, 100.0], [4430.0, 270.0, 80.0], [4530.0, 220.0, 90.0], [4630.0, 260.0, 60.0]]
    for b in buildings:
        var bx: float = b[0]
        var by: float = b[1]
        var bw: float = b[2]
        box(p, Rect2(bx, by, bw, 400.0 - by), Color(0.52, 0.54, 0.62), "plaza")
        box(p, Rect2(bx - 3.0, by - 4.0, bw + 6.0, 6.0), stone_dark, "plaza")
        var wy := by + 14.0
        while wy < 372.0:
            var wx := bx + 8.0
            while wx < bx + bw - 12.0:
                plaza_windows.append(box(p, Rect2(wx, wy, 8.0, 10.0), Color(0.95, 0.88, 0.55), "plaza"))
                wx += 20.0
            wy += 26.0

    # torre do relógio parado (volta a andar depois da vitória)
    box(p, Rect2(4250.0, 170.0, 40.0, 230.0), Color(0.58, 0.58, 0.64), "plaza")
    box(p, Rect2(4244.0, 166.0, 52.0, 8.0), stone_dark, "plaza")
    var roof := Polygon2D.new()
    roof.polygon = PackedVector2Array([Vector2(4244.0, 166.0), Vector2(4296.0, 166.0), Vector2(4270.0, 138.0)])
    roof.color = Color(0.4, 0.32, 0.36)
    roof.material = mats["plaza"]
    p.add_child(roof)
    plaza_clock = WallClock.new()
    plaza_clock.running = false
    plaza_clock.position = Vector2(4270.0, 200.0)
    plaza_clock.scale = Vector2(1.6, 1.6)
    plaza_clock.material = mats["plaza"]
    p.add_child(plaza_clock)

    # grade ao fundo
    var gx := left
    while gx < right:
        box(p, Rect2(gx, 372.0, 2.0, 26.0), stone_dark, "plaza")
        gx += 14.0
    box(p, Rect2(left, 376.0, right - left, 2.0), stone_dark, "plaza")

    # fonte seca (a água volta no final)
    box(p, Rect2(4096.0, 378.0, 88.0, 22.0), stone, "plaza")
    box(p, Rect2(4100.0, 382.0, 80.0, 14.0), stone_dark, "plaza")
    box(p, Rect2(4136.0, 346.0, 8.0, 34.0), stone, "plaza")
    box(p, Rect2(4124.0, 342.0, 32.0, 6.0), stone, "plaza")
    plaza_water = box(p, Rect2(4102.0, 386.0, 76.0, 8.0), Color(0.5, 0.75, 0.95), "plaza")
    plaza_water.modulate.a = 0.0

    # bancos e lampiões (um por silhueta)
    for i in range(bench_xs.size()):
        var cx: float = bench_xs[i]
        add_bench(p, cx, 400.0, "plaza")
        add_lamp(p, "plaza_%d" % i, Vector2(cx + 36.0, 400.0), 2, "plaza")

    # caixotes: plataformas baixas para escapar das ondas de sombra
    for crate_x in [4180.0, 4440.0]:
        box(p, Rect2(crate_x, 364.0, 90.0, 36.0), Color(0.62, 0.48, 0.34), "plaza")
        box(p, Rect2(crate_x + 2.0, 366.0, 86.0, 2.0), Color(0.45, 0.34, 0.24), "plaza")
        box(p, Rect2(crate_x + 44.0, 366.0, 2.0, 32.0), Color(0.45, 0.34, 0.24), "plaza")
        solid(p, Rect2(crate_x, 364.0, 90.0, 16.0))

    # lixo e jornais no chão: a praça está parada há um tempo
    box(p, Rect2(3960.0, 396.0, 10.0, 3.0), Color(0.85, 0.85, 0.8), "plaza")
    box(p, Rect2(4390.0, 394.0, 12.0, 5.0), Color(0.8, 0.8, 0.75), "plaza")
    box(p, Rect2(4620.0, 380.0, 12.0, 20.0), stone_dark, "plaza")

    # muro de névoa entre a arena da Insônia e a praça
    gate2 = solid(p, Rect2(gate_x, -200.0, 20.0, 900.0))
    gate2_fog = ColorRect.new()
    gate2_fog.position = Vector2(gate_x - 30.0, -200.0)
    gate2_fog.size = Vector2(80.0, 900.0)
    gate2_fog.color = Color(0.35, 0.35, 0.42, 0.85)
    p.add_child(gate2_fog)
