extends Node
## Estado global do jogo (autoload "GameState").
## Guarda o progresso do Wander: habilidades, laços, missão e checkpoint.

signal stage_changed(new_stage: int)
signal bonds_changed(count: int)

const QUEST_NONE := 0
const QUEST_ACTIVE := 1
const QUEST_DONE := 2
const QUEST_GOAL := 3

var input_locked := false          # true durante diálogos
var checkpoint := Vector2(0.0, 388.0)

var stage := 1                     # estágio de evolução do Wander (1 a 5)
var bonds := 0                     # amigos feitos (Murmúrios acolhidos)
var has_seed := false
var quest := QUEST_NONE
var boss_defeated := false

# Habilidades liberadas pela história
var can_love := false              # Acolher (J)
var can_dash := false              # Esquiva (K)
var can_rest := false              # Descansar (segurar S)


func max_breath() -> int:
    # Cada amigo faz companhia e dá mais um ponto de Fôlego.
    return 4 + bonds


func set_stage(value: int) -> void:
    if value > stage:
        stage = value
        stage_changed.emit(stage)


func add_bond() -> void:
    bonds += 1
    bonds_changed.emit(bonds)
