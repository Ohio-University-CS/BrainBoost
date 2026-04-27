extends Control

# Logic Variables
var cpu_sequence = []
var player_sequence = []
var is_cpu_playing = false
var high_score = 0
"res://Scripts/Patterngame.gd"

# These link the code to your Scene Dock nodes
@onready var buttons = []
@onready var instructions = %Instructions
@onready var score_label = %Score
@onready var high_score_label = %HighScore

var score = 0

func _ready():
	# 1. Manually fill the button array to prevent "Index" errors
	# Make sure these names match your Scene Dock exactly!
	buttons = [
		get_node("%Button"), 
		get_node("%Button2"), 
		get_node("%Button3"), 
		get_node("%Button4")
	]
	
	# 2. Setup button colors and auto-connect the click signals
	var colors = [Color("#ff595e"), Color("#1982c4"), Color("#8ac926"), Color("#ffca3a")]
	
	for i in range(buttons.size()):
		if buttons[i] != null:
			buttons[i].modulate = colors[i]
			buttons[i].self_modulate = colors[i] # Extra color boost
			# This line connects the button click to our function automatically
			buttons[i].pressed.connect(_on_button_pressed.bind(i))
	
	# 3. Initialize the UI
	instructions.text = "Get Ready..."
	score_label.text = "Current: 0"
	high_score_label.text = "Best: 0"
	
	# Wait a second, then start!
	await get_tree().create_timer(1.0).timeout
	start_new_round()
	

func start_new_round():
	is_cpu_playing = true
	player_sequence = []
	
	# Add a new random step to the pattern
	cpu_sequence.append(randi() % 4)
	
	instructions.text = "WATCH!"
	score_label.text = "Current: " + str(cpu_sequence.size() - 1)
	
	# Flash the sequence
	for index in cpu_sequence:
		var btn = buttons[index]
		btn.modulate.a = 0.3
		await get_tree().create_timer(0.5).timeout
		btn.modulate.a = 1.0
		await get_tree().create_timer(0.2).timeout
	
	is_cpu_playing = false
	instructions.text = "GO!"

func _on_button_pressed(index: int):
	# Ignore clicks if it's the computer's turn
	if is_cpu_playing: 
		return
	
	player_sequence.append(index)
	
	# Visual feedback for your click
	buttons[index].modulate.a = 0.5
	await get_tree().create_timer(0.1).timeout
	buttons[index].modulate.a = 1.0
	
	check_answer()

func check_answer():
	var last_index = player_sequence.size() - 1
	
	# 1. WRONG ANSWER LOGIC
	if player_sequence[last_index] != cpu_sequence[last_index]:
		is_cpu_playing = true # Stop inputs immediately
		
		# Play fail sound if it exists
		if has_node("FailSound"):
			$FailSound.play()
		
		# Calculate the score BEFORE we clear the sequence
		var current_score = cpu_sequence.size() - 1
		
		# Save to your AcountManager leaderboard
		if AcountManager.is_logged_in: 
			AcountManager.save_score("Pattern", current_score)
			if not AcountManager.score_saved.is_connected(_on_score_saved):
				AcountManager.score_saved.connect(_on_score_saved, CONNECT_ONE_SHOT)
				
		# Update High Score UI
		if current_score > high_score:
			high_score = current_score
			high_score_label.text = "Best: " + str(high_score)
			instructions.text = "NEW BEST!"
		else:
			instructions.text = "GAME OVER!"
		
		# Reset game variables
		cpu_sequence = []
		player_sequence = []
		
		# Wait 2 seconds so the player can see their "Game Over" message
		await get_tree().create_timer(2.0).timeout
		start_new_round()
		
		# STOP HERE. This return prevents the crash!
		return 

	# 2. CORRECT ANSWER LOGIC
	# If the code reaches this point, the last click was correct.
	# Now check if they finished the ENTIRE pattern for this round.
	if player_sequence.size() == cpu_sequence.size():
		score_label.text = "Current: " + str(cpu_sequence.size())
		instructions.text = "NICE!"
		
		if has_node("WinSound"):
			$WinSound.play()
			
		# Wait a moment before starting the next round with a new button
		await get_tree().create_timer(0.8).timeout
		start_new_round()

func _on_backbutton_pressed() -> void:
	print("Back button clicked! Heading home...")
	get_tree().change_scene_to_file("res://Scenes/home_menu.tscn")
	
func _on_score_saved(status):
	print("Score saved to leaderboard! Status: ", status)
