extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_grid_cursor_selection_changed(index):
	pass

func _on_grid_cursor_selection_confirmed(index):
	$UISFX.play(0.14)
