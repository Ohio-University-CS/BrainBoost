#extends Node
#
#const SUPABASE_URL = "https://gdxmiqconbcloaewzkgb.supabase.co"
#const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdkeG1pcWNvbmJjbG9hZXd6a2diIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0MDc5MjcsImV4cCI6MjA5MDk4MzkyN30.Vr0WmUEGqHdrmTt2elKWXCKDP0hdm9BWJo_GuJc9M10"
#const SAVE_PATH = "user://session.cfg"
#
#var access_token = ""
#var user_id = ""
#var display_name = ""
#var is_logged_in = false
#
#signal login_success(user_data)
#signal login_failed(error)
#signal signup_success
#signal signup_failed(error)
#signal score_saved
#signal leaderboard_loaded(data)
#signal my_scores_loaded(data)  # NEW: so MainMenu can receive personal scores
#
## ─── Auth ───────────────────────────────────────────────
#
#func signup(email: String, password: String, username: String) -> void:
	#var url = SUPABASE_URL + "/auth/v1/signup"
	#var body = JSON.stringify({
		#"email": email,
		#"password": password,
		#"data": { "username": username }
	#})
	#var http = _make_request(url, HTTPClient.METHOD_POST, _base_headers(), body)
	#http.request_completed.connect(_on_signup_complete)
#
#func login(email: String, password: String) -> void:
	#var url = SUPABASE_URL + "/auth/v1/token?grant_type=password"
	#var body = JSON.stringify({
		#"email": email,
		#"password": password
	#})
	#var http = _make_request(url, HTTPClient.METHOD_POST, _base_headers(), body)
	#http.request_completed.connect(_on_login_complete)
#
#func logout() -> void:
	#access_token = ""
	#user_id = ""
	#display_name = ""
	#is_logged_in = false
	#clear_session()
#
## ─── Scores ─────────────────────────────────────────────
#
#func save_score(game_name: String, score: int) -> void:
	#var url = SUPABASE_URL + "/rest/v1/scores"
	#var body = JSON.stringify({
		#"user_id": user_id,
		#"game_name": game_name,
		#"score": score
	#})
	#var http = _make_request(url, HTTPClient.METHOD_POST, _write_headers(), body)
	#http.request_completed.connect(_on_score_saved)
#
#func get_leaderboard(game_name: String, limit: int = 10) -> void:
	#var url = SUPABASE_URL + \
		#"/rest/v1/scores?game_name=eq." + game_name + \
		#"&order=score.desc&limit=" + str(limit) + \
		#"&select=score,profiles(username,display_name)"
	#print("Leaderboard URL: ", url)
	#var http = _make_request(url, HTTPClient.METHOD_GET, _read_headers(), "")
	#http.request_completed.connect(_on_leaderboard_loaded)
#
#func get_my_scores() -> void:
	#var url = SUPABASE_URL + \
		#"/rest/v1/scores?user_id=eq." + user_id + \
		#"&order=played_at.desc&limit=20"
	#var http = _make_request(url, HTTPClient.METHOD_GET, _read_headers(), "")
	#http.request_completed.connect(_on_my_scores_loaded)
#
## ─── Callbacks ──────────────────────────────────────────
#
#func _on_signup_complete(_result, response_code, _headers, body):
	#var raw = body.get_string_from_utf8()
	#print("Signup code: ", response_code, " | body: ", raw)
	#var json = JSON.parse_string(raw)
	#if response_code == 200 or response_code == 201:
		#if json != null and json.has("access_token"):
			#access_token = json["access_token"]
			#user_id = json["user"]["id"]
			#display_name = json["user"]["user_metadata"].get("username", "Player")
			#is_logged_in = true
			#save_session()
			#emit_signal("login_success", json["user"])
		#else:
			#emit_signal("signup_success")
	#else:
		#var msg = "Signup failed"
		#if json != null:
			#msg = json.get("msg", json.get("message", msg))
		#emit_signal("signup_failed", msg)
#
#func _on_login_complete(_result, response_code, _headers, body):
	#var raw = body.get_string_from_utf8()
	#print("Login code: ", response_code, " | body: ", raw)
	#var json = JSON.parse_string(raw)
	#if response_code == 200:
		#access_token = json["access_token"]
		#user_id = json["user"]["id"]
		#display_name = json["user"]["user_metadata"].get("username", "Player")
		#is_logged_in = true
		#save_session()
		#emit_signal("login_success", json["user"])
	#else:
		#var msg = "Login failed"
		#if json != null:
			#msg = json.get("msg", json.get("message", msg))
		#emit_signal("login_failed", msg)
#
#func _on_score_saved(_result, response_code, _headers, _body):
	#if response_code == 201:
		#emit_signal("score_saved")
#
#func _on_leaderboard_loaded(_result, response_code, _headers, body):
	#var raw = body.get_string_from_utf8()
	#print("Leaderboard code: ", response_code, " | body: ", raw)
	#if response_code == 200:
		#var json = JSON.parse_string(raw)
		#if json == null:
			#print("Leaderboard JSON parse failed")
			#return
		#print("Leaderboard parsed entries: ", json.size())
		#emit_signal("leaderboard_loaded", json)
	#else:
		#print("Leaderboard request failed with code: ", response_code)
#
#func _on_my_scores_loaded(_result, response_code, _headers, body):
	#var raw = body.get_string_from_utf8()
	#print("My scores code: ", response_code, " | body: ", raw)
	#if response_code == 200:
		#var json = JSON.parse_string(raw)
		#if json == null:
			#print("My scores JSON parse failed")
			#return
		#emit_signal("my_scores_loaded", json)  # NEW: emit instead of just printing
#
## ─── Session ────────────────────────────────────────────
#
#func save_session() -> void:
	#var config = ConfigFile.new()
	#config.set_value("auth", "access_token", access_token)
	#config.set_value("auth", "user_id", user_id)
	#config.set_value("auth", "display_name", display_name)
	#config.save(SAVE_PATH)
#
#func load_session() -> bool:
	#var config = ConfigFile.new()
	#if config.load(SAVE_PATH) != OK:
		#return false
	#access_token = config.get_value("auth", "access_token", "")
	#user_id = config.get_value("auth", "user_id", "")
	#display_name = config.get_value("auth", "display_name", "")
	#if access_token != "":
		#is_logged_in = true
		#return true
	#return false
#
#func clear_session() -> void:
	#DirAccess.remove_absolute(SAVE_PATH)
#
## ─── Helpers ────────────────────────────────────────────
#
#func _base_headers() -> PackedStringArray:
	#return PackedStringArray([
		#"Content-Type: application/json",
		#"apikey: " + SUPABASE_ANON_KEY
	#])
#
#func _read_headers() -> PackedStringArray:
	#return PackedStringArray([
		#"Content-Type: application/json",
		#"apikey: " + SUPABASE_ANON_KEY,
		#"Authorization: Bearer " + access_token
	#])
#
#func _write_headers() -> PackedStringArray:
	#return PackedStringArray([
		#"Content-Type: application/json",
		#"apikey: " + SUPABASE_ANON_KEY,
		#"Authorization: Bearer " + access_token,
		#"Prefer: return=minimal"
	#])
#
#func _make_request(url: String, method: int, headers: PackedStringArray, body: String) -> HTTPRequest:
	#var http = HTTPRequest.new()
	#add_child(http)
	#http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free(), CONNECT_ONE_SHOT)
	#http.request(url, headers, method, body)
	#return http
	
extends Node

const SUPABASE_URL = "https://gdxmiqconbcloaewzkgb.supabase.co"
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdkeG1pcWNvbmJjbG9hZXd6a2diIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0MDc5MjcsImV4cCI6MjA5MDk4MzkyN30.Vr0WmUEGqHdrmTt2elKWXCKDP0hdm9BWJo_GuJc9M10"
const SAVE_PATH = "user://session.cfg"

var access_token = ""
var user_id = ""
var display_name = ""
var is_logged_in = false

signal login_success(user_data)
signal login_failed(error)
signal signup_success
signal signup_failed(error)
signal score_saved
signal leaderboard_loaded(data)
signal my_scores_loaded(data)

# ─── Auth ───────────────────────────────────────────────

func signup(email: String, password: String, username: String) -> void:
	var url = SUPABASE_URL + "/auth/v1/signup"
	var body = JSON.stringify({
		"email": email,
		"password": password,
		"data": { "username": username, "display_name": username }
	})
	print(body)
	var http = _make_request(url, HTTPClient.METHOD_POST, _base_headers(), body)
	print(http)
	http.request_completed.connect(_on_signup_complete)

func login(email: String, password: String) -> void:
	var url = SUPABASE_URL + "/auth/v1/token?grant_type=password"
	var body = JSON.stringify({
		"email": email,
		"password": password
	})
	var http = _make_request(url, HTTPClient.METHOD_POST, _base_headers(), body)
	http.request_completed.connect(_on_login_complete)

func logout() -> void:
	access_token = ""
	user_id = ""
	display_name = ""
	is_logged_in = false
	clear_session()

# ─── Scores ─────────────────────────────────────────────

func save_score(game_name: String, score: int) -> void:
	var url = SUPABASE_URL + "/rest/v1/scores"
	var body = JSON.stringify({
		"user_id": user_id,
		"game_name": game_name,
		"score": score
	})
	var http = _make_request(url, HTTPClient.METHOD_POST, _write_headers(), body)
	http.request_completed.connect(_on_score_saved)

# Fetches all scores with display name from profiles via FK join
func get_leaderboard() -> void:
	# Join profiles via user_id directly on profiles.id
	var url = SUPABASE_URL + \
		"/rest/v1/scores?order=score.desc" + \
		"&select=score,game_name,profiles(username,display_name)"
	print("Leaderboard URL: ", url)
	var http = _make_request(url, HTTPClient.METHOD_GET, _read_headers(), "")
	http.request_completed.connect(_on_leaderboard_loaded)

func get_my_scores() -> void:
	var url = SUPABASE_URL + \
		"/rest/v1/scores?user_id=eq." + user_id + \
		"&order=played_at.desc&limit=20"
	var http = _make_request(url, HTTPClient.METHOD_GET, _read_headers(), "")
	http.request_completed.connect(_on_my_scores_loaded)

# ─── Callbacks ──────────────────────────────────────────

func _on_signup_complete(_result, response_code, _headers, body):
	var raw = body.get_string_from_utf8()
	print("Signup code: ", response_code, " | body: ", raw)
	var json = JSON.parse_string(raw)
	if response_code == 200 or response_code == 201:
		if json != null and json.has("access_token"):
			access_token = json["access_token"]
			user_id = json["user"]["id"]
			display_name = json["user"]["user_metadata"].get("username", "Player")
			is_logged_in = true
			save_session()
			emit_signal("login_success", json["user"])
		else:
			emit_signal("signup_success")
	else:
		var msg = "Signup failed"
		if json != null:
			msg = json.get("msg", json.get("message", msg))
		emit_signal("signup_failed", msg)

func _on_login_complete(_result, response_code, _headers, body):
	var raw = body.get_string_from_utf8()
	#print("Login code: ", response_code, " | body: ", raw)
	var json = JSON.parse_string(raw)
	if response_code == 200:
		access_token = json["access_token"]
		user_id = json["user"]["id"]
		display_name = json["user"]["user_metadata"].get("username", "Player")
		is_logged_in = true
		save_session()
		emit_signal("login_success", json["user"])
	else:
		var msg = "Login failed"
		if json != null:
			msg = json.get("msg", json.get("message", msg))
		emit_signal("login_failed", msg)

func _on_score_saved(_result, response_code, _headers, _body):
	if response_code == 201:
		emit_signal("score_saved")

func _on_leaderboard_loaded(_result, response_code, _headers, body):
	var raw = body.get_string_from_utf8()
	print("Leaderboard code: ", response_code, " | body: ", raw)
	if response_code == 200:
		var json = JSON.parse_string(raw)
		if json == null:
			print("Leaderboard JSON parse failed")
			return
		print("Leaderboard parsed entries: ", json.size())
		emit_signal("leaderboard_loaded", json)
	else:
		print("Leaderboard request failed with code: ", response_code)

func _on_my_scores_loaded(_result, response_code, _headers, body):
	var raw = body.get_string_from_utf8()
	print("My scores code: ", response_code)
	if response_code == 200:
		var json = JSON.parse_string(raw)
		if json == null:
			print("My scores JSON parse failed")
			return
		emit_signal("my_scores_loaded", json)

# ─── Session ────────────────────────────────────────────

func save_session() -> void:
	var config = ConfigFile.new()
	config.set_value("auth", "access_token", access_token)
	config.set_value("auth", "user_id", user_id)
	config.set_value("auth", "display_name", display_name)
	config.save(SAVE_PATH)

func load_session() -> bool:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	access_token = config.get_value("auth", "access_token", "")
	user_id = config.get_value("auth", "user_id", "")
	display_name = config.get_value("auth", "display_name", "")
	if access_token != "":
		is_logged_in = true
		return true
	return false

func clear_session() -> void:
	DirAccess.remove_absolute(SAVE_PATH)

# ─── Helpers ────────────────────────────────────────────

func _base_headers() -> PackedStringArray:
	return PackedStringArray([
		"Content-Type: application/json",
		"apikey: " + SUPABASE_ANON_KEY
	])

func _read_headers() -> PackedStringArray:
	return PackedStringArray([
		"Content-Type: application/json",
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + access_token
	])

func _write_headers() -> PackedStringArray:
	return PackedStringArray([
		"Content-Type: application/json",
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + access_token,
		"Prefer: return=minimal"
	])

func _make_request(url: String, method: int, headers: PackedStringArray, body: String) -> HTTPRequest:
	var http = HTTPRequest.new()
	add_child(http)
	http.request(url, headers, method, body)
	return http
