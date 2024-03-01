extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	var panel: Panel = $Panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color.RED
	panel.add_theme_stylebox_override("panel", style)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
