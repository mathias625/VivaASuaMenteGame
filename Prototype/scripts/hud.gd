extends CanvasLayer
## Interface: Fôlego, avisos de interação, mensagens, título do chefe e barra do chefe.
## Tudo discreto: o que não é necessário no momento some ou fica transparente.


class Bars extends Control:
    var breath := 4
    var max_breath := 4
    var boss_visible := false
    var boss_fraction := 1.0
    var boss_marks: Array = []
    var _time := 0.0

    func _process(delta: float) -> void:
        _time += delta
        if breath <= 1 or boss_visible:
            queue_redraw()

    func _draw() -> void:
        draw_rect(Rect2(8.0, 34.0, 12.0 + float(max_breath) * 16.0, 20.0), Color(0.0, 0.0, 0.0, 0.35))
        for i in range(max_breath):
            var filled := i < breath
            var color := Color(1.0, 0.85, 0.3) if filled else Color(0.25, 0.25, 0.3, 0.9)
            if filled and breath <= 1 and max_breath > 1:
                color = Color(1.0, 0.45, 0.35).lerp(Color(1.0, 0.85, 0.3), 0.5 + 0.5 * sin(_time * 8.0))
            draw_circle(Vector2(20.0 + float(i) * 16.0, 44.0), 5.5, color)
        if boss_visible:
            draw_rect(Rect2(168.0, 14.0, 304.0, 12.0), Color(0.0, 0.0, 0.0, 0.65))
            draw_rect(Rect2(170.0, 16.0, 300.0 * boss_fraction, 8.0), Color(0.75, 0.7, 1.0))
            for mark in boss_marks:
                draw_rect(Rect2(170.0 + 300.0 * float(mark) - 1.0, 14.0, 2.0, 12.0), Color(1.0, 1.0, 1.0, 0.8))


var _bars: Bars
var _help: Label
var _breath_label: Label
var _boss_label: Label
var _title: Label
var _message_panel: Panel
var _message: Label
var _prompt_panel: Panel
var _prompt: Label
var _prompts: Dictionary = {}
var _msg_tween: Tween
var _title_tween: Tween
var _help_tween: Tween


func _ready() -> void:
    layer = 1
    _bars = Bars.new()
    _bars.size = Vector2(640.0, 360.0)
    _bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_bars)

    _help = _make_label(self, Vector2(10.0, 6.0), 10)
    _breath_label = _make_label(self, Vector2(10.0, 19.0), 9)
    _breath_label.text = "Fôlego"
    _boss_label = _make_label(self, Vector2(170.0, 28.0), 11)
    _boss_label.visible = false

    _prompt_panel = _make_panel(Vector2(220.0, 262.0), Vector2(200.0, 22.0))
    _prompt = _make_label(_prompt_panel, Vector2(10.0, 3.0), 12)

    _message_panel = _make_panel(Vector2(24.0, 300.0), Vector2(592.0, 36.0))
    _message = _make_label(_message_panel, Vector2(10.0, 5.0), 12)
    _message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _message.custom_minimum_size = Vector2(572.0, 0.0)
    _message.size = Vector2(572.0, 24.0)
    _message_panel.modulate.a = 0.0

    _title = _make_label(self, Vector2(40.0, 110.0), 28)
    _title.custom_minimum_size = Vector2(560.0, 0.0)
    _title.size = Vector2(560.0, 40.0)
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title.modulate.a = 0.0

    var credit := _make_label(self, Vector2(430.0, 344.0), 8)
    credit.text = "Skin do herói: Ozzbit Games"
    credit.modulate = Color(1.0, 1.0, 1.0, 0.45)


func _make_label(parent: Node, pos: Vector2, font_size: int) -> Label:
    var label := Label.new()
    label.position = pos
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color.WHITE)
    label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
    label.add_theme_constant_override("outline_size", 3)
    parent.add_child(label)
    return label


func _make_panel(pos: Vector2, panel_size: Vector2) -> Panel:
    var panel := Panel.new()
    panel.position = pos
    panel.size = panel_size
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.05, 0.05, 0.08, 0.7)
    style.border_color = Color(1.0, 1.0, 1.0, 0.25)
    style.set_border_width_all(1)
    style.set_corner_radius_all(4)
    panel.add_theme_stylebox_override("panel", style)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(panel)
    return panel


## Mostra os controles e, depois de um tempo, deixa a linha quase transparente.
func set_help(text: String) -> void:
    _help.text = text
    _help.modulate.a = 1.0
    if _help_tween and _help_tween.is_valid():
        _help_tween.kill()
    _help_tween = create_tween()
    _help_tween.tween_interval(12.0)
    _help_tween.tween_property(_help, "modulate:a", 0.35, 2.0)


func set_breath(current: int, maximum: int) -> void:
    _bars.breath = current
    _bars.max_breath = maximum
    _bars.queue_redraw()


## Cada objeto/personagem tem seu próprio "dono" de aviso, para não se atropelarem.
## Textos "E: algo" viram "[E] Algo".
func set_prompt_owner(owner_id: String, text: String) -> void:
    _prompts[owner_id] = text
    var shown := ""
    for key in _prompts:
        if str(_prompts[key]) != "":
            shown = str(_prompts[key])
    if shown.begins_with("E: "):
        shown = "[E] " + shown.substr(3, 1).to_upper() + shown.substr(4)
    _prompt.text = shown
    _prompt_panel.visible = shown != ""
    var width := float(shown.length()) * 6.4 + 22.0
    _prompt_panel.size = Vector2(width, 22.0)
    _prompt_panel.position = Vector2(320.0 - width / 2.0, 262.0)


func show_message(text: String, seconds: float) -> void:
    _message.text = text
    var lines := int(ceil(float(text.length()) * 6.4 / 560.0))
    var height := 14.0 * float(maxi(lines, 1)) + 12.0
    _message_panel.size = Vector2(592.0, height)
    _message_panel.position = Vector2(24.0, 338.0 - height)
    _message_panel.modulate.a = 1.0
    if _msg_tween and _msg_tween.is_valid():
        _msg_tween.kill()
    _msg_tween = create_tween()
    _msg_tween.tween_interval(seconds)
    _msg_tween.tween_property(_message_panel, "modulate:a", 0.0, 1.0)


func show_title(text: String, seconds: float) -> void:
    _title.text = text
    _title.modulate.a = 0.0
    if _title_tween and _title_tween.is_valid():
        _title_tween.kill()
    _title_tween = create_tween()
    _title_tween.tween_property(_title, "modulate:a", 1.0, 0.5)
    _title_tween.tween_interval(seconds)
    _title_tween.tween_property(_title, "modulate:a", 0.0, 0.8)


func show_boss(boss_name: String, marks: Array = []) -> void:
    _bars.boss_visible = true
    _bars.boss_fraction = 1.0
    _bars.boss_marks = marks
    _bars.queue_redraw()
    _boss_label.text = boss_name
    _boss_label.visible = true


func set_boss(fraction: float) -> void:
    _bars.boss_fraction = clampf(fraction, 0.0, 1.0)
    _bars.queue_redraw()


func hide_boss() -> void:
    _bars.boss_visible = false
    _bars.queue_redraw()
    _boss_label.visible = false
