extends Sprite2D

@onready var player: Node2D = get_tree().get_first_node_in_group("Player")

@export_group("Sprites")
@export var vida_5_5: Texture2D
@export var vida_4_5: Texture2D
@export var vida_3_5: Texture2D
@export var vida_2_5: Texture2D
@export var vida_1_5: Texture2D
@export var vida_0_5: Texture2D

var vida_mostrada: int = -1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	centered = false
	position = Vector2(0,0)
	atualizar_barra()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	atualizar_barra()

func atualizar_barra():
	if not is_instance_valid(player):
		return
	var vida_atual = int(player.get("vida"))
	var vida_maxima = int(player.get("vida_max"))
	
	if vida_maxima <= 0:
		return
	var nivel = clampi(ceili(float(vida_atual)/vida_maxima * 5.0), 0, 5)
	if nivel == vida_mostrada:
		return
	vida_mostrada = nivel
	match nivel:
		5:
			texture = vida_5_5
		4:
			texture = vida_4_5
		3:
			texture = vida_3_5
		2:
			texture = vida_2_5
		1:
			texture = vida_1_5
		0:
			texture = vida_0_5
		
