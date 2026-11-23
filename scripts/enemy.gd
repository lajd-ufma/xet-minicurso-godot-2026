
extends CharacterBody2D

@export_group("Movimentação")
@export var velocidade_patrulha: float = 45.0
@export var velocidade_perseguicao: float = 90.0

@export var tempo_andando: float = 2.0
@export var tempo_parado: float = 1.0

@export var gravidade: float = 980.0

@export var distancia_borda: float = 18.0

@export_group("Combate")
@export var vida_maxima: int = 30
@export var dano_ataque: int = 10

@export var distancia_ataque: float = 75.0
@export var intervalo_ataque: float = 1.2

@export_group("Barra de Vida")
@export var deslocamento_barra: Vector2 = Vector2(-10, -50)
@export var tamanho_barra: Vector2 = Vector2(100, 0.5)

@export_group("Atordoamento")
@export var duracao_stun: float = 1.0

enum Estado {
	PATRULHA,
	PERSEGUINDO,
	ATACANDO,
	STUNNED,
	MORTO
}

var estado: Estado = Estado.PATRULHA

var vida: int

var jogador: Node2D = null

var direcao: float = 1.0

var andando: bool = true
var tempo_patrulha: float = 0.0

var cooldown_ataque: float = 0.0
var tempo_stun: float = 0.0

var posicao_inicial_visao: Vector2
var posicao_inicial_colisao_visao: Vector2

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area_visao: Area2D = $VissionArea
@onready var colisao_visao: CollisionShape2D = $VissionArea/CollisionShape2D
@onready var edge_detector: RayCast2D = $EdgeDetector
@onready var attack_area: Area2D = $AttackArea

@onready var attack_right: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_left: CollisionShape2D = $AttackArea/CollisionShape2D2
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var barra_vida: ProgressBar = $BarraVida


func _ready() -> void:
	vida = vida_maxima
	tempo_patrulha = tempo_andando

	posicao_inicial_visao = area_visao.position
	posicao_inicial_colisao_visao = colisao_visao.position

	barra_vida.position = deslocamento_barra
	barra_vida.size = tamanho_barra
	barra_vida.min_value = 0
	barra_vida.max_value = vida_maxima
	barra_vida.value = vida
	barra_vida.show_percentage = false
	barra_vida.visible = false
	barra_vida.mouse_filter = Control.MOUSE_FILTER_IGNORE

	area_visao.body_entered.connect(_on_vision_body_entered)
	area_visao.body_exited.connect(_on_vision_body_exited)

	anim.animation_finished.connect(_on_animation_finished)

	attack_right.disabled = true
	attack_left.disabled = true

	atualizar_direcao_sprite()
	tocar_animacao("idle")


func _physics_process(delta: float) -> void:
	if estado == Estado.MORTO:
		return

	if not is_on_floor():
		velocity.y += gravidade * delta

	if cooldown_ataque > 0:
		cooldown_ataque -= delta

	if estado == Estado.STUNNED:
		velocity.x = 0
		tempo_stun -= delta

		if tempo_stun <= 0:
			if is_instance_valid(jogador):
				estado = Estado.PERSEGUINDO
			else:
				estado = Estado.PATRULHA
				andando = true
				tempo_patrulha = tempo_andando

			tocar_animacao("idle")

		move_and_slide()
		return

	match estado:
		Estado.PATRULHA:
			patrulhar(delta)

		Estado.PERSEGUINDO:
			perseguir()

		Estado.ATACANDO:
			velocity.x = 0

	move_and_slide()


func _on_vision_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		jogador = body

		if estado != Estado.MORTO and estado != Estado.ATACANDO and estado != Estado.STUNNED:
			estado = Estado.PERSEGUINDO


func _on_vision_body_exited(body: Node2D) -> void:
	if body == jogador:
		jogador = null

		if estado != Estado.MORTO and estado != Estado.ATACANDO and estado != Estado.STUNNED:
			estado = Estado.PATRULHA
			andando = true
			tempo_patrulha = tempo_andando


func _on_animation_finished(nome_animacao: StringName) -> void:
	if nome_animacao == &"attack":
		if estado == Estado.ATACANDO:
			if is_instance_valid(jogador):
				estado = Estado.PERSEGUINDO
			else:
				estado = Estado.PATRULHA
				andando = true
				tempo_patrulha = tempo_andando

	elif nome_animacao == &"death" and estado == Estado.MORTO:
		queue_free()


func atualizar_direcao_sprite() -> void:
	if direcao == 0:
		return

	var sentido = signf(direcao)

	sprite.flip_h = sentido < 0

	area_visao.position.x = posicao_inicial_visao.x * sentido
	colisao_visao.position.x = posicao_inicial_colisao_visao.x * sentido


func tocar_animacao(nome: String) -> void:
	if anim.current_animation != nome:
		anim.play(nome)


func patrulhar(delta: float) -> void:
	if andando:
		var existe_chao = tem_chao_a_frente()

		if is_on_wall() or not existe_chao:
			andando = false
			tempo_patrulha = tempo_parado
			velocity.x = 0
			tocar_animacao("idle")
			return

		velocity.x = direcao * velocidade_patrulha
		tempo_patrulha -= delta

		tocar_animacao("walk")
		atualizar_direcao_sprite()

		if tempo_patrulha <= 0:
			andando = false
			velocity.x = 0
			tempo_patrulha = tempo_parado
			tocar_animacao("idle")

	else:
		velocity.x = 0
		tempo_patrulha -= delta

		tocar_animacao("idle")

		if tempo_patrulha <= 0:
			direcao *= -1
			andando = true
			tempo_patrulha = tempo_andando
			atualizar_direcao_sprite()


func tem_chao_a_frente() -> bool:
	edge_detector.position.x = distancia_borda * direcao
	edge_detector.force_raycast_update()
	return edge_detector.is_colliding()


func perseguir() -> void:
	if not is_instance_valid(jogador):
		jogador = null
		estado = Estado.PATRULHA
		andando = true
		tempo_patrulha = tempo_andando
		return

	var diferenca = jogador.global_position.x - global_position.x
	var distancia = global_position.distance_to(jogador.global_position)

	if distancia <= distancia_ataque:
		velocity.x = 0

		if not is_zero_approx(diferenca):
			direcao = signf(diferenca)

		atualizar_direcao_sprite()

		if cooldown_ataque <= 0:
			iniciar_ataque()
		else:
			tocar_animacao("idle")

		return

	if not is_zero_approx(diferenca):
		direcao = signf(diferenca)

	velocity.x = direcao * velocidade_perseguicao

	atualizar_direcao_sprite()
	tocar_animacao("walk")


func iniciar_ataque() -> void:
	estado = Estado.ATACANDO
	velocity.x = 0
	cooldown_ataque = intervalo_ataque
	tocar_animacao("attack")


func atacar() -> void:
	if estado != Estado.ATACANDO:
		return

	if not sprite.flip_h:
		attack_right.set_deferred("disabled", false)
		attack_left.set_deferred("disabled", true)
	else:
		attack_left.set_deferred("disabled", false)
		attack_right.set_deferred("disabled", true)

	await get_tree().physics_frame
	await get_tree().physics_frame

	if estado != Estado.ATACANDO:
		return

	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("Player"):
			if body.has_method("take_damage"):
				body.take_damage(dano_ataque)


func terminar_ataque() -> void:
	attack_left.set_deferred("disabled", true)
	attack_right.set_deferred("disabled", true)


func take_damage(quantidade: int) -> void:
	if estado == Estado.MORTO:
		return

	vida = maxi(vida - quantidade, 0)

	barra_vida.value = vida
	barra_vida.visible = true

	if vida <= 0:
		morrer()
		return

	estado = Estado.STUNNED
	tempo_stun = duracao_stun
	velocity.x = 0

	attack_right.set_deferred("disabled", true)
	attack_left.set_deferred("disabled", true)

	tocar_animacao("idle")


func morrer() -> void:
	if estado == Estado.MORTO:
		return

	estado = Estado.MORTO
	velocity = Vector2.ZERO

	collision_shape_2d.set_deferred("disabled", true)
	area_visao.set_deferred("monitoring", false)

	attack_right.set_deferred("disabled", true)
	attack_left.set_deferred("disabled", true)

	tocar_animacao("death")
