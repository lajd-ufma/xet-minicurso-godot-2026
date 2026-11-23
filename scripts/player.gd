
extends CharacterBody2D

var moedas_count: int = 0

signal pegou_moeda
signal pegou_cogumelo

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

@onready var attack_left: CollisionShape2D = $AreaAttack/AttackLeft
@onready var attack_right: CollisionShape2D = $AreaAttack/AttackRight
@onready var area_attack: Area2D = $AreaAttack

var morto: bool = false
var atacando: bool = false
var dano: int = 10
var vida: int
var vida_max: int = 50

const SPEED = 200.0

# Configurações do pulo
const JUMP_VELOCITY = -800
const GRAVITY_MULTIPLIER = 1.5
const JUMP_CUT_MULTIPLIER = 2.0

func _ready() -> void:
	pegou_moeda.connect(incrementar_contador_moeda)
	pegou_cogumelo.connect(crescer)

	attack_left.disabled = true
	attack_right.disabled = true
	
	vida = vida_max
	
	anim.play("idle")


func crescer() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(2, 2), 5)


func incrementar_contador_moeda() -> void:
	moedas_count += 1
	print(moedas_count)


func _input(event: InputEvent) -> void:
	if morto:
		return

	if event.is_action_pressed("atacar") and not event.is_echo() and is_on_floor():
		iniciar_ataque()

	if event.is_action_pressed("consumir_item") and not event.is_echo():
		print("consome item")


func _physics_process(delta: float) -> void:
	if morto:
		return

	var gravidade = get_gravity().y * GRAVITY_MULTIPLIER

	if not is_on_floor():
		velocity.y += gravidade * delta

	# Pulo
	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Pulo variável: soltar o botão reduz o impulso
	if Input.is_action_just_released("pular") and velocity.y < 0:
		velocity.y *= 0.5

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
	anim.play("attack")

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


func atacar() -> void:
	if morto:
		return

	if not sprite.flip_h:
		attack_right.set_deferred("disabled", false)
		attack_left.set_deferred("disabled", true)
	else:
		attack_left.set_deferred("disabled", false)
		attack_right.set_deferred("disabled", true)

	await get_tree().physics_frame
	await get_tree().physics_frame
	
	for body in area_attack.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(dano)


func terminar_ataque() -> void:
	attack_left.set_deferred("disabled", true)
	attack_right.set_deferred("disabled", true)


func take_damage(quantidade: int):
	if morto:
		return

	vida -= quantidade

	if vida <= 0:
		morto = true
		anim.play("death")
		await anim.animation_finished
		queue_free()
		get_tree().quit()
