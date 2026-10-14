extends Node2D
## Animal pequeno do cenário (sprites do pack de animais): passeia por um
## trecho e para de vez em quando. A origem fica nos pés.

const FRAME := 16

var _sprite: AnimatedSprite2D
var _left := 0.0
var _right := 0.0
var _speed := 14.0
var _target := 0.0
var _wait := 0.0


func setup(tex: Texture2D, from_x: float, to_x: float, walk_speed: float, mat: Material) -> void:
    _left = from_x
    _right = to_x
    _speed = walk_speed
    material = mat
    var frames := SpriteFrames.new()
    frames.remove_animation("default")
    frames.add_animation("walk")
    frames.set_animation_speed("walk", 5.0)
    frames.set_animation_loop("walk", true)
    for i in range(4):
        var atlas := AtlasTexture.new()
        atlas.atlas = tex
        atlas.region = Rect2(float(i * FRAME), 0.0, float(FRAME), float(FRAME))
        frames.add_frame("walk", atlas)
    _sprite = AnimatedSprite2D.new()
    _sprite.sprite_frames = frames
    _sprite.position = Vector2(0.0, -8.0)
    _sprite.use_parent_material = true
    add_child(_sprite)
    _sprite.play("walk")
    position.x = randf_range(from_x, to_x)
    _target = position.x
    _wait = randf_range(0.5, 3.0)


func _process(delta: float) -> void:
    if _wait > 0.0:
        _wait -= delta
        _sprite.speed_scale = 0.3
        return
    var before := position.x
    position.x = move_toward(position.x, _target, _speed * delta)
    if absf(position.x - before) > 0.001:
        _sprite.flip_h = _target < before
        _sprite.speed_scale = 1.0
    else:
        _target = randf_range(_left, _right)
        _wait = randf_range(1.5, 4.5)
