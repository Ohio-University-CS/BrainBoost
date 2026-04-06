extends Control

func _on_login_failed(error):
	print(error)

func _on_login_success(_user_data):
	AcountManager.save_session()
	get_tree().change_scene_to_file("res://Scenes/home_menu.tscn")

func _on_signup_success():
	# Either auto-login or show success message
	print("Account created! You can now log in.")
	
func _on_signup_failed(error):
	print(error)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AcountManager.login_success.connect(_on_login_success)
	AcountManager.login_failed.connect(_on_login_failed)
	#AcountManager.signup_success.connect(_on_signup_success)
	#AcountManager.signup_failed.connect(_on_signup_failed)
	#AcountManager.signup("jpTheBest@gmail.com", "password123", "John Pork")
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


#func _on_margin_container_2_gui_input(event: InputEvent) -> void:
	#pass
	#print("!")
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#var email = $ColorRect/Email.text
		#var password = $ColorRect/Password.text
		#print(email)
		#print(password)
		#
		#AcountManager.signup("adamghose@gmail.com", "password", "gamerboy07")
		#AcountManager.login(email, password)


func _on_button_button_up() -> void:
	print("!")
	var email = $ColorRect/Email.text.strip_edges()
	var password = $ColorRect/Password.text
	#var username = "gamerboy07"
	print(email)
	print(password)
	#AcountManager.signup(email, password, username)
	AcountManager.login(email, password)
	get_tree().change_scene_to_file("res://Scenes/home_menu.tscn")
	#$"Popup Wrapper/Stats/GlobalList"
	#$"Popup Wrapper/Stats/PersonalList"
func _exit_tree():
	AcountManager.login_success.disconnect(_on_login_success)
	AcountManager.login_failed.disconnect(_on_login_failed)
	#AcountManager.signup_success.disconnect(_on_signup_success)
	#AcountManager.signup_failed.disconnect(_on_signup_failed)





func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/singUp.tscn")
