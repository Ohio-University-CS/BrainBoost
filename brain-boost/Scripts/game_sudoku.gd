extends Control

@onready var grid_container: GridContainer = $CenterContainer/GridContainer
@onready var start_button: Button = $StartButton

#current board state
var boardData = []
#inital board layout
#0,0,0,2,6,0,7,0,1,
#6,8,0,0,7,0,0,9,0,
#1,9,0,0,0,4,5,0,0,
#8,2,0,1,0,0,0,4,0,
#0,0,4,6,0,2,9,0,0,
#0,5,0,0,0,3,0,2,8,
#0,0,9,3,0,0,0,7,4,
#0,4,0,0,5,0,0,3,6,
#7,0,3,0,1,8,0,0,0
#------------------
#4,3,5,2,6,9,7,8,1,
#6,8,2,5,7,1,4,9,3,
#1,9,7,8,3,4,5,6,2,
#8,2,6,1,9,5,3,4,7,
#3,7,4,6,8,2,9,1,5,
#9,5,1,7,4,3,6,2,8,
#5,1,9,3,2,6,8,7,4,
#2,4,8,9,5,7,1,3,6,
#7,6,3,4,1,8,2,5,0];
var startBoard =[
	4,3,5,2,6,9,7,8,1,
	6,8,2,5,7,1,4,9,3,
	1,9,7,8,3,4,5,6,2,
	8,2,6,1,9,5,3,4,7,
	3,7,4,6,8,2,9,1,5,
	9,5,1,7,4,3,6,2,8,
	5,1,9,3,2,6,8,7,4,
	2,4,8,9,5,7,1,3,6,
	7,6,3,4,1,8,2,5,0];
var selectedCell : Button 

# 
func _ready() -> void:
	boardData.resize(81)
	boardData.fill(0)
#
func createBoard():
	for i in range(81):
		var btn = Button.new();
		if(startBoard[i] != 0):
			btn.text = str(startBoard[i])
			btn.disabled = true
		boardData[i] = startBoard[i]
		btn.custom_minimum_size = Vector2(50,50)
		btn.pressed.connect(selectButton.bind(btn))
		grid_container.add_child(btn)
		

func selectButton(btn):
	#if(selectedCell != null):
		#selectedCell.modulate = Color.GREEN
	selectedCell = btn
	print("selected")


# 
func _process(delta: float) -> void:
	var input = {
		"one": 1,"two": 2,"three": 3,"four": 4,"five": 5,"six": 6,"seven": 7,"eight": 8,"nine": 9,
	}
	for action in input:
		if(Input.is_action_just_pressed(action)):
			handleInput(input[action])
			
	if(checkWin()):
		$Victory.text = "Winner"
		$ColorRect.color = Color.GREEN


func handleInput(number):
	#error handling
	if(selectedCell != null):
		#valid move; update box to input value
		if(isValidMove(selectedCell.get_index(),number)):
			selectedCell.text = str(number)
			selectedCell.modulate = Color.SKY_BLUE
			boardData[selectedCell.get_index()] = number
			#invalid move; 
		else:
			selectedCell.text = ""
			selectedCell.modulate = Color.RED
			boardData[selectedCell.get_index()] = 0

#verify move is legal
func isValidMove(cellIndex, number):
	var row = cellIndex/9
	var col = cellIndex%9
	
	
	for i in range(9):
		#row check
		if(row*9+i != cellIndex and boardData[row*9+i] == number):
			print("invalid move (row)")
			return false
		#col check
		if(9*i+col != cellIndex and boardData[9*i+col] == number):
			print("invalid move (col)")
			return false
			
	#3x3 check
	var boxRow = row/3*3
	var boxCol = col/3*3
	
	for i in range(3):
		for j in range(3):
			if((boxRow+i)*9+boxCol+j != cellIndex and boardData[(boxRow+i)*9+boxCol+j] == number):
				print("invalid move (box)")
				return false
			
	return true


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_pressed():
		if(selectedCell != null):
			selectedCell.release_focus()
			selectedCell = null


func _on_start_button_pressed() -> void:
	$StartButton.hide()
	createBoard()


func checkWin():
	#check that every spot has been filled 
	for i in boardData:
		if(i == 0):
			return false
	return true


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/home_menu.tscn")
