extends GutTest

var sudoku_scene
var sudoku_instance

func before_each():
	sudoku_scene = load("res://Scenes/Sudoku.tscn")
	sudoku_instance = sudoku_scene.instantiate()
	add_child(sudoku_instance)

	await get_tree().process_frame


func after_each():
	sudoku_instance.queue_free()
	#pause to assure all children are freed
	await get_tree().process_frame


func test_timer_display():
	var StartButton = sudoku_instance.get_node("StartButton")
	StartButton.emit_signal("pressed")
	
	#pause for a frame to let the game start
	await get_tree().process_frame
	
	var timer_label = sudoku_instance.get_node("TimerLabel")
	
	assert_not_null(timer_label)
	assert_eq(timer_label.text, "05:00", "Timer should display 5:00")
	
func test_timer_count_down():
	var StartButton = sudoku_instance.get_node("StartButton")
	StartButton.emit_signal("pressed")
	
	#pause for a frame to let the game start
	await get_tree().process_frame
	#pause for another frame to check timer counts down
	await get_tree().process_frame
	var timer_label = sudoku_instance.get_node("TimerLabel")
	
	assert_not_null(timer_label)
	assert_eq(timer_label.text, "04:59", "Timer should display 4:59")

func test_board_display():
	var StartButton = sudoku_instance.get_node("StartButton")
	StartButton.emit_signal("pressed")
	
	#pause for a frame to let the game start
	await get_tree().process_frame
	
	
	var board_data = sudoku_instance.boardData
	var start_board = sudoku_instance.startBoard
	
	assert_eq(sudoku_instance.boardData , sudoku_instance.startBoard, "Starting board was not copied correctly")

#valid number test
func test_cell_input_valid() -> void:
	
	var scene = load("res://Scenes/Sudoku.tscn")
	var instance = scene.instantiate()
	add_child(instance)

	#press start
	var start: Button = instance.get_node("StartButton")
	assert_not_null(start)
	start.emit_signal("pressed")
	await get_tree().process_frame

	#clikc first cell
	var grid: GridContainer = instance.get_node("CenterContainer/GridContainer")
	assert_not_null(grid)
	assert_eq(grid.get_child_count(), 81)

	var firstCell: Button = grid.get_child(0)
	assert_not_null(firstCell)

	# select cell
	firstCell.emit_signal("pressed")
	instance.handleInput(3)


	assert_eq(firstCell.text, "3")
	assert_eq(instance.boardData[0], 3, "3 is valid")


#test invalid input
func test_cell_input_invalid() -> void:

	var scene = load("res://Scenes/Sudoku.tscn")
	var instance = scene.instantiate()
	add_child(instance)

	#press start
	var start: Button = instance.get_node("StartButton")
	assert_not_null(start)
	start.emit_signal("pressed")
	await get_tree().process_frame

	#clikc first cell
	var grid: GridContainer = instance.get_node("CenterContainer/GridContainer")
	assert_not_null(grid)
	assert_eq(grid.get_child_count(), 81)

	var firstCell: Button = grid.get_child(0)
	assert_not_null(firstCell)

	# select cell
	firstCell.emit_signal("pressed")
	instance.handleInput(1)


	assert_eq(firstCell.text, "")
	assert_eq(instance.boardData[0], 0, "1 is invalid here")
