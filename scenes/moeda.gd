extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		#print("coletou moeda")
		#body.emit_signal("pegou_moeda")
		body.emit_signal("pegou_cogumelo")
		queue_free()
