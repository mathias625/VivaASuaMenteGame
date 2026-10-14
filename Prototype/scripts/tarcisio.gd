extends Node2D
## Tarcísio: jardineiro de humor seco, a primeira pessoa que volta a ter voz.
## Ele não dá missão. Conversa, e o que ele diz sobre os Murmúrios é um
## palpite de quem já passou por isso. A origem do node é nos pés dele.

signal first_talk_done
signal reward_given

const SaturationShader := preload("res://shaders/saturation.gdshader")

var _player: Node2D
var _dialogue
var _hud
var _material: ShaderMaterial
var _time := 0.0
var _prompt_shown := false
var _reward_done := false


func setup(player: Node2D, dialogue, hud) -> void:
    _player = player
    _dialogue = dialogue
    _hud = hud


func _ready() -> void:
    _material = ShaderMaterial.new()
    _material.shader = SaturationShader
    _material.set_shader_parameter("saturation", 0.0)
    material = _material


func colorize() -> void:
    var tween := create_tween()
    tween.tween_property(_material, "shader_parameter/saturation", 1.0, 2.5)


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()
    if _player == null:
        return
    var near := absf(_player.global_position.x - global_position.x) < 50.0 and absf(_player.global_position.y - global_position.y) < 50.0
    var want_prompt: bool = near and _dialogue.can_start()
    if want_prompt != _prompt_shown:
        _prompt_shown = want_prompt
        _hud.call("set_prompt_owner", "tarcisio", "E: conversar com Tarcísio" if want_prompt else "")
    if want_prompt and Input.is_action_just_pressed("interact"):
        _talk()


func _talk() -> void:
    if GameState.boss_defeated:
        _dialogue.start(_lines_after_boss())
    elif GameState.quest == GameState.QUEST_NONE:
        _dialogue.start(_lines_first(), Callable(self, "_on_first_done"))
    elif GameState.bonds >= 2 and not _reward_done:
        _dialogue.start(_lines_reward(), Callable(self, "_on_reward"))
    else:
        _dialogue.start(_lines_small_talk())


func _on_first_done() -> void:
    colorize()
    first_talk_done.emit()


func _on_reward() -> void:
    _reward_done = true
    reward_given.emit()


# ---------- Falas ----------

func _lines_first() -> Array:
    var lines: Array = []
    lines.append(["Tarcísio", "Ah, finalmente. Eu já achava que a porta tinha emperrado."])
    lines.append(["Tarcísio", "Não precisa falar nada. Ninguém fala muito por aqui ultimamente."])
    if GameState.has_seed:
        lines.append(["Broto", "Ele fala! Ele ME VIU! Wander, ele me viu!"])
        lines.append(["Tarcísio", "Vi. Um broto falante. Já vi coisa pior nessa horta. Uma vez uma ervilha me deu bom dia."])
    else:
        lines.append(["Tarcísio", "Cuidado onde pisa. A horta é teimosa: só dá ervilha, e reclama o tempo todo."])
    lines.append(["Tarcísio", "Tem uns bichinhos cinzentos rondando por aí. Os Murmúrios. Dão encontrão, ficam sussurrando pelos cantos."])
    lines.append(["Tarcísio", "Eu já tentei espantar, não adianta. Um dia só fiquei parado do lado de um, sem fazer nada, e ele foi se aquietando."])
    lines.append(["Tarcísio", "Se quiser tentar, estende a mão pra ele, devagar. É só apertar J. Funciona com broto murcho também."])
    return lines


func _lines_reward() -> Array:
    var lines: Array = []
    lines.append(["Tarcísio", "Opa. Olha só, você anda acompanhado."])
    lines.append(["Tarcísio", "Eu era assim, sabe? Achava que tinha que resolver tudo sozinho. Deu errado em quase tudo. Menos as ervilhas."])
    lines.append(["Tarcísio", "Escuta: lá no fim da trilha tem uma névoa. Mora uma moça lá que não dorme. Nunca vi a névoa deixar ninguém passar sozinho. Com companhia, ela costuma abrir."])
    lines.append(["Tarcísio", "Toma, é um fio da minha horta. Amarra no pulso. Não faz nada de mágico, mas dá um ar de quem sabe pra onde vai."])
    if GameState.has_seed:
        lines.append(["Broto", "Eu quero um fio também!"])
        lines.append(["Tarcísio", "Você já é um broto inteiro, ué."])
    return lines


func _lines_small_talk() -> Array:
    var pool := [
        "A ervilha desse ano tá com ideia própria. Nasceu torta.",
        "Sabia que samambaia fica emburrada se ninguém conversa com ela? Eu converso. Ela não responde, mas fico tranquilo.",
        "Hoje cedo vi um Murmúrio parado olhando as nuvens. Quase fiz companhia.",
        "Se passar na padaria, fala com a Tarsila. Ela finge que é brava.",
        "A Mel anda assobiando por aí. Ainda não saiu nenhuma música, mas o esforço é bonito.",
    ]
    return [["Tarcísio", pool[randi() % pool.size()]]]


func _lines_after_boss() -> Array:
    return [
        ["Tarcísio", "Ouvi o silêncio daqui. Foi o melhor barulho que escutei esse ano."],
        ["Tarcísio", "Você não derrotou a moça, né? Ajudou ela a dormir. É um serviço diferente."],
        ["Tarcísio", "Ela deve acordar de novo, mais dia menos dia. Mas agora você sabe o caminho da torre. E ela sabe quem leva o chá."],
        ["Broto", "Isso foi bonito, Tarcísio. Quase chorei folhas."],
    ]


# ---------- Desenho ----------

func _draw() -> void:
    var bob := sin(_time * 2.0) * 1.0
    draw_set_transform(Vector2(0.0, bob), 0.0, Vector2.ONE)
    draw_rect(Rect2(-5.0, -8.0, 4.0, 8.0), Color(0.4, 0.3, 0.22))
    draw_rect(Rect2(1.0, -8.0, 4.0, 8.0), Color(0.4, 0.3, 0.22))
    draw_rect(Rect2(-7.0, -22.0, 14.0, 14.0), Color(0.3, 0.5, 0.75))
    draw_rect(Rect2(-7.0, -22.0, 14.0, 3.0), Color(0.9, 0.9, 0.85))
    draw_rect(Rect2(7.0, -20.0, 3.0, 9.0), Color(0.96, 0.82, 0.68))
    draw_circle(Vector2(0.0, -27.0), 6.0, Color(0.96, 0.82, 0.68))
    draw_rect(Rect2(-5.0, -25.0, 10.0, 6.0), Color(0.92, 0.92, 0.9))
    draw_rect(Rect2(-2.5, -29.0, 1.5, 2.0), Color(0.1, 0.1, 0.1))
    draw_rect(Rect2(1.0, -29.0, 1.5, 2.0), Color(0.1, 0.1, 0.1))
    draw_rect(Rect2(-10.0, -34.0, 20.0, 3.0), Color(0.9, 0.78, 0.4))
    draw_rect(Rect2(-5.0, -39.0, 10.0, 6.0), Color(0.9, 0.78, 0.4))
