extends CharacterBody2D

var moedas_count:int = 0
signal pegou_moeda
signal pegou_cogumelo

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _ready() -> void:
	pegou_moeda.connect(incrementar_contador_moeda)
	pegou_cogumelo.connect(crescer)
	
func crescer():
	var tween:Tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(2,2), 5)

func incrementar_contador_moeda():
	moedas_count += 1
	print(moedas_count)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("atacar") and not event.is_echo():
		print("ataca")
	if event.is_action_pressed("consumir_item") and not event.is_echo():
		print("consome item")
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("mover_esquerda", "mover_direita")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
