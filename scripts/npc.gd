extends CharacterBody2D

var ja_dialogou := false

func _ready() -> void:
	Dialogic.signal_event.connect(_on_signal_event)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	
	
func _on_timeline_ended():
	print("cabou a primeira")
func _on_signal_event(signal_name):
	
	var tween :Tween = get_tree().create_tween()
	
	match signal_name:
		
		"ficar_vermelho":
			tween.tween_property(self, "modulate", Color.RED, 1)
		"ficar_verde":
			tween.tween_property(self, "modulate", Color.GREEN, 1)
		"ficar_azul":
			tween.tween_property(self, "modulate", Color.BLUE, 1)
		
		_:
			print("naoi foi atribuida cor")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()


func _on_area_dialogo_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not ja_dialogou:
		ja_dialogou = true
		Dialogic.start("timeline_test")
