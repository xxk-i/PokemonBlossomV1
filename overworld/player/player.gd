extends CharacterBody2D

var speed = 5

var initial_position = Vector2(0,0)
var input_direction = Vector2(0,0)
var percent_to_tile = 0.0

var gender = 'F'

enum PlayerState { IDLE, TURNING, WALKING }
enum FacingDirection { LEFT, RIGHT, UP, DOWN }

var player_state = PlayerState.IDLE
var facing_direction = FacingDirection.DOWN

@export_group("Level Info")
@export var tile_map: TileMap
@export var starting_tile: Vector2

@onready var anim_tree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")
@onready var TILE_SIZE = tile_map.tile_set.tile_size.x

func _ready():
	position = position.snapped(Vector2.ONE * TILE_SIZE)
	position += Vector2.ONE * TILE_SIZE/2
	
	anim_tree.active = true
	
	if gender == 'M':
		$AnimatedSprite2D.animation = "Male"
	elif gender == 'F':
		$AnimatedSprite2D.animation = "Female"

func _process(delta):
	if player_state == PlayerState.WALKING:
		return
		
	process_priority_input()
	
	if input_direction != Vector2.ZERO:
		if need_to_turn():
			player_state = PlayerState.TURNING
			anim_state.travel("Turn")
		anim_tree.set("parameters/Idle/blend_position", input_direction)
		anim_tree.set("parameters/Walk/blend_position", input_direction)
		anim_tree.set("parameters/Turn/blend_position", input_direction)
		
		if player_state == PlayerState.IDLE:
			anim_state.travel("Walk")
			move()
	
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

func finished_turning():
	player_state = PlayerState.IDLE
		
func move():
	player_state = PlayerState.WALKING
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", position + (TILE_SIZE * input_direction), 0.35)
	await tween.finished
	player_state = PlayerState.IDLE 
