extends Node2D
## Mel: criança agitada e curiosa. Cacheada. Hoje acordou achando o cabelo uma bagunça.
## Um elogio simples e específico muda o dia dela. Nada de missão: é só uma conversa.
## A origem do node é nos pés dela.

signal complimented

const SaturationShader := preload("res://shaders/saturation.gdshader")

var _player: Node2D
var _dialogue
var _hud
var _material: ShaderMaterial
var _time := 0.0
var _shine := 0.0
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
    _shine = 4.0
    var tween := create_tween()
    tween.tween_property(_material, "shader_parameter/saturation", 1.0, 2.5)


func _process(delta: float) -> void:
    _time += delta
    _shine = maxf(_shine - delta, 0.0)
    queue_redraw()
    if _player == null:
        return
    var near := absf(_player.global_position.x - global_position.x) < 50.0 and absf(_player.global_position.y - global_position.y) < 50.0
    var want_prompt: bool = near and _dialogue.can_start()
    if want_prompt != _prompt_shown:
        _prompt_shown = want_prompt
        _hud.call("set_prompt_owner", "mel", "E: falar com a Mel" if want_prompt else "")
    if want_prompt and Input.is_action_just_pressed("interact"):
        _talk()


# ---------- Conversa ----------

func _talk() -> void:
    if GameState.mel_stage == 0:
        _dialogue.start_choice(_lines_first(), _options_first(), Callable(self, "_on_first_choice"))
    else:
        _dialogue.start(_lines_small_talk())


func _options_first() -> Array:
    return ["Dizer: seu cabelo está brilhante hoje", "Perguntar o que ela está desenhando", "Seguir o caminho"]


func _options_second() -> Array:
    return ["Dizer: seu cabelo está brilhante hoje", "Seguir o caminho"]


func _on_first_choice(index: int) -> void:
    match index:
        0:
            _compliment()
        1:
            _dialogue.start_choice(_lines_drawing(), _options_second(), Callable(self, "_on_second_choice"))
        _:
            _dialogue.start([["Mel", "Tá. Tchau! Cuidado com o buraco ali atrás, eu já caí."]])


func _on_second_choice(index: int) -> void:
    if index == 0:
        _compliment()
    else:
        _dialogue.start([["Mel", "Tchau! Se achar um gato laranja, não corre atrás. Eu já tentei."]])


func _compliment() -> void:
    _dialogue.start(_lines_compliment(), Callable(self, "_after_compliment"))


func _after_compliment() -> void:
    GameState.mel_stage = 1
    colorize()
    complimented.emit()


func _lines_first() -> Array:
    return [
        ["Mel", "Oi, Wander! Ah... não olha pro meu cabelo. Hoje tá uma bagunça."],
        ["Mel", "Acordei em cima da hora e não deu pra fazer nada. Minha irmã tem o cabelo lisinho, perfeito. O meu parece que levou um susto."],
    ]


func _lines_drawing() -> Array:
    return [
        ["Mel", "Isso? É um gato! Não tá parecido, eu sei. Ele nunca fica parado pra eu desenhar."],
        ["Mel", "Mora na padaria da Tarsila. Foge de mim toda vez. Acho que eu faço barulho demais."],
    ]


func _lines_compliment() -> Array:
    var lines: Array = []
    lines.append(["Wander", "Seu cabelo está brilhante hoje."])
    lines.append(["Mel", "...Brilhante? Sério?"])
    lines.append(["Mel", "Normalmente só falam pra eu pentear."])
    lines.append(["Mel", "A minha vó diz que cacho é que nem planta: não adianta puxar, tem que deixar crescer do jeito dele."])
    lines.append(["Mel", "Acho que eu vou deixar solto hoje. Valeu, Wander."])
    if GameState.has_seed:
        lines.append(["Broto", "Eu também acho! Quer dizer, o meu cabelo é folha. Mas acho!"])
    lines.append(["Mel", "Ah, se passar na padaria: tem um gato laranja por lá. Foge de todo mundo. A Tarsila diz que é porque a gente tem pressa."])
    return lines


func _lines_small_talk() -> Array:
    var pool := [
        "O Seu Bento perguntou se eu tinha ido no salão. Falei que era o cabelo mesmo.",
        "Aprendi a assobiar, quer ouvir? ...Ih, saiu só ar. Vou treinar mais.",
        "Tô desenhando o gato da padaria de longe e inventando o resto. Ele sempre acaba com cinco patas.",
        "Minha irmã perguntou por que eu tava sorrindo à toa. Eu também não sei.",
    ]
    return [["Mel", pool[randi() % pool.size()]]]


# ---------- Desenho ----------

func _draw() -> void:
    var bob := sin(_time * 3.0) * 1.0
    draw_set_transform(Vector2(0.0, bob), 0.0, Vector2.ONE)
    var hair := Color(0.28, 0.18, 0.13)
    draw_rect(Rect2(-4.0, -6.0, 3.0, 6.0), Color(0.4, 0.3, 0.25))
    draw_rect(Rect2(1.0, -6.0, 3.0, 6.0), Color(0.4, 0.3, 0.25))
    draw_rect(Rect2(-6.0, -17.0, 12.0, 11.0), Color(0.98, 0.82, 0.3))
    # cabelo cacheado: um monte de cachos em volta da cabeça
    for p in [Vector2(-7.0, -19.0), Vector2(7.0, -19.0), Vector2(-6.0, -23.0), Vector2(6.0, -23.0), Vector2(-4.0, -27.0), Vector2(4.0, -27.0), Vector2(0.0, -29.0)]:
        draw_circle(p, 4.0, hair)
    draw_circle(Vector2(0.0, -21.0), 5.0, Color(0.8, 0.58, 0.42))
    draw_circle(Vector2(0.0, -25.0), 4.5, hair)
    draw_rect(Rect2(-2.5, -22.0, 1.5, 2.0), Color(0.1, 0.1, 0.1))
    draw_rect(Rect2(1.0, -22.0, 1.5, 2.0), Color(0.1, 0.1, 0.1))
    if GameState.mel_stage >= 1:
        draw_arc(Vector2(0.0, -19.5), 2.5, 0.3, PI - 0.3, 8, Color(0.5, 0.2, 0.2), 1.0)
        # brilho no cabelo
        draw_arc(Vector2(-2.0, -27.0), 6.0, PI * 1.05, PI * 1.55, 8, Color(1.0, 0.95, 0.8), 1.5)
    if _shine > 0.0:
        for i in range(6):
            var angle := _time * 1.5 + float(i) * 1.05
            var pos := Vector2(cos(angle) * 10.0, -25.0 + sin(angle * 1.7) * 7.0)
            var a := 0.5 + 0.5 * sin(_time * 8.0 + float(i))
            var c := Color(1.0, 0.97, 0.7, a)
            draw_line(pos + Vector2(-2.0, 0.0), pos + Vector2(2.0, 0.0), c, 1.0)
            draw_line(pos + Vector2(0.0, -2.0), pos + Vector2(0.0, 2.0), c, 1.0)
