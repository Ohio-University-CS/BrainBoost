extends Control

@onready var text: RichTextLabel = $ColorRect/RichTextLabel2
@onready var inputText: LineEdit = $ColorRect/LineEdit
@onready var scoreOutput: RichTextLabel = $ColorRect/Score
@onready var timeText: RichTextLabel = $ColorRect/RichTextLabel
@onready var popUp: ColorRect = $GameEndPopUp
@onready var finalScore: RichTextLabel = $"GameEndPopUp/Final Score"

@export var countdown_time: float = 5

var time
var words
var answer
var score = 0
var new_word_needed
var countdownActive

func read_text(file_path) -> void:
# vector of words
	words = []
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
		
		#scramble answer!!
		var scram_answer = answer
		for i in range(1):
			var index = (randi() % (answer.length() - 1)) + 1
			var scram1 = answer.substr(0, index) 
			var scram2 = answer.substr(index, answer.length())
			scram_answer = scram2 + scram1
		text.text = scram_answer
		print(answer)
		new_word_needed = false
	else:
		#check if input is answer
		if inputText.text == answer:
			new_word_needed = true
			score = score + 1
			scoreOutput.text = str(score)
			inputText.text = ""

func _on_exit_button_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/home_menu.tscn")
