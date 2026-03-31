extends Control

# Child node references
@onready var puzzle_gen  = $PuzzleGenerator
@onready var start_label = $Container/Panel/VBoxContainer2/ColorRect/StartLabel
@onready var tile_area   = $Container/VBoxContainer/Tile_Area
@onready var feedback    = $FeedBack
@onready var check_btn   = $Container/Buttons/CheckButton
@onready var new_btn     = $Container/Buttons/NewButton
@onready var undo_btn    = $Container/Buttons/UndoButton
@onready var back_btn    = $Container/TopBar/Panel/BackButton
@onready var label       = $Container/TopBar/Panel/Label

const WordTileScene = preload("res://Scenes/Word_Tile.tscn")
var START_WORDS = [
	"air"
]

var current_puzzle: Array = []
var player_chain: Array = []
var start_word: String = ""
var elapsed_seconds: float = 0

func _ready():
	check_btn.pressed.connect(check_chain)
	new_btn.pressed.connect(new_puzzle)
	undo_btn.pressed.connect(reset_puzzle)
	back_btn.pressed.connect(_on_back_pressed)
	new_puzzle()
	elapsed_seconds = 0
	



func _process(delta: float) -> void:
	elapsed_seconds += delta
	label.text = format_time(int(elapsed_seconds))

func format_time(seconds: int) -> String:
	var minutes = seconds / 60
	var secs = seconds % 60
	return "%02d:%02d" % [minutes, secs]

func new_puzzle() -> void:
	
	feedback.text = "Loading..."
	_set_buttons_disabled(true)
	start_word = START_WORDS[randi() % START_WORDS.size()]
	current_puzzle = await puzzle_gen.generate_puzzle(start_word, 6)
	_set_buttons_disabled(false)
	if current_puzzle.is_empty():
		feedback.text = "Couldn't build a puzzle — trying another word."
		await get_tree().create_timer(1.5).timeout
		new_puzzle()
		return
	player_chain = [start_word]
	_render()


func _render() -> void:
	feedback.text = ""

	# Reset all slots
	for slot in get_tree().get_nodes_in_group("chain_slots"):
		slot.set_meta("occupied", false)
		slot.set_meta("occupying_tile", null)

	# Clear and rebuild tile area
	for c in tile_area.get_children():
		tile_area.remove_child(c)
		c.queue_free()

	var start_word: String = current_puzzle[0]
	var solution: Array = current_puzzle.slice(1)  # words the player must place

	start_label.text = start_word

	for word in solution:
		if player_chain.has(word):
			continue
		var tile: Control = WordTileScene.instantiate()
		tile.setup(word)
		tile_area.add_child(tile)
		tile.tile_placed.connect(_on_tile_placed)
		tile.tile_removed.connect(_on_tile_removed)
		tile.add_to_group("active_tiles")
		



func _on_tile_placed(word: String) -> void:
	print("Tile placed: ", word)

func _on_tile_removed(word: String) -> void:
	print("Tile removed: ", word)

func check_chain() -> void:
	var slots = get_tree().get_nodes_in_group("chain_slots")
	slots.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)
	
	player_chain = [start_word]
	for slot in slots:
		if slot.get_meta("occupied", false) and slot.has_meta("occupying_tile"):
			var tile = slot.get_meta("occupying_tile")
			if tile != null:
				player_chain.append(tile.word)

	print("Chain built from slots: ", player_chain)

	if player_chain.size() < current_puzzle.size() - 1:
		feedback.text = "Puzzle not finished yet!"
		return

	for i in range(player_chain.size()):
		if not player_chain[i] == current_puzzle[i]:
			feedback.text = "Try again!"
		else:
			feedback.text = "Perfect chain!"
			feedback.add_theme_color_override("font_color", Color(0.2, 0.8, 0.45))

func reset_puzzle() -> void:
	if player_chain.is_empty():
		return
	player_chain = [start_word]
	# Free any tiles that were reparented to root during dragging
	for tile in get_tree().get_nodes_in_group("active_tiles"):
		tile.queue_free()
	_render()



func _set_buttons_disabled(val: bool) -> void:
	check_btn.disabled = val
	new_btn.disabled   = val
	undo_btn.disabled  = val

func _on_back_pressed() -> void:
	reset_puzzle()
	get_tree().change_scene_to_file("res://Scenes/home_menu.tscn")
