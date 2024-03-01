extends Control

@export var grid: GridContainer
@export var cursor: TextureRect

var isConfirmed := false

var selected := 0:
	get:
		return selected
	set(value):
		selected = value
		update_cursor_position()

# Called when the node enters the scene tree for the first time.
func _ready():
	update_cursor_position()

func _input(event):
	if isConfirmed:
		if event.is_action_pressed("pause"):
			isConfirmed = false
		
		else:
			return
			
	if event.is_action_pressed("confirm"):
		isConfirmed = true
	
	if event.is_action_pressed("move_east"):
		if selected != grid.get_child_count() - 1:
			selected += 1
	
	elif event.is_action_pressed("move_west"):
		if selected != 0:
			selected -= 1
			
	elif event.is_action_pressed("move_north"):
		if selected >= grid.columns:
			selected -= grid.columns
		
		else:
			selected = grid.get_child_count() - grid.columns + selected
	
	elif event.is_action_pressed("move_south"):
		if selected + grid.columns <= grid.get_child_count() - 1:
			selected += grid.columns
		
		# Wrap vertically
		else:
			selected = selected % grid.columns

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func update_cursor_position():
	var first_item: Label = grid.get_children()[selected]
	var setpos = first_item.global_position
	cursor.global_position.x = setpos.x - cursor.size.x
	cursor.global_position.y = setpos.y
