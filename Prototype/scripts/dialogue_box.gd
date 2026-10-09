extends CanvasLayer
## Caixa de diálogo com efeito de máquina de escrever.
## Cada fala é um array: ["Quem fala", "Texto"].
## Avance com E.

const CHARS_PER_SECOND := 50.0
const SPEAKER_COLORS := {
    "Tarcísio": Color(1.0, 0.8, 0.5),
    "Broto": Color(0.6, 1.0, 0.6),
    "Insônia": Color(0.75, 0.75, 1.0),
    "Wander": Color(1.0, 0.9, 0.9),
}

var is_open := false

var _lines: Array = []
var _index := 0
var _chars := 0.0
var _open_time := 0.0
var _since_close := 1.0
var _on_done: Callable = Callable()
var _panel: Panel
var _name_label: Label
var _text_label: Label
var _hint: Label


func _ready() -> void:
    layer = 5
    _panel = Panel.new()
    _panel.position = Vector2(20.0, 244.0)
    _panel.size = Vector2(600.0, 96.0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.08, 0.08, 0.1, 0.92)
    style.border_color = Color(0.9, 0.9, 0.9, 0.6)
    style.set_border_width_all(1)
    style.set_corner_radius_all(4)
    _panel.add_theme_stylebox_override("panel", style)
    _panel.visible = false
    add_child(_panel)

    _name_label = Label.new()
    _name_label.position = Vector2(14.0, 6.0)
    _name_label.add_theme_font_size_override("font_size", 13)
    _panel.add_child(_name_label)

    _text_label = Label.new()
    _text_label.position = Vector2(14.0, 28.0)
    _text_label.custom_minimum_size = Vector2(572.0, 0.0)
    _text_label.size = Vector2(572.0, 60.0)
    _text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _text_label.add_theme_font_size_override("font_size", 13)
    _panel.add_child(_text_label)

    _hint = Label.new()
    _hint.text = "[E] continuar"
    _hint.position = Vector2(490.0, 78.0)
    _hint.add_theme_font_size_override("font_size", 10)
    _hint.modulate = Color(1.0, 1.0, 1.0, 0.7)
    _panel.add_child(_hint)


func can_start() -> bool:
    return not is_open and _since_close > 0.3


func start(lines: Array, on_done: Callable = Callable()) -> void:
    if is_open or lines.is_empty():
        return
    _lines = lines
    _index = 0
    _on_done = on_done
    is_open = true
    _open_time = 0.0
    GameState.input_locked = true
    _panel.visible = true
    _show_line()


func _show_line() -> void:
    var line: Array = _lines[_index]
    var speaker: String = line[0]
    _name_label.text = speaker
    _name_label.add_theme_color_override("font_color", SPEAKER_COLORS.get(speaker, Color.WHITE))
    _text_label.text = line[1]
    _text_label.visible_characters = 0
    _chars = 0.0
    _hint.visible = false


func _process(delta: float) -> void:
    if not is_open:
        _since_close += delta
        return
    _open_time += delta
    var total := _text_label.text.length()
    if int(_chars) < total:
        _chars += CHARS_PER_SECOND * delta
        _text_label.visible_characters = mini(int(_chars), total)
    var finished := int(_chars) >= total
    _hint.visible = finished
    if _open_time > 0.25 and Input.is_action_just_pressed("interact"):
        if finished:
            _advance()
        else:
            _chars = float(total)
            _text_label.visible_characters = total


func _advance() -> void:
    _index += 1
    if _index >= _lines.size():
        _close()
    else:
        _show_line()


func _close() -> void:
    _panel.visible = false
    is_open = false
    _since_close = 0.0
    GameState.input_locked = false
    if _on_done.is_valid():
        _on_done.call()
