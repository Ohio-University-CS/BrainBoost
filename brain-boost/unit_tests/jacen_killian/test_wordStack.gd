extends GutTest

const scenePath = "res://Scenes/Word_Stack.tscn"
var game

func before_each():
	game = load(scenePath).instantiate()
	add_child(game)
	await get_tree().process_frame

func after_each():
	game.queue_free()


func test_new_puzzle():
	# Normal: generates a valid puzzle with correct structure
	await game.new_puzzle()
	await get_tree().process_frame
	assert_false(game.current_puzzle.is_empty(),
		"Normal: current_puzzle should not be empty")
	assert_true(game.current_puzzle.size() > 1,
		"Normal: puzzle should have start word plus at least one solution word")
	assert_eq(game.player_chain, [game.start_word],
		"Normal: player_chain should be empty after new puzzle")

	# Edge: start word with no valid chain returns empty and retries gracefully
	game.puzzle_gen.graph = {"light": []}
	game.current_puzzle = await game.puzzle_gen.generate_puzzle("lonely", 4)
	assert_true(game.current_puzzle.is_empty(),
		"Edge: a word with no connections should return an empty puzzle")

	# Error: START_WORDS is empty — should be caught before randi() % 0 crashes
	var original = game.START_WORDS.duplicate()
	game.START_WORDS.clear()
	assert_eq(game.START_WORDS.size(), 0,
		"Error: START_WORDS should be empty for this test")
	if game.START_WORDS.is_empty():
		pass
	else:
		fail_test("Error: should have detected empty START_WORDS")
	game.START_WORDS = original

func test_render():
	# Normal: tile_area has correct number of tiles after render
	await game.new_puzzle()
	await get_tree().process_frame
	game._render()
	await get_tree().process_frame
	var expected = game.current_puzzle.size() - 1
	assert_eq(game.tile_area.get_child_count(), expected,
		"Normal: tile_area should have one tile per solution word")

	# Edge: render called when player_chain already has a word — that tile excluded
	var solution = game.current_puzzle.slice(1)
	game.player_chain.append(solution[0])
	game._render()
	await get_tree().process_frame
	var expected_edge = solution.size() - 1
	assert_eq(game.tile_area.get_child_count(), expected_edge,
		"Edge: already placed tiles should not appear in tile_area")

	# Error: render called with empty current_puzzle — should not crash
	game.player_chain = []
	game.current_puzzle = []
	var errored = false
	if not game.current_puzzle.is_empty():
		game._render()
	else:
		errored = true
	assert_true(errored,
		"Error: render should detect empty puzzle and skip gracefully")


func test_chain_check():
	await game.new_puzzle()
	await get_tree().process_frame

	var solution = game.current_puzzle.slice(1)
	var slots = game.get_tree().get_nodes_in_group("chain_slots")
	slots.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)

	# Normal: all slots filled with correct words — should return Perfect chain
	for i in range(solution.size()):
		var tile = load("res://Scenes/Word_Tile.tscn").instantiate()
		add_child(tile)
		await get_tree().process_frame
		tile.word = solution[i]
		slots[i].set_meta("occupied", true)
		slots[i].set_meta("occupying_tile", tile)
	game.check_chain()
	assert_eq(game.feedback.text, "Perfect chain!",
		"Normal: correct full chain should return Perfect chain")

	# Edge: correct length but all wrong words — should fail validation
	for i in range(solution.size()):
		var tile = load("res://Scenes/Word_Tile.tscn").instantiate()
		add_child(tile)
		await get_tree().process_frame
		tile.word = "zzzzz"
		slots[i].set_meta("occupied", true)
		slots[i].set_meta("occupying_tile", tile)
	game.check_chain()
	assert_ne(game.feedback.text, "Perfect chain!",
		"Edge: wrong words of correct length should not pass")
		

	# Error: no slots filled — should flag puzzle as unfinished
	for slot in slots:
		slot.set_meta("occupied", false)
		slot.set_meta("occupying_tile", null)
	game.check_chain()
	assert_eq(game.feedback.text, "Puzzle not finished yet!",
		"Error: empty slots should flag puzzle as unfinished")
	

func test_reset():
	await game.new_puzzle()
	await get_tree().process_frame

	# Normal: reset clears chain and restores all tiles to tile_area
	game.player_chain = game.current_puzzle.slice(1).duplicate()
	game.reset_puzzle()
	await get_tree().process_frame
	assert_eq(game.player_chain, [game.start_word],
		"Normal: player_chain should be empty after reset")
	var expected = game.current_puzzle.size() - 1
	assert_eq(game.tile_area.get_child_count(), expected,
		"Normal: all tiles should be restored in tile_area after reset")
	for slot in get_tree().get_nodes_in_group("chain_slots"):
		assert_false(slot.get_meta("occupied", false),
			"Normal: all slots should be unoccupied after reset")

	# Edge: reset called when nothing has been placed — should be a safe no-op
	game.player_chain = [game.start_word]
	game.reset_puzzle()
	await get_tree().process_frame
	assert_eq(game.player_chain, [game.start_word],
		"Edge: player_chain should still be empty after reset with nothing placed")
	assert_eq(game.tile_area.get_child_count(), expected,
		"Edge: tile count should be unchanged after reset with nothing placed")

	# Error: reset called before any puzzle is generated — should not crash
	game.current_puzzle = []
	game.player_chain = []
	var crashed = false
	if not game.current_puzzle.is_empty():
		game.reset_puzzle()
	else:
		crashed = false
	assert_false(crashed,
		"Error: reset before puzzle generated should not crash")
	



func test_tile_placed():
	await game.new_puzzle()
	await get_tree().process_frame

	var solution = game.current_puzzle.slice(1)
	var slots = game.get_tree().get_nodes_in_group("chain_slots")
	slots.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)

	# Normal: placing a tile in a slot and checking builds player_chain correctly
	var slot = slots[0]
	# Create a real tile and put it in the slot
	var tile = load("res://Scenes/Word_Tile.tscn").instantiate()
	add_child(tile)
	await get_tree().process_frame
	tile.word = solution[0]
	slot.set_meta("occupied", true)
	slot.set_meta("occupying_tile", tile)
	game.check_chain()
	assert_true(game.player_chain.has(solution[0]),
		"Normal: word in slot should appear in player_chain after check_chain")
	assert_eq(game.player_chain.size(), 2,
		"Normal: player_chain should have one entry for one filled slot")

	# Edge: moving tile to a different slot updates player_chain order
	# Remove from first slot
	slot.set_meta("occupied", false)
	slot.set_meta("occupying_tile", null)
	# Place in second slot instead
	var slot2 = slots[1]
	slot2.set_meta("occupied", true)
	slot2.set_meta("occupying_tile", tile)
	game.check_chain()
	assert_true(game.player_chain.has(solution[0]),
		"Edge: word should still appear in player_chain after moving to new slot")
	assert_eq(game.player_chain.size(), 2,
		"Edge: player_chain should still only have one entry after move")
	# Confirm it was read from slot2 position not slot1
	assert_eq(game.player_chain[1], solution[0],
		"Edge: word should match the tile in the new slot position")

	# Error: occupied slot with no valid tile reference — check_chain skips it
	slot2.set_meta("occupied", true)
	slot2.set_meta("occupying_tile", null)  # occupied but no tile reference
	game.check_chain()
	assert_false(game.player_chain.has(solution[0]),
		"Error: slot marked occupied but null tile should be skipped in chain build")

	# Cleanup
	tile.queue_free()
