@icon("res://ui/cursor_hand.png")
class_name GridCursor
extends GridContainer

signal selection_changed
signal selection_confirmed(index)

@export var cursor: TextureRect
@export var cursor_offset: int

var isConfirmed := false:
	set(index):
		isConfirmed = index
		if index:
			selection_confirmed.emit(selected)

var selected := 0:
	set(index):
		# put currently selected back in position
		get_children()[selected].add_theme_constant_override("margin_left", 0)
		
		# do the actual setting
		selected = index
		var selected: MarginContainer = get_children()[index]
		selected.add_theme_constant_override("margin_left", -40)
		update_cursor_position()
		selection_changed.emit(index)


# Called when the node enters the scene tree for the first time.
func _ready():
	# Selected is already 0, but by doing set again we run
	# the UI setup code
	selected = 0

func _input(event):
	if isConfirmed:
		if event.is_action_pressed("pause"):
			isConfirmed = false
		else:
			return
			
	if event.is_action_pressed("confirm"):
		isConfirmed = true
	
	if event.is_action_pressed("move_east"):
		if selected != get_child_count() - 1:
			selected += 1
	
	elif event.is_action_pressed("move_west"):
		if selected != 0:
			selected -= 1
			
	elif event.is_action_pressed("move_north"):
		if selected >= columns:
			selected -= columns
		
		else:
			selected = get_child_count() - columns + selected
	
	elif event.is_action_pressed("move_south"):
		if selected + columns <= get_child_count() - 1:
			selected += columns
		
		# Wrap vertically
		else:
			selected = selected % columns

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func update_cursor_position():
	var selected_item = get_children()[selected]
	var setpos = selected_item.get_global_rect().position
	cursor.global_position.x = setpos.x - cursor.get_rect().size.x - cursor_offset
	cursor.global_position.y = setpos.y
	#cursor.global_position.y = setpos.y - (cursor.size.y / 2)
