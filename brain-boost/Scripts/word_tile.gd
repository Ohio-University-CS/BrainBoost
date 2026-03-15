extends Button

signal tile_pressed(word: String)

var word: String = ""

func setup(w: String):
	word = w
	text = w

func _pressed():
	tile_pressed.emit(word)
