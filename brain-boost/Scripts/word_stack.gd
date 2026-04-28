extends Control

# Child node references
@onready var puzzle_gen  = $PuzzleGenerator
@onready var start_label = $Container/Panel/VBoxContainer2/StartLabel
@onready var tile_area   = $Container/VBoxContainer/Tile_Area
@onready var feedback    = $FeedBack
@onready var check_btn   = $Container/Buttons/CheckButton
@onready var new_btn     = $Container/Buttons/NewButton
@onready var new_btn2     = $Panel/Panel/NewButton
@onready var undo_btn    = $Container/Buttons/UndoButton
@onready var back_btn    = $Container/TopBar/Panel/BackButton 
@onready var back_btn2    = $Panel/Panel/BackButton
@onready var label       = $Container/TopBar/Panel/Label
@onready var final_response =$Panel/Panel/Label
@onready var end_popup    = $Panel
@onready var scoretxt = $Panel/Panel/Label2
@onready var confetti = $Panel/GPUParticles2D
@onready var time_taken = $Panel/Panel/HFlowContainer/VFlowContainer/TimeTaken
@onready var checks_left = $Panel/Panel/HFlowContainer/VFlowContainer2/ChecksLeft

const WordTileScene = preload("res://Scenes/Word_Tile.tscn")

var START_WORDS = [
	"air","back","ball","barn","black","blood","blue","bone","book","break","broad","brush","butter","camp","candle",
	"child","cliff","corn","cow","cross","day","door","down","drum","egg","eye","farm","fire","fish","flag","folk",
	"foot","free","gold","grand","grave","grey","gun","hand","hard","hay","head","heart","high","hill","home","honey",
	"horse","house","ice","iron","key","land","life","light","log","mill","moon","mud","night","out","over","paper",
	"park","pass","pay","pin","pipe","play","pond","rain","road","rock","rose","round","sail","sand","sea","ship",
	"shoe","side","sky","snow","song","star","steam","stone","sun","swan","tail","thunder","tide","timber","time",
	"trade","trail","tree","under","war","water","whale","wild","wind","wolf","wood","yard"
]

var current_puzzle: Array = []
var player_chain: Array = []
var start_word: String = ""
var elapsed_seconds: float = 0
var checks: int = 3
var won: bool = false

func _ready():
	end_popup.hide()
	check_btn.pressed.connect(check_chain)
	new_btn.pressed.connect(new_puzzle)
	new_btn2.pressed.connect(new_puzzle)
	undo_btn.pressed.connect(reset_puzzle)
	back_btn.pressed.connect(_on_back_pressed)
	back_btn2.pressed.connect(_on_back_pressed)
	new_puzzle()
	elapsed_seconds = 0
	$".".theme =load("res://Scenes/home_menu.tscn")

func _score() -> int:
	var score = (10000 -(elapsed_seconds * 258)) * checks
	
	return score

func _process(delta: float) -> void:
	if not won:
		elapsed_seconds += delta
		label.text = format_time(int(elapsed_seconds))
	if checks == 0:
		end_popup.show()
		feedback.text = "Defeat"
		final_response.text = "YOU LOST"
		
		scoretxt.text = "TRY AGAIN!"
		scoretxt.label_settings.font_color = Color.RED
		checks_left.text = str(checks) + "/3"
		time_taken.text = "DNF"
		confetti.emitting = false
		
	if won:
		end_popup.show()
		scoretxt.text = str(_score()) + " " + "Pts."
		scoretxt.label_settings.font_color = Color("#f0a500")
		final_response.text = "PUZZLE SOLVED"
		checks_left.text = str(checks) + "/3"
		time_taken.text = label.text
		confetti.emitting = true
		

func format_time(seconds: int) -> String:
	var minutes = seconds / 60
	var secs = seconds % 60
	return "%02d:%02d" % [minutes, secs]

func new_puzzle() -> void:
	won = false
	end_popup.hide()
	elapsed_seconds = 0
	checks = 3
	check_btn.text = "Check" + " " + str(checks) + "/3"
	reset_puzzle()
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
	print(current_puzzle)


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
	var checkCount = 0;
	if not checks == 0:
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
			if player_chain[i] != current_puzzle[i]:
				print("Try again!")
				break
			else:
				checkCount += 1
		if checkCount == 7:
			won = true
			if AcountManager.is_logged_in:
				AcountManager.save_score("WordStack", _score())
				if not AcountManager.score_saved.is_connected(_on_score_saved):
					AcountManager.score_saved.connect(_on_score_saved, CONNECT_ONE_SHOT)
			return

		print(checkCount)
		checks -= 1
		check_btn.text = "Check" + " " + str(checks) + "/3"

func reset_puzzle() -> void:
	if player_chain.is_empty():
		return
	player_chain = [start_word]
	# Free any tiles that were reparented to root during dragging
	for tile in get_tree().get_nodes_in_group("active_tiles"):
		tile.queue_free()
	_render()

func _on_score_saved():
	print("score saved")

func _set_buttons_disabled(val: bool) -> void:
	check_btn.disabled = val
	new_btn.disabled   = val
	undo_btn.disabled  = val

func _on_back_pressed() -> void:
	reset_puzzle()
	get_tree().change_scene_to_file("res://Scenes/home_menu.tscn")
