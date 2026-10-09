extends Node2D
## Tarcísio: jardineiro de humor seco, a primeira pessoa que volta a ter voz.
## A origem do node é nos pés dele.

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
        _hud.call("set_prompt", "E: conversar com Tarcísio" if want_prompt else "")
    if want_prompt and Input.is_action_just_pressed("interact"):
        _talk()


func _talk() -> void:
    if GameState.boss_defeated:
        _dialogue.start(_lines_after_boss())
    elif GameState.quest == GameState.QUEST_DONE:
        if not _reward_done:
            _dialogue.start(_lines_done(), Callable(self, "_on_reward"))
        else:
            _dialogue.start(_lines_hint())
    elif GameState.quest == GameState.QUEST_ACTIVE:
        _dialogue.start(_lines_active())
    else:
        _dialogue.start(_lines_first(), Callable(self, "_on_first_done"))


func _on_first_done() -> void:
    colorize()
    first_talk_done.emit()


func _on_reward() -> void:
    _reward_done = true
    reward_given.emit()


# ---------- Falas ----------

func _lines_first() -> Array:
    var lines: Array = []
    lines.append(["Tarcísio", "Ah. Você chegou. Eu já achava que a porta tinha emperrado."])
    lines.append(["Tarcísio", "Calma, não precisa dizer nada. Faz tempo que ninguém por aqui diz muita coisa."])
    if GameState.has_seed:
        lines.append(["Broto", "Ele fala! Ele ME VIU! Wander, ele me viu!"])
        lines.append(["Tarcísio", "Vi. Um broto falante. Já vi coisa pior nessa horta. Uma vez uma ervilha me deu bom dia."])
    else:
        lines.append(["Tarcísio", "Cuidado onde pisa. Essa horta é teimosa: só dá ervilha, e ainda reclama."])
    lines.append(["Tarcísio", "Escuta: por aqui vivem uns bichinhos cinzentos. Os Murmúrios."])
    lines.append(["Tarcísio", "Ficam sussurrando pelos cantos e dão uns encontrões na gente. Todo mundo acha que é pra brigar com eles."])
    lines.append(["Tarcísio", "Eu discordo. Eles só estão sozinhos. Fazem barulho porque é o único jeito que conhecem de chamar alguém."])
    lines.append(["Tarcísio", "Tenta assim: chega perto e oferece um pouco de carinho. Estende a mão e aperta J."])
    lines.append(["Tarcísio", "Faz isso com três deles e volta aqui. Sem pressa. Até planta teimosa cresce."])
    return lines


func _lines_active() -> Array:
    var lines: Array = []
    match GameState.bonds:
        0:
            lines.append(["Tarcísio", "Nenhum ainda? Tudo bem. Eles são tímidos. Chega devagar e aperta J quando estiver perto."])
            lines.append(["Tarcísio", "Se levar um encontrão, respira. Parar um pouco não é desistir, é manutenção."])
        1:
            lines.append(["Tarcísio", "Um já! Reparou que ele ganhou cor? Eles ficam assim quando alguém presta atenção."])
            lines.append(["Tarcísio", "Faltam dois. E essa esquiva que você aprendeu vai ser útil pra mais coisa do que Murmúrio."])
        _:
            lines.append(["Tarcísio", "Dois! Falta só um. Olha eles te seguindo... parecem patinhos."])
    return lines


func _lines_done() -> Array:
    return [
        ["Tarcísio", "Três! Olha só... eles te seguem como patinhos."],
        ["Tarcísio", "Sabe o que aprendi nessa horta? Quase nada nasce porque a gente grita com ele."],
        ["Tarcísio", "Agora que você tem companhia, posso contar. No fim da trilha, na torre do relógio, mora a Insônia."],
        ["Tarcísio", "Ela não é má. Só não dorme, e quem chega perto também não. Já levei chá pra ela. Ficou me olhando, de olhos arregalados."],
        ["Tarcísio", "Não vá achando que precisa derrotá-la. Ela está tão cansada que nem lembra por que continua acordada. Espere ela bocejar."],
        ["Broto", "Bocejar. Entendi. Isso eu sei fazer."],
        ["Tarcísio", "Toma. É um fio dourado da minha horta. Amarra no cachecol. Não faz nada de mágico, mas ajuda a andar mais firme."],
        ["Tarcísio", "A névoa do portão já se abriu. A torre é logo depois."],
    ]


func _lines_hint() -> Array:
    return [
        ["Tarcísio", "A torre fica depois do portão. Quando precisar, volta aqui pra prosear. A horta não vai a lugar nenhum."],
    ]


func _lines_after_boss() -> Array:
    return [
        ["Tarcísio", "Ouvi o silêncio daqui. Foi o melhor barulho que escutei esse ano."],
        ["Tarcísio", "E você não a derrotou. Você a ajudou a dormir. É um trabalho diferente."],
        ["Tarcísio", "Provavelmente ela acorda de novo. Mas agora você sabe onde fica a torre, e ela sabe quem leva o chá."],
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
