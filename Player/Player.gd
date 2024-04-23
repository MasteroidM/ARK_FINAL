extends KinematicBody2D

enum{
	punch,
	kick,
	knockback,
	block,
	idle
}

onready var animationplayer = $NetworkAnimationPlayer
onready var stats = $HealthUI/PlayerStats


var STATE = idle
var NAME = "p1_"


func _get_local_input() -> Dictionary:
	var input_vector = Input.get_vector(NAME+"move_left", NAME+"move_right", "ui_up", "ui_down")
	if Input.is_action_just_pressed(NAME+"kick"):
		STATE = kick
	elif Input.is_action_just_pressed(NAME+"punch"):
		STATE = punch
	elif Input.is_action_just_pressed(NAME+"block"):
		STATE = block
	
	var input := {}
	if input_vector != Vector2.ZERO:
		input["input_vector"] = input_vector.x
	input["state"] = STATE
	
	return input

func _network_process(input: Dictionary) -> void:
	match input.get("state"):
		kick:
			kick()
		punch:
			punch()
		idle:
			idle()
		block:
			block()
	move_and_collide(Vector2(input.get("input_vector",0),0)*8)
	#position.x += input.get("input_vector",0) * 8
	


func _save_state() -> Dictionary:
	return {
		position = position
		
	}

func _load_state(state: Dictionary) -> void:
	position = state['position']
	


func kick():
	animationplayer.play("kick")
	

func punch():
	animationplayer.play("punch")
	
func block():
	animationplayer.play("block")
	

func idle():
	animationplayer.play("idle")


func _on_NetworkAnimationPlayer_animation_finished(anim_name):
	STATE = idle


func _on_hitbox_area_entered(area):
	if (area.get_parent() == self):
		return
	else:
		if (area != self):
			stats.health -=1 
