extends Control

signal tile_pressed(word: String)

@onready var txt: RichTextLabel = $TextureRect/RichTextLabel

var word: String = ""
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# -----------------------------
# Setup the word
# -----------------------------
func setup(w: String) -> void:
	word = w
	if is_inside_tree() and txt:
		txt.text = "test"
	else:
		# Wait until ready
		call_deferred("_deferred_setup", w)

func _deferred_setup(w: String) -> void:
	if txt:
		txt.text = w
	else:
		push_error("RichTextLabel not found! Check the node path.")

# -----------------------------
# Dragging
# -----------------------------
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = event.position
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		position += event.relative

# -----------------------------
# Optional: click signal
# -----------------------------
func _pressed() -> void:
	emit_signal("tile_pressed", word)
