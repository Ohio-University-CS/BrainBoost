extends Control

signal tile_placed(word: String)
signal tile_removed(word: String)

@onready var txt: RichTextLabel = $TextureRect/RichTextLabel

var word: String = ""
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var home_position: Vector2 = Vector2.ZERO
var snapped_slot = null
var original_parent = null

# ─────────────────────────────────────────────
# Setup
# ─────────────────────────────────────────────

func setup(w: String) -> void:
	word = w
	if is_inside_tree() and txt:
		txt.text = w
	else:
		call_deferred("_deferred_setup", w)

func _deferred_setup(w: String) -> void:
	if txt:
		txt.text = w
	else:
		push_error("RichTextLabel not found!")

func _ready() -> void:
	await get_tree().process_frame
	home_position = global_position

# ─────────────────────────────────────────────
# Dragging
# ─────────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = event.position
			if snapped_slot != null:
				snapped_slot.set_meta("occupied", false)
				snapped_slot.set_meta("occupying_tile", null)
				snapped_slot = null
				emit_signal("tile_removed", word)  # ← add this
			z_index = 10
			# Cache root BEFORE removing from tree
			var root = get_tree().root
			var current_global = global_position
			original_parent = get_parent()
			original_parent.remove_child(self)
			root.add_child(self)
			global_position = current_global
	elif event is InputEventMouseMotion and dragging:
		position += event.relative

# Global mouse release so it fires even if cursor moved off tile
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and not event.pressed \
	and dragging:
		dragging = false
		z_index = 0
		_try_snap()

# ─────────────────────────────────────────────
# Snapping
# ─────────────────────────────────────────────

func _try_snap() -> void:
	var slots = get_tree().get_nodes_in_group("chain_slots")
	var best_slot = null
	var best_dist = INF

	for slot in slots:
		if slot.get_meta("occupied", false):
			continue
		var slot_rect = Rect2(slot.global_position, slot.size)
		var tile_rect = Rect2(global_position, size)
		if tile_rect.intersects(slot_rect):
			var dist = global_position.distance_to(slot.global_position)
			if dist < best_dist:
				best_dist = dist
				best_slot = slot

	if best_slot != null:
		snapped_slot = best_slot
		best_slot.set_meta("occupied", true)
		best_slot.set_meta("occupying_tile", self)
		global_position = best_slot.global_position + (best_slot.size - size) / 2
		emit_signal("tile_placed", word)
	else:
		# Return to original parent and home position
		var root = get_tree().root
		root.remove_child(self)
		original_parent.add_child(self)
		global_position = home_position
