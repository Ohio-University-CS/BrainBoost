extends Node

signal theme_changed



var themes = [
	"res://Themes/dark.tres","res://Themes/light.tres","res://Themes/deep_blue.tres"
]

var current_theme = themes[0]

func apply_theme(index: int) -> void:
	current_theme = themes[index]
	var theme = load(themes[index]) as Theme
	get_tree().root.theme = theme
	emit_signal("theme_changed")
	# Save the selection
	var config = ConfigFile.new()
	config.set_value("settings", "theme_index", index)
	config.save("user://settings.cfg")

func load_saved_theme() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var index = config.get_value("settings", "theme_index", 0)
		apply_theme(index)
