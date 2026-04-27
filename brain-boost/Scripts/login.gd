extends Control

@onready var status = $Status
@onready var passwrd = $ColorRect/Password

var email:String
var password:String

func _on_login_failed(error):
	print(error)
	status.text = "Login Failed"
	$"ColorRect/MarginContainer2/Login In".disabled = false
	$"ColorRect/MarginContainer3/Sign Up".disabled = false
	$ColorRect/Password.text = ""
	

func _on_login_success(_user_data):
	AcountManager.save_session()
	get_tree().change_scene_to_file("res://Scenes/home_menu.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AcountManager.login_success.connect(_on_login_success)
	AcountManager.login_failed.connect(_on_login_failed)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _exit_tree():
	AcountManager.login_success.disconnect(_on_login_success)
	AcountManager.login_failed.disconnect(_on_login_failed)





func _on_sign_up_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/singUp.tscn")


func _on_login_in_button_up() -> void:
	print("!")
	status.text = "Validating..." 
	var email = $ColorRect/Email.text.strip_edges()
	var password = $ColorRect/Password.text
	$"ColorRect/MarginContainer2/Login In".disabled = true
	$"ColorRect/MarginContainer3/Sign Up".disabled = true
	AcountManager.login(email, password)


func _on_home_button_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/home_menu.tscn")
