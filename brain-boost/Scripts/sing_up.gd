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
	AcountManager.signup_success.connect(_on_signup_success)
	AcountManager.signup_failed.connect(_on_signup_failed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass



func _on_button_button_up() -> void:
	print("!")
	var email = $ColorRect/Email.text.strip_edges()
	var password = $ColorRect/Password.text
	var username = $ColorRect/Username.text.strip_edges()
	print(email)
	print(password)
	AcountManager.signup(email, password, username)
	get_tree().change_scene_to_file("res://Scenes/home_menu.tscn")

func _exit_tree():
	AcountManager.signup_success.disconnect(_on_signup_success)
	AcountManager.signup_failed.disconnect(_on_signup_failed)
