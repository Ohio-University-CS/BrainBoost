extends CheckButton

func _ready() -> void:
	ThemeManager.theme_changed.connect(_apply_theme)
	_apply_theme()

func _apply_theme() -> void:
	modulate = get_theme_color("font_color", "Label")
