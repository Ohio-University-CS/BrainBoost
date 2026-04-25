extends Control

@onready var popup = $"Popup Wrapper"
@onready var stats = $"Popup Wrapper/Stats"
@onready var personal_menu = $"Popup Wrapper/Personal"
@onready var settings_menu = $"Popup Wrapper/Settings"
@onready var stats_menu = $"Popup Wrapper/Stats"
@onready var themes_drop_down = $"Popup Wrapper/Settings/VBoxContainer/HBoxContainer/ThemeSelection"
@onready var global_scores = $"Popup Wrapper/Stats/GlobalList"
@onready var personal_scores = $"Popup Wrapper/Stats/PersonalList"

@onready var uname = $"Popup Wrapper/Personal/ColorRect/Uname"
@onready var email = $"Popup Wrapper/Personal/ColorRect/Email"
@onready var bp = $"Popup Wrapper/Personal/ColorRect/BPNum"
@onready var brain_text = $BrainTex/BrainText


func _ready() -> void:
	ThemeManager.load_saved_theme()
	popup.hide()
	personal_menu.hide()
	settings_menu.hide()
	stats_menu.hide()
	if AcountManager.is_logged_in:
		_show_streak()
	#if you just logged in might take a second to load so wait just in case
	await  AcountManager.login_success
	_show_streak()

func _process(_delta: float) -> void:
	global_scores.deselect_all()
	personal_scores.deselect_all()

func get_final_score(score_string: String) -> String:
	# Split the string by the dash character
	var parts = score_string.split("—")
	
	# Get the last element in the array and clean up whitespace
	var final_score = parts[-1].strip_edges()
	
	return final_score

# ─── Stats / Leaderboard ────────────────────────────────

func _on_leaderboard_loaded(data: Array) -> void:
	var global_list = $"Popup Wrapper/Stats/GlobalList"
	global_list.clear()
	for i in data.size():
		var entry = data[i]
		var profile = entry.get("profiles", {})
		var entry_name = profile.get("display_name", "")
		if entry_name == "" or entry_name == null:
			entry_name = profile.get("username", "Unknown")
		var score = entry.get("score", 0)
		var game = entry.get("game_name", "")
		global_list.add_item("%s:  %d  —  %s" % [entry_name, score, game])

func _on_my_scores_loaded(data: Array) -> void:
	var personal_list = $"Popup Wrapper/Stats/PersonalList"
	personal_list.clear()
	for i in data.size():
		var entry = data[i]
		var score = entry.get("score", 0)
		var game = entry.get("game_name", "")
		personal_list.add_item("%d  —  %s" % [score, game])


func remove_hidden_scores(game: String):
	global_scores.deselect_all()
	
	# Loop backwards: from (count - 1) down to 0
	for i in range(global_scores.get_item_count() - 1, -1, -1):
		# Use get_item_text(i) to get the label
		var item_text = global_scores.get_item_text(i)
		
		# Your existing logic
		if get_final_score(item_text) != game:
			global_scores.remove_item(i)
	
	#same for user scores
	for i in range(personal_scores.get_item_count() - 1, -1, -1):
		# Use get_item_text(i) to get the label
		var item_text = personal_scores.get_item_text(i)
		
		# Your existing logic
		if get_final_score(item_text) != game:
			personal_scores.remove_item(i)

func _show_streak() -> void:
	AcountManager.streak_loaded.connect(_on_streak_loaded, CONNECT_ONE_SHOT)
	AcountManager.get_streak()

func _on_streak_loaded(count: int) -> void:
	print("Current streak: ", count, " day(s)")
	brain_text.text = str(count)


func load_all_scores():
	if not AcountManager.is_logged_in:
		return
	if AcountManager.leaderboard_loaded.is_connected(_on_leaderboard_loaded):
		AcountManager.leaderboard_loaded.disconnect(_on_leaderboard_loaded)
	if AcountManager.my_scores_loaded.is_connected(_on_my_scores_loaded):
		AcountManager.my_scores_loaded.disconnect(_on_my_scores_loaded)
	AcountManager.leaderboard_loaded.connect(_on_leaderboard_loaded, CONNECT_ONE_SHOT)
	AcountManager.my_scores_loaded.connect(_on_my_scores_loaded, CONNECT_ONE_SHOT)
	AcountManager.get_leaderboard()
	AcountManager.get_my_scores()
	
# ─── Button Handlers ────────────────────────────────────

func _on_online_button_pressed():
	if !AcountManager.is_logged_in:
		get_tree().change_scene_to_file("res://Scenes/login.tscn")
	else:
		uname.text = AcountManager.display_name
		email.text = AcountManager.email
		popup.show()
		personal_menu.show()
		stats_menu.hide()
		settings_menu.hide()

func _on_settings_button_pressed() -> void:
	popup.show()
	settings_menu.show()
	stats.hide()
	personal_menu.hide()

func _on_stats_button_pressed() -> void:
	popup.show()
	stats_menu.show()
	settings_menu.hide()
	personal_menu.hide()

# ─── Scene Navigation ───────────────────────────────────

func _on_margin_container_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().change_scene_to_file("res://Scenes/Sudoku.tscn")

func _on_margin_container_2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().change_scene_to_file("res://Scenes/wordle_like.tscn")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Patterngame.tscn")

func _on_margin_container_4_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().change_scene_to_file("res://Scenes/Word_Stack.tscn")
 




func _on_option_button_item_selected(index: int) -> void:
	# Disconnect any existing connections before adding new ones
	if AcountManager.leaderboard_loaded.is_connected(_on_leaderboard_loaded):
		AcountManager.leaderboard_loaded.disconnect(_on_leaderboard_loaded)
	if AcountManager.my_scores_loaded.is_connected(_on_my_scores_loaded):
		AcountManager.my_scores_loaded.disconnect(_on_my_scores_loaded)

	# Clear lists
	global_scores.clear()
	personal_scores.clear()

	# Connect fresh one-shots
	AcountManager.leaderboard_loaded.connect(_on_leaderboard_loaded, CONNECT_ONE_SHOT)
	AcountManager.my_scores_loaded.connect(_on_my_scores_loaded, CONNECT_ONE_SHOT)

	var selected_game = $"Popup Wrapper/Stats/OptionButton".get_item_text(index)
	var loaded = [false, false]

	AcountManager.leaderboard_loaded.connect(
		func(_data):
			loaded[0] = true
			if loaded[1]:
				remove_hidden_scores(selected_game),
		CONNECT_ONE_SHOT
	)
	AcountManager.my_scores_loaded.connect(
		func(_data):
			loaded[1] = true
			if loaded[0]:
				remove_hidden_scores(selected_game),
		CONNECT_ONE_SHOT
	)

	AcountManager.get_leaderboard()
	AcountManager.get_my_scores()


func _on_theme_selection_item_selected(index: int) -> void:
	ThemeManager.apply_theme(index)


func _on_logout_button_button_up() -> void:
	AcountManager.logout()
	brain_text.text = ""
	personal_menu.hide()
	popup.hide()
