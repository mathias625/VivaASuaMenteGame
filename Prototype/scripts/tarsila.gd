extends Node2D
## Dona Tarsila, a padeira. Brava por fora, solitária por dentro.
## O abraço aqui é uma conversa: dá pra ficar do lado sem dizer nada,
## dá pra perguntar antes, dá pra só ficar mais um pouco. Nada é "o certo".
## A origem do node é nos pés dela.

signal hug_requested

const SaturationShader := preload("res://shaders/saturation.gdshader")

var _player: Node2D
var _dialogue
var _hud
var _material: ShaderMaterial
var _time := 0.0
var _prompt_shown := false


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
    tween.tween_property(_material, "shader_parameter/saturation", 1.0, 3.0)


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()
    if _player == null:
        return
    var near := absf(_player.global_position.x - global_position.x) < 55.0 and absf(_player.global_position.y - global_position.y) < 50.0
    var want_prompt: bool = near and _dialogue.can_start()
    if want_prompt != _prompt_shown:
        _prompt_shown = want_prompt
        _hud.call("set_prompt_owner", "tarsila", "E: conversar com Dona Tarsila" if want_prompt else "")
    if want_prompt and Input.is_action_just_pressed("interact"):
        _talk()


# ---------- Conversa ----------

func _talk() -> void:
    match GameState.tarsila_stage:
        0:
            GameState.tarsila_stage = 1
            _dialogue.start_choice(_lines_first(), _options_first(), Callable(self, "_on_first_choice"))
        1:
            _dialogue.start_choice(_lines_again(), _options_first(), Callable(self, "_on_first_choice"))
        2:
            _dialogue.start_choice(_lines_stay_again(), _options_hug(), Callable(self, "_on_hug_choice"))
        _:
            if GameState.boss_defeated:
                _dialogue.start(_lines_after_boss(), Callable(self, "_give_bread"))
            else:
                _dialogue.start(_lines_bread(), Callable(self, "_give_bread"))


func _options_first() -> Array:
    return ["Sentar ao lado dela, sem dizer nada", "Dizer que é só se acostumar", "Ir embora"]


func _options_hug() -> Array:
    return ["Perguntar: posso te abraçar?", "Só ficar mais um pouco"]


func _on_first_choice(index: int) -> void:
    match index:
        0:
            GameState.tarsila_stage = 2
            _dialogue.start_choice(_lines_open_up(), _options_hug(), Callable(self, "_on_hug_choice"))
        1:
            _dialogue.start(_lines_advice())
        _:
            _dialogue.start([["Tarsila", "Tá bom. A porta fica aberta."]])


func _on_hug_choice(index: int) -> void:
    if index == 0:
        _dialogue.start(_lines_hug_ask(), Callable(self, "_ask_hug"))
    else:
        _dialogue.start([["Tarsila", "Então fica mais um pouco. Pega um pão, ainda tá quente."]], Callable(self, "_give_bread"))


func _ask_hug() -> void:
    hug_requested.emit()


## Chamado pelo main.gd quando a cena do abraço termina.
func after_hug() -> void:
    GameState.tarsila_stage = 3
    _dialogue.start(_lines_after_hug(), Callable(self, "_after_hug_done"))


func _after_hug_done() -> void:
    GameState.checkpoint = Vector2(global_position.x - 40.0, 384.0)


func _give_bread() -> void:
    Sfx.play("pickup")
    _player.call("refresh_breath", 99)
    GameState.checkpoint = Vector2(global_position.x - 40.0, 384.0)
    _hud.call("show_message", "Pãozinho quentinho: Fôlego recuperado.", 4.0)


# ---------- Falas ----------

func _lines_first() -> Array:
    var lines: Array = []
    lines.append(["Tarsila", "Hm? Ah. Pode deixar o pão no balcão."])
    if GameState.has_seed:
        lines.append(["Broto", "Ela é brava! Eu gosto dela."])
    lines.append(["Tarsila", "...Não trouxe pão? Então não precisa de nada. Não fica parado na porta, que esfria o forno."])
    lines.append(["Tarsila", "Ah, reparou nas duas xícaras? Costume. Eu ainda arrumo a mesa pra dois."])
    return lines


func _lines_again() -> Array:
    return [
        ["Tarsila", "De novo aqui? O pão não vende sozinho. Mas tudo bem, pode ficar."],
        ["Tarsila", "Duas xícaras, como sempre. Não repara."],
    ]


func _lines_advice() -> Array:
    var lines: Array = []
    lines.append(["Tarsila", "Se acostumar... É, todo mundo diz isso. Obrigada."])
    lines.append(["Tarsila", "Agora vai, o forno tá chamando."])
    if GameState.has_seed:
        lines.append(["Broto", "Hm. Acho que ela não queria uma solução. Acho que queria... companhia?"])
    return lines


func _lines_open_up() -> Array:
    var lines: Array = []
    lines.append(["", "Você se senta no banco ao lado dela. Ela não diz nada por um tempo."])
    if GameState.has_seed:
        lines.append(["Broto", "(cochichando) Wander, isso é o silêncio mais confortável que já ouvi."])
    lines.append(["Tarsila", "A Beatriz, minha filha, foi estudar numa cidade grande. Ela liga todo domingo."])
    lines.append(["Tarsila", "Eu sempre atendo no segundo toque, pra ela não achar que fiquei esperando. Fiquei esperando."])
    lines.append(["Tarsila", "A casa ficou grande. E pão a gente aprende a fazer pra muita gente. Pra uma só, sobra."])
    lines.append(["", "O forno estala devagar. Ela te passa uma xícara."])
    lines.append(["Tarsila", "Toma. É a da outra."])
    return lines


func _lines_stay_again() -> Array:
    return [
        ["Tarsila", "Você voltou. Senta aí, o pão acabou de sair."],
        ["", "Vocês ficam um tempo vendo o forno esfriar devagar."],
    ]


func _lines_hug_ask() -> Array:
    return [
        ["Wander", "...Posso te abraçar?"],
        ["Tarsila", "...Pode. Só cuidado com a farinha."],
    ]


func _lines_after_hug() -> Array:
    var lines: Array = []
    lines.append(["Tarsila", "Nossa. Faz tempo. Desculpa, a farinha."])
    if GameState.has_seed:
        lines.append(["Broto", "(voltando) Terminei de olhar a farinha. Perdi alguma coisa?"])
        lines.append(["Tarsila", "Só o melhor abraço da padaria."])
    lines.append(["Tarsila", "Passa aqui quando der. Sempre tem pão. E come alguma coisa antes de ir pra torre, ninguém atravessa torre de barriga vazia."])
    return lines


func _lines_bread() -> Array:
    var lines: Array = []
    lines.append(["Tarsila", "Chegou na hora. O pão saiu agora. Come, Wander."])
    if GameState.cat_stage >= 2:
        lines.append(["Tarsila", "Viu o Marmelada ali no banco? Faz meses que ele só aceitava comida de longe."])
    return lines


func _lines_after_boss() -> Array:
    var lines: Array = []
    lines.append(["Tarsila", "Dormi a noite inteira. Pela primeira vez em semanas. Não sei o que você fez lá na torre, mas obrigada."])
    lines.append(["Tarsila", "Come, que o pão tá quentinho."])
    return lines


# ---------- Desenho ----------

func _draw() -> void:
    var bob := sin(_time * 2.0) * 1.0
    draw_set_transform(Vector2(0.0, bob), 0.0, Vector2.ONE)
    draw_rect(Rect2(-5.0, -6.0, 4.0, 6.0), Color(0.35, 0.25, 0.22))
    draw_rect(Rect2(1.0, -6.0, 4.0, 6.0), Color(0.35, 0.25, 0.22))
    draw_rect(Rect2(-8.0, -22.0, 16.0, 16.0), Color(0.85, 0.45, 0.5))
    draw_rect(Rect2(-5.0, -20.0, 10.0, 14.0), Color(0.97, 0.95, 0.9))
    draw_circle(Vector2(0.0, -27.0), 6.0, Color(0.96, 0.8, 0.66))
    draw_circle(Vector2(0.0, -35.0), 4.0, Color(0.55, 0.4, 0.35))
    draw_rect(Rect2(-6.0, -33.0, 12.0, 4.0), Color(0.55, 0.4, 0.35))
    draw_rect(Rect2(-2.5, -28.0, 1.5, 2.0), Color(0.1, 0.1, 0.1))
    draw_rect(Rect2(1.0, -28.0, 1.5, 2.0), Color(0.1, 0.1, 0.1))
    draw_circle(Vector2(-4.0, -25.0), 1.5, Color(0.95, 0.6, 0.6))
    draw_circle(Vector2(4.0, -25.0), 1.5, Color(0.95, 0.6, 0.6))
