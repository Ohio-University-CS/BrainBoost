extends Control

@onready var text: RichTextLabel = $ColorRect/RichTextLabel2
@onready var inputText: LineEdit = $ColorRect/LineEdit
@onready var scoreOutput: RichTextLabel = $ColorRect/Score
@onready var extraText: RichTextLabel = $ColorRect/RichTextLabel

var words
var answer
var score = 0;
var new_word_needed = true;

func read_text(file_path) -> void:
# vector of words
	words = [];
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



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scoreOutput.text = str(score)
	read_text("res://sgb-words.txt")
	
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if new_word_needed:
		answer = words[randi() % words.size()]
		
		#scramble answer!!
		var scram_answer = answer
		for i in range(1):
			var index = randi() % answer.length()
			var scram1 = answer.substr(0, index) 
			var scram2 = answer.substr(index, answer.length())
			scram_answer = scram2 + scram1
		text.text = scram_answer
		extraText.text = answer
		new_word_needed = false
	else:
		if inputText.text == answer:
			new_word_needed = true
			score = score + 1
			scoreOutput.text = str(score)
			inputText.text = ""
