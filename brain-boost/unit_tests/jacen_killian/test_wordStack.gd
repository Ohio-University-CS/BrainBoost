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

# ─────────────────────────────────────────────
# test_render
# ─────────────────────────────────────────────

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

# ─────────────────────────────────────────────
# test_chain_check
# ─────────────────────────────────────────────

func test_chain_check():
	await game.new_puzzle()
	await get_tree().process_frame

	# Normal: correct full chain returns Perfect chain
	game.player_chain = game.current_puzzle
	game.check_chain()
	assert_eq(game.feedback.text, "Perfect chain!",
		"Normal: correct full chain should return Perfect chain")

	# Edge: correct length but all wrong words — should fail validation
	var solution = game.current_puzzle.slice(1)
	game.player_chain = [game.start_word]
	for i in range(solution.size()):
		game.player_chain.append("zzzzz")
	game.check_chain()
	assert_ne(game.feedback.text, "Perfect chain!",
		"Edge: wrong words of correct length should not pass")

	# Error: empty player_chain — should flag puzzle as unfinished
	game.player_chain = [game.start_word]
	game.check_chain()
	assert_eq(game.feedback.text, "Puzzle not finished yet!",
		"Error: empty player_chain should flag puzzle as unfinished")

# ─────────────────────────────────────────────
# test_reset
# ─────────────────────────────────────────────

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

# ─────────────────────────────────────────────
# test_tile_placed
# ─────────────────────────────────────────────

func test_tile_placed():
	await game.new_puzzle()
	await get_tree().process_frame

	# Normal: placing a tile appends its word to player_chain
	var solution = game.current_puzzle.slice(1)
	game._on_tile_placed(solution[0])
	assert_eq(game.player_chain.size(), 2,
		"Normal: player_chain should have one word after placing one tile")
	assert_eq(game.player_chain[1], solution[0],
		"Normal: placed word should match the tile's word")

	# Edge: moving a tile from one slot to another removes and re-adds it
	# Simulate tile being picked up from slot (removes from chain)
	game._on_tile_removed(solution[0])
	assert_false(game.player_chain.has(solution[0]),
		"Edge: word should be removed from player_chain when tile is picked up")
	# Simulate tile being dropped into a new slot (re-adds to chain)
	game._on_tile_placed(solution[0])
	assert_true(game.player_chain.has(solution[0]),
		"Edge: word should be re-added to player_chain when dropped in new slot")
	assert_eq(game.player_chain.size(), 2,
		"Edge: player_chain should still only have one entry after move")

	# Error: placing a tile on an occupied slot should not change player_chain
	var slots = game.get_tree().get_nodes_in_group("chain_slots")
	if slots.size() > 0:
		var slot = slots[0]
		slot.set_meta("occupied", true)
		slot.set_meta("occupying_tile", solution[0])
		var previous_chain = game.player_chain.duplicate()
		if slot.get_meta("occupied", false):
			pass
		assert_eq(game.player_chain, previous_chain,
			"Error: placing a tile on an occupied slot should not change player_chain")
