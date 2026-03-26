extends Control

@onready var text: RichTextLabel = $ColorRect/RichTextLabel2
@onready var inputText: LineEdit = $ColorRect/LineEdit
@onready var scoreOutput: RichTextLabel = $ColorRect/Score
@onready var timeText: RichTextLabel = $ColorRect/RichTextLabel
@onready var popUp: ColorRect = $GameEndPopUp
@onready var finalScore: RichTextLabel = $"GameEndPopUp/Final Score"

@export var countdown_time: float = 300

var time
var words
var possible_answers
var answer
var answer_counts: Array[int]
var answer_chars: Array[String]
var score = 0
var new_word_needed
var countdownActive

func read_text(file_path) -> Array[String]:
# vector of words
	var new_words: Array[String] = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		while not file.eof_reached():
			var word = file.get_line()
			# Process each line as needed
			if(word != ""):
				new_words.append(word)
		file.close()
	else:
		print("Error opening file: ", file_path)
		
	return new_words


func char_counts(word, chars: Array, counts: Array):
	for i in range(word.length()):
		var ch = word[i]
		var notCounted = true
		for j in range(chars.size()):
			if ch == chars[j]:
				notCounted = false
		if notCounted:
			chars.append(ch)
			counts.append(1)
		else:
			for j in range(chars.size()):
				if ch == chars[j]:
					counts[j] += 1

func find_possible(chars: Array, counts: Array):
	var new_answers : Array[String]
	for i in range(possible_answers.size()):
		var item_chars = []
		var item_counts = []
		char_counts(possible_answers[i], item_chars, item_counts)
		
		if(item_chars == chars and item_counts == counts):
			new_answers.append(possible_answers[i])
	
	possible_answers = new_answers
	print(possible_answers)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scoreOutput.text = str(score)
	words = read_text("res://wordles.txt")
	time = countdown_time
	countdownActive = true
	new_word_needed = true
	popUp.hide()

	
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#check if time > 0
	if (int(time) % 60) > 0 or floor(time /60) > 0:
		time -= delta
		var mins = floor(time /60)
		var secs = int(time) % 60
		timeText.text = "%1d:%02d" % [mins, secs]
	else:
		#end game
		time = 0
		countdownActive = false;
		inputText.text = ""
		timeText.text = "0:00"
		popUp.show()
		finalScore.text = "Final Score: " + str(score)
	if new_word_needed:
		answer = words[randi() % words.size()]
		
		#finds all possible answers
		answer_chars = []
		answer_counts = []
		char_counts(answer, answer_chars, answer_counts)
		possible_answers = read_text("res://sgb-words.txt")
		find_possible(answer_chars, answer_counts)
		
		#scramble answer!!
		var scram_answer = answer
		for i in range(1):
			var index = (randi() % (answer.length() - 1)) + 1
			var scram1 = answer.substr(0, index) 
			var scram2 = answer.substr(index, answer.length())
			scram_answer = scram2 + scram1
		text.text = scram_answer
		new_word_needed = false
		
		print(answer)
		print(answer_chars)
		print(answer_counts)
	else:
		#finds inputs unqiue chars and char count
		var input_chars = []
		var input_counts = []
		char_counts(inputText.text, input_chars, input_counts)
		
		#checks if input is possible word
		#needs more work!!!!
		#make so chars order doesnt matter
		#check that word is real (prob using sgb-words)
		for i in range(possible_answers.size()):
			if possible_answers[i] == inputText.text:
				new_word_needed = true
				score = score + 1
				scoreOutput.text = str(score)
				inputText.text = ""

func _on_exit_button_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/home_menu.tscn")
