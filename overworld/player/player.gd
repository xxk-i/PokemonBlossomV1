extends CharacterBody2D

const TILE_SIZE = 16
var speed = 5
var jump_speed = 5

var jumping_over_ledge: bool = false

var initial_position = Vector2(0,0)
var input_direction = Vector2(0,0)
var percent_to_tile = 0.0

var gender = 'M'

enum PlayerState { IDLE, TURNING, WALKING, JUMP }
enum FacingDirection { LEFT, RIGHT, UP, DOWN }

var player_state = PlayerState.IDLE
var facing_direction = FacingDirection.DOWN

const GRASS_STEP = preload("res://overworld/player/grass_steps.tscn")

@onready var anim_tree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")
@onready var collision_ray = $RayCast2D
@onready var ledge_ray = $LedgeRayCast2D

func _ready():
	position = position.snapped(Vector2.ONE * TILE_SIZE)
	position += Vector2.ONE * TILE_SIZE/2
	
	anim_tree.active = true
	
	if gender == 'M':
		$AnimatedSprite2D.animation = "Male"
	elif gender == 'F':
		$AnimatedSprite2D.animation = "Female"

func _physics_process(delta):
	match player_state:
		PlayerState.TURNING:
			return
		PlayerState.IDLE:
			process_priority_input()
		PlayerState.WALKING:
			if input_direction != Vector2.ZERO:
				anim_state.travel("Walk")
				move(delta)
				
			else:
				anim_state.travel("Idle")
				player_state = PlayerState.IDLE
		PlayerState.JUMP:
			jump(delta)
	
	move_and_slide()

func process_priority_input():
	if input_direction.y == 0:
		input_direction.x = int(Input.is_action_pressed("move_east")) - int(Input.is_action_pressed("move_west"))
	if input_direction.x == 0:
		input_direction.y = int(Input.is_action_pressed("move_south")) - int(Input.is_action_pressed("move_north"))
	
	if input_direction != Vector2.ZERO:
		anim_tree.set("parameters/Idle/blend_position", input_direction)
		anim_tree.set("parameters/Walk/blend_position", input_direction)
		anim_tree.set("parameters/Turn/blend_position", input_direction)
		
		if need_to_turn():
			player_state = PlayerState.TURNING
			anim_state.travel("Turn")
		else:
			player_state = PlayerState.WALKING
			initial_position = position
			
	else:
		player_state = PlayerState.IDLE
		anim_state.travel("Idle")

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

func finished_turning():
	player_state = PlayerState.IDLE

func move(delta):
	var desired_step: Vector2 = input_direction * TILE_SIZE/2
	collision_ray.target_position = desired_step
	collision_ray.force_raycast_update()
	
	ledge_ray.target_position = desired_step
	ledge_ray.force_raycast_update()
	
	if (ledge_ray.is_colliding() and input_direction == Vector2(0,1)):
		player_state = PlayerState.JUMP
	elif (ledge_ray.is_colliding()):
		percent_to_tile = 0.0
		player_state = PlayerState.IDLE
	elif !collision_ray.is_colliding():
		percent_to_tile += speed * delta
		if percent_to_tile >= 1.0:
			position = initial_position + (TILE_SIZE * input_direction)
			percent_to_tile = 0.0
			player_state = PlayerState.IDLE
		else:
			position = initial_position + (TILE_SIZE * input_direction * percent_to_tile)
	else:
		percent_to_tile = 0.0
		player_state = PlayerState.IDLE

var tile_position

func jump(delta):
	percent_to_tile += jump_speed * delta
	if percent_to_tile >= 2.0:
		position = initial_position + (input_direction * TILE_SIZE * 2)
		percent_to_tile = 0.0
		jumping_over_ledge = false
		player_state = PlayerState.IDLE
	else:
		var input = input_direction.y * TILE_SIZE * percent_to_tile
		position.y = initial_position.y + (-0.96 - 0.53 * input + 0.05 * pow(input, 2))

func _on_area_2d_body_entered(body):
	if body is TileMap:
		tile_position = body.local_to_map(position)
		#Check if player is standing in grass
		if body.get_cell_atlas_coords(1, tile_position) == Vector2i(7,0):
			$Shadow.visible = false
			body.set_cell(2, tile_position, body.get_cell_source_id(1, tile_position, false), Vector2i(8,0), 0)
			var grass_step_inst = GRASS_STEP.instantiate()
			grass_step_inst.position = body.map_to_local(tile_position)
			get_tree().current_scene.add_child(grass_step_inst)


func _on_area_2d_body_exited(body):
	if body is TileMap:
		$Shadow.visible = true
		body.erase_cell(2, tile_position)

