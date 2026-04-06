extends Control

@onready var popup = $"Popup Wrapper"
@onready var stats = $"Popup Wrapper/Stats"
@onready var online_menu = $"Popup Wrapper/Online"
@onready var settings_menu = $"Popup Wrapper/Settings"
@onready var stats_menu = $"Popup Wrapper/Stats"
@onready var themes_drop_down = $"Popup Wrapper/Settings/VBoxContainer/HBoxContainer/OptionButton"



func _ready() -> void:
	ThemeManager.load_saved_theme()
	popup.hide()
	online_menu.hide()
	settings_menu.hide()
	stats_menu.hide()

func _process(_delta: float) -> void:
	pass

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
		global_list.add_item("#%d  %s  —  %d" % [i + 1, entry_name, score])

func _on_my_scores_loaded(data: Array) -> void:
	var personal_list = $"Popup Wrapper/Stats/PersonalList"
	personal_list.clear()
	for i in data.size():
		var entry = data[i]
		var score = entry.get("score", 0)
		var date = entry.get("played_at", "").left(10)  # trims to "2026-04-05"
		personal_list.add_item("#%d  %s  —  %d" % [i + 1, date, score])

# ─── Button Handlers ────────────────────────────────────

func _on_online_button_pressed():
	if !AcountManager.is_logged_in:
		get_tree().change_scene_to_file("res://Scenes/login.tscn")

func _on_settings_button_pressed() -> void:
	popup.show()
	settings_menu.show()
	stats.hide()

func _on_stats_button_pressed() -> void:
	popup.show()
	stats_menu.show()
	if not AcountManager.is_logged_in:
		return
	AcountManager.leaderboard_loaded.connect(_on_leaderboard_loaded, CONNECT_ONE_SHOT)
	AcountManager.my_scores_loaded.connect(_on_my_scores_loaded, CONNECT_ONE_SHOT)
	AcountManager.get_leaderboard()
	AcountManager.get_my_scores()

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
	ThemeManager.apply_theme(index)
