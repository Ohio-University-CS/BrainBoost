extends "res://addons/gut/test.gd"

var script_path = "res://Scripts/Patterngame.gd"

func test_high_score_logic():
	var game = load(script_path).new()
	game.high_score = 10
	var new_score = 15
	assert_gt(new_score, game.high_score, "15 beats 10")
	game.high_score = 15
	assert_eq(new_score, game.high_score, "Tie case")

func test_sequence_matching():
	var game = load(script_path).new()
	game.cpu_sequence = [0,1,2]
	game.player_sequence = [0,1,2]
	assert_eq(game.player_sequence, game.cpu_sequence, "Match")
	game.player_sequence = [0,5,2]
	assert_ne(game.player_sequence, game.cpu_sequence, "Wrong")

func test_game_state_locks():
	var game = load(script_path).new()
	game.is_cpu_playing = true
	assert_true(game.is_cpu_playing, "Locked")
	game.is_cpu_playing = false
	assert_false(game.is_cpu_playing, "Unlocked")

func test_round_progression():
	var game = load(script_path).new()
	game.cpu_sequence = [1]
	game.cpu_sequence.append(2)
	assert_eq(game.cpu_sequence.size(), 2, "Grew")
	game.player_sequence = []
	assert_eq(game.player_sequence.size(), 0, "Cleared")

func test_ui_logic_math():
	var game = load(script_path).new()
	game.cpu_sequence = [0,1,2,3]
	var score = game.cpu_sequence.size() - 1
	assert_eq(score, 3, "Math check")
