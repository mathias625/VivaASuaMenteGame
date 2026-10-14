extends CanvasLayer
## Caixa de diálogo com efeito de máquina de escrever e ESCOLHAS.
## Cada fala é um array: ["Quem fala", "Texto"]  (nome vazio = narração).
## E avança. Nas escolhas: W/S (ou setas) movem, E confirma.

const CHARS_PER_SECOND := 50.0
const SPEAKER_COLORS := {
    "Tarcísio": Color(1.0, 0.8, 0.5),
    "Tarsila": Color(1.0, 0.72, 0.78),
    "Broto": Color(0.6, 1.0, 0.6),
    "Insônia": Color(0.75, 0.75, 1.0),
    "Solidão": Color(0.7, 0.85, 0.95),
    "Bento": Color(0.7, 0.85, 1.0),
    "Mel": Color(1.0, 0.85, 0.5),
    "Wander": Color(1.0, 0.9, 0.9),
}

var is_open := false

var _lines: Array = []
var _index := 0
var _chars := 0.0
var _open_time := 0.0
var _since_close := 1.0
var _on_done: Callable = Callable()

var _options: Array = []
var _choice_cb: Callable = Callable()
var _choosing := false
var _selected := 0
var _choice_time := 0.0

var _panel: Panel
var _name_label: Label
var _text_label: Label
var _hint: Label
var _choice_panel: Panel
var _choice_labels: Array = []


func _ready() -> void:
    layer = 5
    _panel = _make_panel(Vector2(20.0, 244.0), Vector2(600.0, 96.0))
    _name_label = _make_label(_panel, Vector2(14.0, 6.0), 13)
    _text_label = _make_label(_panel, Vector2(14.0, 28.0), 13)
    _text_label.custom_minimum_size = Vector2(572.0, 0.0)
    _text_label.size = Vector2(572.0, 60.0)
    _text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _hint = _make_label(_panel, Vector2(490.0, 78.0), 10)
    _hint.text = "[E] continuar"
    _hint.modulate = Color(1.0, 1.0, 1.0, 0.7)

    _choice_panel = _make_panel(Vector2(300.0, 150.0), Vector2(320.0, 80.0))
    for i in range(3):
        var label := _make_label(_choice_panel, Vector2(12.0, 8.0 + 22.0 * float(i)), 12)
        _choice_labels.append(label)


func _make_panel(pos: Vector2, panel_size: Vector2) -> Panel:
    var panel := Panel.new()
    panel.position = pos
    panel.size = panel_size
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.08, 0.08, 0.1, 0.92)
    style.border_color = Color(0.9, 0.9, 0.9, 0.6)
    style.set_border_width_all(1)
    style.set_corner_radius_all(4)
    panel.add_theme_stylebox_override("panel", style)
    panel.visible = false
    add_child(panel)
    return panel


func _make_label(parent: Node, pos: Vector2, font_size: int) -> Label:
    var label := Label.new()
    label.position = pos
    label.add_theme_font_size_override("font_size", font_size)
    parent.add_child(label)
    return label


func can_start() -> bool:
    return not is_open and _since_close > 0.3


func start(lines: Array, on_done: Callable = Callable()) -> void:
    if is_open or lines.is_empty():
        return
    _lines = lines
    _index = 0
    _on_done = on_done
    _options = []
    _choosing = false
    is_open = true
    _open_time = 0.0
    GameState.input_locked = true
    _panel.visible = true
    _show_line()


## Mostra as falas e, no fim, uma lista de escolhas. on_choice recebe o índice.
func start_choice(lines: Array, options: Array, on_choice: Callable) -> void:
    if is_open or lines.is_empty() or options.is_empty():
        return
    start(lines)
    _options = options
    _choice_cb = on_choice


func _show_line() -> void:
    var line: Array = _lines[_index]
    var speaker: String = line[0]
    _name_label.text = speaker
    _name_label.add_theme_color_override("font_color", SPEAKER_COLORS.get(speaker, Color.WHITE))
    _text_label.text = line[1]
    _text_label.visible_characters = 0
    Sfx.play("blip", -16.0)
    _chars = 0.0
    _hint.visible = false


func _process(delta: float) -> void:
    if not is_open:
        _since_close += delta
        return
    _open_time += delta
    if _choosing:
        _choice_time += delta
        _update_choice()
        return
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
        if _options.is_empty():
            _close(true)
        else:
            _begin_choice()
    else:
        _show_line()


func _begin_choice() -> void:
    _choosing = true
    _selected = 0
    _choice_time = 0.0
    _hint.visible = false
    var count := _options.size()
    _choice_panel.size = Vector2(320.0, 16.0 + 22.0 * float(count))
    _choice_panel.position = Vector2(300.0, 236.0 - _choice_panel.size.y)
    for i in range(_choice_labels.size()):
        var label: Label = _choice_labels[i]
        label.visible = i < count
    _refresh_choices()
    _choice_panel.visible = true


func _refresh_choices() -> void:
    for i in range(_options.size()):
        var label: Label = _choice_labels[i]
        var selected := i == _selected
        label.text = ("> " if selected else "   ") + str(_options[i])
        label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5) if selected else Color(0.85, 0.85, 0.9))


func _update_choice() -> void:
    var count := _options.size()
    if Input.is_action_just_pressed("jump"):
        _selected = (_selected - 1 + count) % count
        _refresh_choices()
    elif Input.is_action_just_pressed("rest"):
        _selected = (_selected + 1) % count
        _refresh_choices()
    elif _choice_time > 0.2 and Input.is_action_just_pressed("interact"):
        _confirm_choice()


func _confirm_choice() -> void:
    var index := _selected
    var callback := _choice_cb
    _choice_cb = Callable()
    _options = []
    _choosing = false
    _choice_panel.visible = false
    _close(false)
    if callback.is_valid():
        callback.call(index)


func _close(call_done: bool) -> void:
    _panel.visible = false
    is_open = false
    _since_close = 0.0
    GameState.input_locked = false
    if call_done and _on_done.is_valid():
        _on_done.call()
