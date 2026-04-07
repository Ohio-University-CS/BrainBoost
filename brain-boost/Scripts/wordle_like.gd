extends Node

@onready var text: RichTextLabel = $ColorRect/RichTextLabel2
@onready var inputText: LineEdit = $ColorRect/LineEdit
@onready var scoreOutput: RichTextLabel = $ColorRect/Score
@onready var timeText: RichTextLabel = $ColorRect/RichTextLabel3
@onready var popUp: ColorRect = $GameEndPopUp
@onready var finalScore: RichTextLabel = $"GameEndPopUp/Final Score"
@onready var home = $Button

@export var countdown_time: float = 300.0
@export var scrambles: int

var time
var words
var possible_answers
var answer
var answer_counts: Array[int]
var answer_chars: Array[String]
var score = 0
var finalScoreNum = -1
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

#make so chars order doesnt matter
func find_possible(all_words: Array, chars: Array, counts: Array) -> Array[String]:
	var new_answers : Array[String]
	for i in range(all_words.size()):
		var item_chars = []
		var item_counts = []
		char_counts(all_words[i], item_chars, item_counts)
		
		var sameChars = true
		for j in range(item_chars.size()):
			if !(chars.has(item_chars[j])):
				sameChars = false
		
		if sameChars and item_counts == counts:
			new_answers.append(all_words[i])
	
	return new_answers

func scramble(new_answer) -> String:
	if new_answer.length() == 1:
		return new_answer
	var scram_answer = new_answer
	for i in range(scrambles):
		var index = (randi() % (new_answer.length() - 1)) + 1
		var scram1 = scramble(new_answer.substr(0, index))
		var scram2 = new_answer.substr(index, new_answer.length())
		scram_answer = scram2 + scram1
		print(index)
		print(scram_answer)
	
	return scram_answer
	
func format_time(cur_time) -> String:
	var mins = floor(cur_time /60)
	var secs = int(cur_time) % 60
	return "%1d:%02d" % [mins, secs]

func answer_found() -> void:
	new_word_needed = true
	score = score + 1
	scoreOutput.text = str(score)
	inputText.text = ""

func end_game() -> void:
	time = 0
	countdownActive = false;
	inputText.text = ""
	timeText.text = "	0:00"
	popUp.show()
	finalScoreNum = score
	finalScore.text = "Final Score: " + str(finalScoreNum)
	if AcountManager.is_logged_in:
		AcountManager.save_score("Scrambled", score)
		AcountManager.score_saved.connect(_on_score_saved, CONNECT_ONE_SHOT)

func _on_score_saved():
	$ColorRect/Saved.show()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scoreOutput.text = str(score)
	words = read_text("res://wordles.txt")
	time = countdown_time
	countdownActive = true
	new_word_needed = true
	popUp.hide()
	home.pressed.connect(_home)

	
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#check if time > 0
	if (int(time) % 60) > 0 or floor(time /60) > 0:
		time -= delta
		timeText.text = "	" + format_time(time)
	else:
		if finalScoreNum == -1:
			end_game()
		
	if new_word_needed:
		answer = words[randi() % words.size()]
		
		#finds all possible answers
		answer_chars = []
		answer_counts = []
		char_counts(answer, answer_chars, answer_counts)
		possible_answers = read_text("res://sgb-words.txt")
		possible_answers = find_possible(possible_answers, answer_chars, answer_counts)
		
		var scram_answer = scramble(answer)
		text.text = scram_answer
		
		if possible_answers.size() != 0:
			new_word_needed = false
		
		print(possible_answers)
		print(answer_chars)
		print(answer_counts)
	else:
		#finds inputs unqiue chars and char count
		var input_chars = []
		var input_counts = []
		char_counts(inputText.text, input_chars, input_counts)
		
		for i in range(possible_answers.size()):
			if possible_answers[i] == inputText.text:
				answer_found()

func _on_exit_button_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/home_menu.tscn")


func _home() -> void:
	get_tree().change_scene_to_file("res://Scenes/home_menu.tscn")
