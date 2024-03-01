extends CharacterBody2D

var speed = 0.25

var party = []

var input_direction = Vector2(0, 1)
var tile_position = Vector2.ZERO

var lock_movement = false

@export var gender = 'F'

enum PlayerState { IDLE, TURNING, WALKING }
enum FacingDirection { LEFT, RIGHT, UP, DOWN }

var player_state = PlayerState.IDLE
var facing_direction = FacingDirection.DOWN

const GRASS_STEP = preload("res://overworld/player/grass_steps.tscn")
const DUST_EFFECT = preload("res://overworld/player/dust_effect.tscn")
const POKEMON_INST = preload("res://pokemon/poke_inst.tscn")

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_state: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback")

@onready var tilemap = $"../TileMap"
@onready var tile_size = tilemap.tile_set.tile_size.x

func _ready():
	# Temporary code for adding starter to player (just popplio for now)
	var starter = POKEMON_INST.instantiate()
	starter.create_poke(load("res://pokemon/resources/popplio.tres"), 5, "Docile")
	party.append(starter)
	
	anim_tree.active = true
	anim_tree.set("parameters/Idle/blend_position", input_direction)
	anim_tree.set("parameters/Walk/blend_position", input_direction)
	anim_tree.set("parameters/Turn/blend_position", input_direction)
	anim_tree.set("parameters/Jump/blend_position", input_direction)
	
	if gender == 'M':
		$AnimatedSprite2D.animation = "Male"
	elif gender == 'F':
		$AnimatedSprite2D.animation = "Female"

func _process(delta):
	if player_state == PlayerState.WALKING or lock_movement:
		return
	
	process_priority_input()
	
	if input_direction != Vector2.ZERO:
		if need_to_turn():
			player_state = PlayerState.TURNING
			anim_state.travel("Turn")
		anim_tree.set("parameters/Idle/blend_position", input_direction)
		anim_tree.set("parameters/Walk/blend_position", input_direction)
		anim_tree.set("parameters/Turn/blend_position", input_direction)
		anim_tree.set("parameters/Jump/blend_position", input_direction)
	
		if player_state == PlayerState.IDLE:
			anim_state.travel("Walk")
			var target_position = position + (tile_size * input_direction)
			if is_ledge_jumpable(target_position):
				target_position += (tile_size * input_direction)
				jump(target_position, speed*2)
			elif is_walkable(target_position):
				move(target_position, speed)
	else:
		if player_state == PlayerState.IDLE:
			anim_state.travel("Idle")

func process_priority_input():
	if input_direction.y == 0:
		input_direction.x = int(Input.is_action_pressed("move_east")) - int(Input.is_action_pressed("move_west"))
	if input_direction.x == 0:
		input_direction.y = int(Input.is_action_pressed("move_south")) - int(Input.is_action_pressed("move_north"))

func need_to_turn():
	var new_facing_direction
	if input_direction.x < 0:
		new_facing_direction = FacingDirection.LEFT
	elif input_direction.x > 0:
		new_facing_direction = FacingDirection.RIGHT
	elif input_direction.y < 0:
		new_facing_direction = FacingDirection.UP
	elif input_direction.y > 0:
		new_facing_direction = FacingDirection.DOWN
		
	if facing_direction != new_facing_direction:
		facing_direction = new_facing_direction
		return true
	facing_direction = new_facing_direction
	return false

#called by the final frame of the turning animation
func finished_turning():
	player_state = PlayerState.IDLE

func move(destination, delta):
	var start_position = position
	if await tile_action_exited(start_position, destination):
		await(execute_walk(destination, delta))
		tile_action_entered(start_position, destination)

func tile_action_entered(start_position, tile_position):
	var atlas_position = tilemap.local_to_map(tile_position)
	var atlas_start = tilemap.local_to_map(start_position)
	if tilemap.get_cell_atlas_coords(1, atlas_position) == Vector2i(7, 0):
		$Shadow.visible = false
		tilemap.set_cell(2, atlas_position, tilemap.get_cell_source_id(1, atlas_position, false), Vector2i(8,0), 0)
		var grass_step_inst = GRASS_STEP.instantiate()
		grass_step_inst.position = tile_position
		get_tree().current_scene.add_child(grass_step_inst)
	if tilemap.get_cell_atlas_coords(1, atlas_start) == Vector2i(7, 0) and facing_direction != FacingDirection.DOWN:
		tilemap.erase_cell(2, atlas_start)

func tile_action_exited(tile_position, destination):
	var atlas_position = tilemap.local_to_map(tile_position)
	var atlas_destination = tilemap.local_to_map(destination)
	#tall grass remove covering layer
	if tilemap.get_cell_atlas_coords(1, atlas_position) == Vector2i(7, 0):
		if facing_direction == FacingDirection.DOWN:
			tilemap.erase_cell(2, atlas_position)
		if tilemap.get_cell_atlas_coords(1, atlas_destination) != Vector2i(7, 0):
			$Shadow.visible = true
	#open door, have player walk through, and close door behind, then transition to desired scene
	elif facing_direction == FacingDirection.UP and (tilemap.get_cell_atlas_coords(1, atlas_destination) == Vector2i(10,6) or tilemap.get_cell_atlas_coords(2, atlas_destination) == Vector2i(10,6) or tilemap.get_cell_atlas_coords(3, atlas_destination) == Vector2i(10,6)):
		for i in $"../Doors".get_child_count():
			var door = $"../Doors".get_child(i)
			if door.position == destination:
				door.play("default", 1.5, false)
				await(execute_walk(destination + tile_size * Vector2(0, -2), speed*3))
				door.play_backwards("default")
				get_tree().get_root().get_child(0).transition_to_scene(door.next_scene_path, door.spawn_location, door.spawn_direction)
				lock_movement = true
				return false
	elif facing_direction == FacingDirection.DOWN and tilemap.get_cell_atlas_coords(1, atlas_destination) == Vector2i(22,1):
		for i in $"../Doors".get_child_count():
			var door = $"../Doors".get_child(i)
			if tilemap.local_to_map(door.position) == atlas_destination:
				get_tree().get_root().get_child(0).transition_to_scene(door.next_scene_path, door.spawn_location, door.spawn_direction)
				lock_movement = true
	return true

func is_walkable(target_position):
	var result = true
	for i in tilemap.get_layers_count():
		var tile = tilemap.get_cell_tile_data(i, tilemap.local_to_map(target_position))
		if tile and tile.get_collision_polygons_count(0) == 1:
			result = false
	return result

func is_ledge_jumpable(target_position):
	var target_tile_coords = tilemap.get_cell_atlas_coords(1, tilemap.local_to_map(target_position))
	if facing_direction == FacingDirection.DOWN and (target_tile_coords == Vector2i(0,3) or target_tile_coords == Vector2i(1,3) or target_tile_coords == Vector2i(2,3)):
		return true
	elif facing_direction == FacingDirection.RIGHT and (target_tile_coords == Vector2i(1,4) or target_tile_coords == Vector2i(1,5) or target_tile_coords == Vector2i(1,6)):
		return true
	elif facing_direction == FacingDirection.LEFT and (target_tile_coords == Vector2i(0,4) or target_tile_coords == Vector2i(0,5) or target_tile_coords == Vector2i(0,6)):
		return true
	else:
		return false

func jump(destination, delta):
	if facing_direction != FacingDirection.UP:
		anim_state.travel("Jump")
		await move(destination, delta)
		var dust_effect_inst = DUST_EFFECT.instantiate()
		dust_effect_inst.position = position
		get_tree().current_scene.add_child(dust_effect_inst)
		player_state = PlayerState.IDLE 

func execute_walk(destination, delta):
	player_state = PlayerState.WALKING
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", destination, delta)
	await tween.finished
	player_state = PlayerState.IDLE 

func set_spawn(location, direction):
	anim_tree.set("parameters/Idle/blend_position", direction)
	anim_tree.set("parameters/Walk/blend_position", direction)
	anim_tree.set("parameters/Turn/blend_position", direction)
	anim_tree.set("parameters/Jump/blend_position", direction)
	position = location
