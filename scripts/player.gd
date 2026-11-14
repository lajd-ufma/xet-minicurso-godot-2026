extends CharacterBody2D

var moedas_count:int = 0
signal pegou_moeda
signal pegou_cogumelo

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

var morto: bool = false
var atacando: bool = false

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _ready() -> void:
	pegou_moeda.connect(incrementar_contador_moeda)
	pegou_cogumelo.connect(crescer)
	anim.play("idle")

func crescer():
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(2, 2), 5)

func incrementar_contador_moeda():
	moedas_count += 1
	print(moedas_count)

func _input(event: InputEvent) -> void:
	if morto: 
		return
	if event.is_action_pressed("atacar") and not event.is_echo():
		iniciar_ataque()
		print("ataca")
	if event.is_action_pressed("consumir_item") and not event.is_echo():
		print("consome item")
func _physics_process(delta: float) -> void:
	if morto: 
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("mover_esquerda", "mover_direita")
	
	if atacando:
		velocity.x = 0
	else:
		if direction:
			velocity.x = direction * SPEED
			sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	if not atacando:
		if abs(velocity.x) > 1:
			tocar_animacao("walk")
		else:
			tocar_animacao("idle")

func tocar_animacao(nome: String) -> void:
	if anim.current_animation != nome:
		anim.play(nome)
		

func iniciar_ataque() -> void:
	if morto or atacando:
		return
	
	atacando = true
	anim.play("atack")
	await anim.animation_finished
	atacando = false
		

func morrer() -> void:
	if morto:
		return
	
	morto = true
	velocity.x = 0
	anim.play("death")
	await anim.animation_finished
	
	queue_free()
