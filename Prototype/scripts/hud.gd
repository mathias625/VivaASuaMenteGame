extends CanvasLayer
## Interface: Fôlego, laços, mensagens, objetivo e barra do chefe.


class Bars extends Control:
    var breath := 4
    var max_breath := 4
    var boss_visible := false
    var boss_fraction := 1.0

    func _draw() -> void:
        for i in range(max_breath):
            var color := Color(1.0, 0.85, 0.3) if i < breath else Color(0.25, 0.25, 0.3, 0.9)
            draw_circle(Vector2(20.0 + float(i) * 16.0, 44.0), 5.5, color)
        if boss_visible:
            draw_rect(Rect2(170.0, 14.0, 300.0, 10.0), Color(0.0, 0.0, 0.0, 0.6))
            draw_rect(Rect2(172.0, 16.0, 296.0 * boss_fraction, 6.0), Color(0.75, 0.7, 1.0))


var _bars: Bars
var _help: Label
var _breath_label: Label
var _bonds: Label
var _quest: Label
var _message: Label
var _prompt: Label
var _boss_label: Label
var _tween: Tween


func _ready() -> void:
    layer = 1
    _bars = Bars.new()
    _bars.size = Vector2(640.0, 360.0)
    _bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_bars)

    _help = _make_label(Vector2(12.0, 6.0), 10)
    _breath_label = _make_label(Vector2(12.0, 22.0), 10)
    _breath_label.text = "Fôlego"
    _bonds = _make_label(Vector2(12.0, 56.0), 11)
    _bonds.visible = false
    _quest = _make_label(Vector2(12.0, 72.0), 11)
    _prompt = _make_label(Vector2(12.0, 280.0), 12)
    _boss_label = _make_label(Vector2(170.0, 26.0), 11)
    _boss_label.visible = false
    _message = _make_label(Vector2(12.0, 300.0), 12)
    _message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _message.custom_minimum_size = Vector2(616.0, 0.0)
    _message.size = Vector2(616.0, 40.0)
    _message.modulate.a = 0.0


func _make_label(pos: Vector2, font_size: int) -> Label:
    var label := Label.new()
    label.position = pos
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color.WHITE)
    label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
    label.add_theme_constant_override("outline_size", 3)
    add_child(label)
    return label


func set_help(text: String) -> void:
    _help.text = text


func set_breath(current: int, maximum: int) -> void:
    _bars.breath = current
    _bars.max_breath = maximum
    _bars.queue_redraw()


func set_bonds(count: int) -> void:
    _bonds.visible = true
    _bonds.text = "Laços: %d/%d" % [count, GameState.QUEST_GOAL]


func set_quest_text(text: String) -> void:
    _quest.text = text


func set_prompt(text: String) -> void:
    _prompt.text = text


func show_message(text: String, seconds: float) -> void:
    _message.text = text
    _message.modulate.a = 1.0
    if _tween and _tween.is_valid():
        _tween.kill()
    _tween = create_tween()
    _tween.tween_interval(seconds)
    _tween.tween_property(_message, "modulate:a", 0.0, 1.0)


func show_boss(boss_name: String) -> void:
    _bars.boss_visible = true
    _bars.boss_fraction = 1.0
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
