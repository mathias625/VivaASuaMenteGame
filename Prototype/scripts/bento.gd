extends Node2D
## Seu Bento: pescador de poucas palavras que perdeu o chapéu num dia de vento.
## Um favor pequeno (achar um objeto) e uma conversa. Sem pressão.
## A origem do node é nos pés dele.

signal hat_given

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
        _hud.call("set_prompt_owner", "bento", "E: conversar com Seu Bento" if want_prompt else "")
    if want_prompt and Input.is_action_just_pressed("interact"):
        _talk()


func _talk() -> void:
    if GameState.hat_returned:
        _dialogue.start(_lines_small_talk())
    elif GameState.has_hat:
        _dialogue.start(_lines_return(), Callable(self, "_on_return"))
    else:
        _dialogue.start(_lines_lost())


func _on_return() -> void:
    hat_given.emit()


func _lines_lost() -> Array:
    var lines: Array = []
    lines.append(["Bento", "Ei. Você viu um chapéu de palha por aí? Ventou ontem e ele saiu voando."])
    lines.append(["Bento", "Tenho quase certeza que foi parar naquela pedra alta, perto da horta do Tarcísio. Mas meu joelho não deixa eu subir."])
    lines.append(["Bento", "Não é urgente. É que sem ele o sol bate na minha cabeça e eu fico mal-humorado."])
    if GameState.has_seed:
        lines.append(["Broto", "Você já é mal-humorado."])
        lines.append(["Bento", "...Sem o chapéu, mais."])
    return lines


func _lines_return() -> Array:
    return [
        ["Bento", "...Esse é o meu chapéu. Você subiu lá?"],
        ["Bento", "Obrigado. Eu ia dizer que não precisava, mas precisava."],
        ["", "Seu Bento ajeita o chapéu, acende o lampião do poste ao lado e senta de novo. Parece outra pessoa."],
        ["Bento", "Se achar um gato roubando peixe de degrau, não fui eu que mandei."],
    ]


func _lines_small_talk() -> Array:
    var pool := [
        "O sol bate melhor quando a cabeça tá coberta.",
        "Hoje o peixe não quis conversa. Eu também não, então ficamos quites.",
        "Esse poste aqui foi o Tarcísio que fez. Ficou torto, mas ilumina.",
        "Quando o vento aperta, eu seguro o chapéu com as duas mãos. Aprendi do jeito difícil.",
    ]
    return [["Bento", pool[randi() % pool.size()]]]


func _draw() -> void:
    var bob := sin(_time * 1.6) * 1.0
    draw_set_transform(Vector2(0.0, bob), 0.0, Vector2.ONE)
    draw_rect(Rect2(-5.0, -8.0, 4.0, 8.0), Color(0.3, 0.3, 0.35))
    draw_rect(Rect2(1.0, -8.0, 4.0, 8.0), Color(0.3, 0.3, 0.35))
    draw_rect(Rect2(-8.0, -23.0, 16.0, 15.0), Color(0.35, 0.5, 0.6))
    draw_circle(Vector2(0.0, -28.0), 6.0, Color(0.9, 0.72, 0.58))
    draw_rect(Rect2(-4.0, -26.0, 8.0, 5.0), Color(0.85, 0.85, 0.85))
    draw_rect(Rect2(-2.5, -30.0, 1.5, 2.0), Color(0.1, 0.1, 0.1))
    draw_rect(Rect2(1.0, -30.0, 1.5, 2.0), Color(0.1, 0.1, 0.1))
    draw_line(Vector2(9.0, -22.0), Vector2(18.0, -42.0), Color(0.5, 0.35, 0.2), 2.0)
    if GameState.hat_returned:
        draw_rect(Rect2(-10.0, -34.0, 20.0, 3.0), Color(0.9, 0.78, 0.4))
        draw_rect(Rect2(-5.0, -39.0, 10.0, 6.0), Color(0.92, 0.8, 0.45))
