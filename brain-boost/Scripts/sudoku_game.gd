extends Control

var light_purple = Color("#5e3a8c")
var dark_blue = Color("#1a2247")
var auto_pink = Color("#ff99d6")
var player_white = Color("#ffffff")

@onready var grid_container = $MarginContainer/VBoxContainer/AspectRatioContainer/GridContainer
var board = [] 

func _ready():
	if not grid_container:
		return

	# This is the vertical list that holds everything
	var vbox = $MarginContainer/VBoxContainer
	var aspect_cont = grid_container.get_parent()

	# 1. SETUP THE GRID
	grid_container.columns = 9

	# 2. FIND THE NODES YOU ALREADY HAVE
	# We search the VBox for any Label or Button you put there in the editor
	for child in vbox.get_children():
		if child is Label:
			# Fix the existing Title
			child.text = "SUDOKU"
			child.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			child.add_theme_font_size_override("font_size", 50)
			child.add_theme_color_override("font_color", auto_pink)
			vbox.move_child(child, 0) # Force to TOP
		
		if child is Button and child != grid_container: # Don't move the grid cells!
			# Fix the existing Button
			child.text = "CHECK BOARD"
			child.custom_minimum_size = Vector2(240, 70)
			child.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			if not child.pressed.is_connected(check_victory):
				child.pressed.connect(check_victory)
			vbox.move_child(child, vbox.get_child_count() - 1) # Force to BOTTOM

	# 3. FIX THE BOARD ALIGNMENT
	aspect_cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	aspect_cont.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.move_child(aspect_cont, 1) # Force to MIDDLE
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 100)
	vbox.add_child(bottom_spacer)
	vbox.move_child(bottom_spacer, -1)

	create_grid()

func create_grid():
	board = []
	for r in range(9):
		var row_data = []
		for c in range(9):
			row_data.append(0)
		board.append(row_data)
	
	# Clear old buttons
	for child in grid_container.get_children():
		child.queue_free()
	
	for i in range(81):
		@warning_ignore("integer_division")
		var r = i / 9
		var c = i % 9
		var cell = Button.new()
		cell.custom_minimum_size = Vector2(60, 60)
		
		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(5)
		
		@warning_ignore("integer_division")
		var box_r = r/3
		@warning_ignore("integer_division")
		var box_c = c/3
		if(box_r + box_c)%2 == 0:
			style.bg_color = light_purple
		else :
			style.bg_color = dark_blue
		cell.add_theme_stylebox_override("normal", style)
		cell.add_theme_stylebox_override("hover", style)
		cell.add_theme_stylebox_override("pressed", style)
		
		if randf() > 0.5:
				var num = randi_range(1, 9)
				if is_legal(r, c, num):
						board[r][c] = num 
						cell.text = str(num)
						cell.add_theme_color_override("font_color", auto_pink)
						cell.add_theme_font_size_override("font_size", 26)
		
		else:
			cell.add_theme_color_override("font_color", player_white)
			cell.add_theme_font_size_override("font_size", 26)
		
		@warning_ignore("integer_division")
		if ((r / 3) + (c / 3)) % 2 == 0:
			style.bg_color = Color("#5e3a8c")
		else:
			style.bg_color = Color("#1a2247")
			cell.add_theme_stylebox_override("normal", style)
			cell.add_theme_stylebox_override("hover", style)
			cell.add_theme_stylebox_override("pressed", style)
			
		cell.pressed.connect(_on_cell_pressed.bind(cell, r, c))
		grid_container.add_child(cell)

func is_legal(row, col, num):
	for i in range(9):
		if board[row][i] == num or board[i][col] == num:
			return false
	var start_row = (row / 3) * 3
	var start_col = (col / 3) * 3
	for r in range(start_row, start_row + 3):
		for c in range(start_col, start_col + 3):
			if board[r][c] == num: return false
	return true

func _on_cell_pressed(cell: Button, r: int, c: int):
	# If it's a blue clue, don't change it
	if cell.get_theme_color("font_color") == auto_pink:
		return
		
	var current = 0 if cell.text == "" else int(cell.text)
	var next_val = (current + 1) % 10
	cell.text = str(next_val) if next_val != 0 else ""
	cell.add_theme_font_size_override("font_size", 26)
	board[r][c] = next_val 

# We'll use a generic function name so you can link any button to it
func check_victory():
	var full = true
	for r in range(9):
		if 0 in board[r]: full = false
	
	if full:
		print("Checking board...")
		# If you have a Label named StatusLabel, it updates. If not, it just prints.
		if has_node("StatusLabel"):
			get_node("StatusLabel").text = "Victory! 🧠"
		print("YOU WON!")
	else:
		if has_node("StatusLabel"):
			get_node("StatusLabel").text = "Not full yet!"
		print("Keep filling it in!")
