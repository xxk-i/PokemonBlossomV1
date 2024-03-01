extends Node2D

var next_scene
var player_location
var player_direction


func transition_to_scene(new_scene, location, direction):
	next_scene = new_scene
	player_location = location
	player_direction = direction
	$ScreenTransition/AnimationPlayer.play("fade_to_black")
	
func fade_complete():
	$CurrentScene.get_child(0).queue_free()
	$CurrentScene.add_child(load(next_scene).instantiate())
	var player = $CurrentScene.get_child(1).find_child("Player")
	player.set_spawn(player_location, player_direction)
	
	$ScreenTransition/AnimationPlayer.play("fade_to_normal")
