extends Node2D
## Objeto examinável: mostra um aviso "E: ..." quando o jogador chega perto
## e avisa o main.gd (sinal "interacted"). Quem decide o que acontece é o main.
## A origem do node fica na altura dos pés do jogador (chão ou topo de móvel).

signal interacted(id: String)

var enabled := true
var reach := 18.0

var _id := ""
var _prompt := ""
var _player: Node2D
var _dialogue
var _hud
var _shown := false


func setup(player: Node2D, dialogue, hud, id: String, prompt: String) -> void:
    _player = player
    _dialogue = dialogue
    _hud = hud
    _id = id
    _prompt = prompt


func _process(_delta: float) -> void:
    if _player == null:
        return
    var feet_y: float = _player.global_position.y + 15.0
    var near := enabled and absf(_player.global_position.x - global_position.x) < reach and absf(feet_y - global_position.y) < 22.0
    var want: bool = near and _dialogue.can_start() and not GameState.input_locked
    if want != _shown:
        _shown = want
        _hud.call("set_prompt_owner", "obs_" + _id, _prompt if want else "")
    if want and Input.is_action_just_pressed("interact"):
        interacted.emit(_id)
