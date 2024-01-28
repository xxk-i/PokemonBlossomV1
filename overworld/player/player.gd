extends CharacterBody2D

# Time it takes to walk to next tile
var speed = 0.35

var initial_position = Vector2(0,0)
var input_direction = Vector2(0,0)

var gender = 'F'

enum PlayerState { IDLE, TURNING, WALKING }
enum FacingDirection { LEFT, RIGHT, UP, DOWN }

var player_state = PlayerState.IDLE
var facing_direction = FacingDirection.DOWN

@export_group("Level Info")
@export var tile_map: TileMap
@export var starting_tile: Vector2

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_state: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback")
@onready var TILE_SIZE = tile_map.tile_set.tile_size.x

func _ready():
	position = position.snapped(Vector2.ONE * TILE_SIZE)
	position += Vector2.ONE * TILE_SIZE/2
	
	anim_tree.active = true
	
	if gender == 'M':
		$AnimatedSprite2D.animation = "Male"
	elif gender == 'F':
		$AnimatedSprite2D.animation = "Female"

# NOTE: Changed from _physics_process since we manage
# our own collision now. See explanation in PR
func _process(delta):
	# If we are busy (see note above move()), wait and do not process
	if player_state == PlayerState.WALKING || player_state == PlayerState.TURNING:
		return
	
	# We are not busy, let's check for input
	update_input_direction() # Note: this used to be process_priority_input
	
	# If there is no input and we are IDLE, set the animation
	# This isn't done at the end of move() so that if we hold
	# a walking direction we do not Idle in between movements
	#
	# ^ look at that consistent width comment shoooooooooowee
	if input_direction == Vector2.ZERO:
		if player_state == PlayerState.IDLE:
			anim_state.travel("Idle")
	
	# We are not busy (idle) and ready to process the input
	else:
		# NOTE: need_to_turn sets FacingDirection
		if need_to_turn():
			player_state = PlayerState.TURNING
			anim_state.travel("Turn")
			# I moved this line because it doesn't seem to need to be set
			# unless we are turning
			anim_tree.set("parameters/Turn/blend_position", input_direction)
		
		# AnimationTree magic, I do not have the know-how about them to
		# actually validate this is any way. Looks great to me!
		anim_tree.set("parameters/Idle/blend_position", input_direction)
		anim_tree.set("parameters/Walk/blend_position", input_direction)

		# If we are currently idle but have an input direction, do the move!
		if player_state == PlayerState.IDLE:
			# NOTE: this is probably where collision checking should go
			# e.g. canWalkToTile(position_to_tile(position.x/y +/- TILE_SIZE))
			anim_state.travel("Walk")
			move()

func update_input_direction():
	if input_direction.y == 0:
		input_direction.x = int(Input.is_action_pressed("move_east")) - int(Input.is_action_pressed("move_west"))
	if input_direction.x == 0:
		input_direction.y = int(Input.is_action_pressed("move_south")) - int(Input.is_action_pressed("move_north"))

# There are probably more "clever" ways of
# writing this function but it __really__
# does NOT matter, its performance is 100%
# negligible
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
	else:
		return false

# NOTE: this is called by $AnimationPlayer at the
# end of Turn__ animations. Neat trick! Wish Godot
# actually told us though -- it's not even in stack frames!!
func finished_turning():
	player_state = PlayerState.IDLE

# Pretty straight forward, we "lock" our character by setting
# our state to WALKING, then we await for the tween to finish.
# Finally, we "unlock" our character by setting them back to IDLE
#
# NOTE: the "lock" is enforced by _process based on player_state.
# I'd suggest adding a helper isBusy() function that checks if
# we are busy ("locked") by checking our state, e.g.
# PlayerState.WALKING, PlayerState.INTERACTING, PlayerState.TALKING
func move():
	player_state = PlayerState.WALKING
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", position + (TILE_SIZE * input_direction), speed)
	await tween.finished
	player_state = PlayerState.IDLE 
