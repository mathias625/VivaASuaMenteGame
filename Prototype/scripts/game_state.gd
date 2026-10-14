extends Node
## Estado global do jogo (autoload "GameState").
## Guarda o progresso do Wander: habilidades, laços, ações e checkpoint.

signal stage_changed(new_stage: int)
signal bonds_changed(count: int)

const QUEST_NONE := 0
const QUEST_ACTIVE := 1
const QUEST_DONE := 2
const NOTES_TOTAL := 5

var input_locked := false          # true durante diálogos e cenas
var checkpoint := Vector2(-480.0, 384.0)

var stage := 1                     # estágio de evolução do Wander (1 a 6)
var bonds := 0                     # amigos feitos (Murmúrios acolhidos)
var notes := 0                     # bilhetes dos moradores encontrados
var warmth := 0.0                  # só alimenta a música; nunca aparece como "barra"
var has_seed := false
var quest := QUEST_NONE
var tarsila_stage := 0             # 0 não conheceu, 1 conheceu, 2 abriu o coração, 3 abraço
var mel_stage := 0                 # 0 ainda não elogiado o cabelo, 1 elogiou
var cat_stage := 0                 # 0 arisco, 2 confiou no Wander
var boss_defeated := false         # Eco da Insônia
var boss2_defeated := false        # Eco da Solidão

# Pequenas ações do cotidiano (todas opcionais)
var curtain_open := false
var desk_tidied := false
var memory_found := false
var lookout_done := false
var has_hat := false
var hat_returned := false

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
