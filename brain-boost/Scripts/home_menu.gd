extends Control

@onready var popup = $"Popup Wrapper"
@onready var online_menu = $"Popup Wrapper/Online"
@onready var settings_menu = $"Popup Wrapper/Settings"
@onready var stats_menu = $"Popup Wrapper/Stats"





# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	popup.hide()
	online_menu.hide()
	settings_menu.hide()
	stats_menu.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_online_button_pressed():
	popup.show()
	online_menu.show()
	


func _on_settings_button_pressed() -> void:
	popup.show()
	settings_menu.show()


func _on_stats_button_pressed() -> void:
	popup.show()
	stats_menu.show()
	
	


func _on_margin_container_gui_input(event):
	# This checks if the user clicked the Left Mouse Button
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Box clicked! Switching to Sudoku...")
		get_tree().change_scene_to_file("res://Scenes/SudokuGame.tscn")


func _on_margin_container_2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Box clicked! Switching to Word Game...")
		get_tree().change_scene_to_file("res://Scenes/wordle_like.tscn")


func _on_margin_container_4_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Box clicked! Switching to Word Stack...")
		get_tree().change_scene_to_file("res://Scenes/Word_Stack.tscn")
