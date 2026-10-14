extends Node
## Efeitos sonoros e música em camadas (autoload "Sfx").
## Os sons foram sintetizados para o projeto, então não dependem de licença externa.
## A música ganha camadas conforme o mundo recupera as cores.

const SFX := {
    "pickup": preload("res://assets/sfx/pickup.wav"),
    "knock": preload("res://assets/sfx/knock.wav"),
    "hit": preload("res://assets/sfx/hit.wav"),
    "love": preload("res://assets/sfx/love.wav"),
    "dash": preload("res://assets/sfx/dash.wav"),
    "color": preload("res://assets/sfx/color.wav"),
    "boss_hit": preload("res://assets/sfx/boss_hit.wav"),
    "warn": preload("res://assets/sfx/warn.wav"),
    "door": preload("res://assets/sfx/door.wav"),
    "purr": preload("res://assets/sfx/purr.wav"),
    "sleep": preload("res://assets/sfx/sleep.wav"),
    "blip": preload("res://assets/sfx/blip.wav"),
    "jump": preload("res://assets/sfx/jump.wav"),
    "shadow": preload("res://assets/sfx/shadow.wav"),
}
const MUSIC := {
    "pad": preload("res://assets/music/pad.wav"),
    "melody": preload("res://assets/music/melody.wav"),
    "warm": preload("res://assets/music/warm.wav"),
    "boss": preload("res://assets/music/boss.wav"),
}

var _players: Array = []
var _layers: Dictionary = {}
var _tweens: Dictionary = {}
var _progress := 0.0
var _boss_mode := false


func _ready() -> void:
    for i in range(6):
        var p := AudioStreamPlayer.new()
        add_child(p)
        _players.append(p)
    for key in MUSIC:
        var stream: AudioStreamWAV = MUSIC[key].duplicate()
        stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
        stream.loop_begin = 0
        stream.loop_end = stream.data.size() / 2
        var layer := AudioStreamPlayer.new()
        layer.stream = stream
        layer.volume_db = -60.0
        add_child(layer)
        layer.play()
        _layers[key] = layer
    _apply(0.5)


func play(sfx_name: String, volume_db: float = -6.0) -> void:
    if not SFX.has(sfx_name):
        return
    for p in _players:
        if not p.playing:
            p.stream = SFX[sfx_name]
            p.volume_db = volume_db
            p.play()
            return


func set_progress(value: float) -> void:
    _progress = clampf(value, 0.0, 1.0)
    _apply(3.0)


func boss_mode(on: bool) -> void:
    _boss_mode = on
    _apply(1.5)


func _targets() -> Dictionary:
    var t := {}
    t["pad"] = -22.0 if _boss_mode else -15.0
    t["melody"] = -60.0 if _boss_mode else lerpf(-60.0, -15.0, clampf((_progress - 0.1) / 0.4, 0.0, 1.0))
    t["warm"] = -60.0 if _boss_mode else lerpf(-60.0, -17.0, clampf((_progress - 0.45) / 0.45, 0.0, 1.0))
    t["boss"] = -11.0 if _boss_mode else -60.0
    return t


func _apply(seconds: float) -> void:
    var targets := _targets()
    for key in _layers:
        var layer: AudioStreamPlayer = _layers[key]
        if _tweens.has(key) and _tweens[key].is_valid():
            _tweens[key].kill()
        var tween := create_tween()
        tween.tween_property(layer, "volume_db", float(targets[key]), seconds)
        _tweens[key] = tween
