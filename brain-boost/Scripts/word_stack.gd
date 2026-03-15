extends Control

# Child node reference — NOT an autoload
@onready var puzzle_gen  = $PuzzleGenerator
@onready var start_label = $VBoxContainer/StartLabel
@onready var chain_row   = $VBoxContainer/ChainRow
@onready var tile_area   = $VBoxContainer/TileArea
@onready var feedback    = $VBoxContainer/Feedback
@onready var check_btn   = $VBoxContainer/Buttons/CheckButton
@onready var new_btn     = $VBoxContainer/Buttons/NewButton
@onready var undo_btn    = $VBoxContainer/Buttons/UndoButton
@onready var back_btn    = $VBoxContainer/TopBar/BackButton

const WordTileScene = preload("res://Scenes/Word_Tile.tscn")

const START_WORDS = [
	"soccer", "sun", "fire", "hand",
	"water", "book", "snow", "door"
]

var current_puzzle: Dictionary = {}
var player_chain: Array = []

func _ready():
	check_btn.pressed.connect(check_chain)
	new_btn.pressed.connect(new_puzzle)
	undo_btn.pressed.connect(undo_last)
	back_btn.pressed.connect(_on_back_pressed)
	new_puzzle()

func new_puzzle():
	player_chain = []
	feedback.text = "Loading..."
	_set_buttons_disabled(true)

	var start = START_WORDS[randi() % START_WORDS.size()]
	current_puzzle = await puzzle_gen.generate_puzzle(start, 4)

	_set_buttons_disabled(false)

	if current_puzzle.is_empty():
		feedback.text = "Couldn't build a puzzle — trying another word."
		await get_tree().create_timer(1.5).timeout
		new_puzzle()
		return

	_render()

func _render():
	start_label.text = "Start:  " + current_puzzle["start"].to_upper()
	feedback.text = ""

	for c in chain_row.get_children(): c.queue_free()
	for c in tile_area.get_children():  c.queue_free()

	_add_chain_label(current_puzzle["start"], true)
	for word in player_chain:
		_add_arrow_label()
		_add_chain_label(word, false)
	if player_chain.size() < current_puzzle["solution"].size():
		_add_arrow_label()
		_add_empty_slot()

	for word in current_puzzle["tiles"]:
		if player_chain.has(word):
			continue
		var tile: Button = WordTileScene.instantiate()
		tile.setup(word)
		tile.tile_pressed.connect(_on_tile_pressed)
		tile_area.add_child(tile)

func _add_chain_label(word: String, is_start: bool):
	var lbl = Label.new()
	lbl.text = word
	lbl.add_theme_font_size_override("font_size", 62)
	if is_start:
		lbl.add_theme_color_override("font_color", Color(0.55, 0.47, 0.95))
	else:
		lbl.add_theme_color_override("font_color", Color(0.25, 0.75, 0.55))
	chain_row.add_child(lbl)

func _add_arrow_label():
	var lbl = Label.new()
	lbl.text = "→"
	lbl.add_theme_font_size_override("font_size", 62)
	lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	chain_row.add_child(lbl)

func _add_empty_slot():
	var lbl = Label.new()
	lbl.text = "[ ? ]"
	lbl.add_theme_font_size_override("font_size", 62)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	chain_row.add_child(lbl)

func _on_tile_pressed(word: String):
	player_chain.append(word)
	_render()
	if player_chain.size() == current_puzzle["solution"].size():
		check_chain()

func check_chain():
	var full = [current_puzzle["start"]] + player_chain
	for i in range(full.size() - 1):
		if not puzzle_gen.is_valid_pair(full[i], full[i + 1]):
			feedback.text = '"%s" + "%s" is not a valid pair. Try again!' \
				% [full[i], full[i + 1]]
			feedback.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
			player_chain = []
			_render()
			return
	feedback.text = "Perfect chain!"
	feedback.add_theme_color_override("font_color", Color(0.2, 0.8, 0.45))

func undo_last():
	if player_chain.is_empty(): return
	player_chain.pop_back()
	_render()

func _set_buttons_disabled(val: bool):
	check_btn.disabled = val
	new_btn.disabled   = val
	undo_btn.disabled  = val

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_back_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Box clicked! Switching to Home...")
		get_tree().change_scene_to_file("res://Scenes/home_menu.tscn")
