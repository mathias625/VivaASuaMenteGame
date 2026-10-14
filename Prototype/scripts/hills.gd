extends Node2D
## Colinas distantes, desenhadas em colunas (visual "pixelado").
## Uma única passada de desenho: não pesa no jogo.

var base_y := 300.0
var amp := 30.0
var phase := 0.0
var color := Color(0.5, 0.6, 0.65)
var x_from := -900.0
var x_to := 4200.0


func _ready() -> void:
    queue_redraw()


func _draw() -> void:
    var x := x_from
    while x < x_to:
        var h := base_y + sin(x * 0.004 + phase) * amp + sin(x * 0.011 + phase * 2.0) * amp * 0.4
        h = floorf(h / 4.0) * 4.0
        draw_rect(Rect2(x, h, 6.0, 700.0 - h), color)
        x += 6.0
