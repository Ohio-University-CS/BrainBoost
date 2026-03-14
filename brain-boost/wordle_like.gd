extends Control

@onready var text: RichTextLabel = $ColorRect/RichTextLabel2
@onready var inputText: LineEdit = $ColorRect/LineEdit
@onready var scoreOutput: RichTextLabel = $ColorRect/Score

func read_text(file_path) -> Array:
# vector of words
	var words = [];
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		while not file.eof_reached():
			var word = file.get_line()
			# Process each line as needed
			if(word != ""):
				words.append(word)
		file.close()
	else:
		print("Error opening file: ", file_path)
	
	return words

var words
var answer
var score = 0;
var new_word_needed = true;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scoreOutput.text = str(score)
	words = read_text("res://sgb-words.txt")
	
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if new_word_needed:
		answer = words[randi() % words.size()]
		#scramble answer!!
		var scram_answer = answer
		text.text = scram_answer
		new_word_needed = false
	else:
		if inputText.text == answer:
			new_word_needed = true
			score = score + 1
			scoreOutput.text = str(score)
			inputText.text = ""
