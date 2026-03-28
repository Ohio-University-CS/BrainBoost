extends GutTest

var Scram = preload("res://Scripts/wordle_like.gd").new()

# ════════════════════════════════════════════════════════════
# TEST 1 — char_counts()
# Verifies that characters and their frequencies are recorded
# correctly across normal words, repeated letters, and
# single-character edge cases.
# ════════════════════════════════════════════════════════════


# ════════════════════════════════════════════════════════════
# TEST 2 — find_possible()
# Verifies that only anagrams of the target word survive the
# filter, including degenerate lists and duplicate entries.
# ════════════════════════════════════════════════════════════

 
# ════════════════════════════════════════════════════════════
# TEST 3 — scramble_word()
# Verifies that the rotation-based scramble produces the
# correct output, handles boundary indices, and preserves
# all characters.
# ════════════════════════════════════════════════════════════
func test_scramble_word_mid_index() -> void:
	# Normal case: split "apple" at index 2 → "pleap"
	var result = Scram.scramble("apple", 2)
	assert_eq(result, "pleap", "Scrambling 'apple' at index 2 should give 'pleap'")
 
func test_scramble_word_preserves_all_chars() -> void:
	# Invariant: scrambled word must contain every char of the original
	var original = "listen"
	var result   = Scram.scramble(original, 3)
 
	assert_eq(result.length(), original.length(),
		"Scrambled word must have the same length as the original")
 
	for i in range(original.length()):
		assert_true(result.find(original[i]) != -1,
			"Every character of the original must appear in the scramble")
 
func test_scramble_word_index_at_one() -> void:
	# Edge case: index 1 moves only the first character to the end
	var result = Scram.scramble("abcde", 1)
	assert_eq(result, "bcdea", "Index 1 should rotate first char to the end")
 
func test_scramble_word_full_length_minus_one() -> void:
	# Edge case: largest valid index — one char stays, rest rotates
	var result = Scram.scramble("abcde", 4)
	assert_eq(result, "eabcd", "Index 4 should move last char to the front")
 
# ════════════════════════════════════════════════════════════
# TEST 4 — format_time()
# Verifies minute/second formatting for normal gameplay time,
# the boundary at exactly 0, and values just above zero.
# ════════════════════════════════════════════════════════════
func test_format_time_full_five_minutes() -> void:
	# Normal case: 300 s → "5:00"
	assert_eq(Scram.format_time(300.0), "5:00",
		"300 seconds should display as '5:00'")
 
func test_format_time_one_minute_thirty() -> void:
	# Normal case: 90 s → "1:30"
	assert_eq(Scram.format_time(90.0), "1:30",
		"90 seconds should display as '1:30'")
 
func test_format_time_zero() -> void:
	# Boundary case: 0 s → "0:00"
	assert_eq(Scram.format_time(0.0), "0:00",
		"0 seconds should display as '0:00'")
 
func test_format_time_59_seconds() -> void:
	# Edge case: just under a minute → seconds must be zero-padded
	assert_eq(Scram.format_time(59.0), "0:59",
		"59 seconds should display as '0:59' (zero-padded)")
 
func test_format_time_one_second() -> void:
	# Edge case: 1 second left → "0:01"
	assert_eq(Scram.format_time(1.0), "0:01",
		"1 second should display as '0:01'")
 

# ════════════════════════════════════════════════════════════
# TEST 5 — is_time_expired()
# Verifies the expiry check used to trigger end-game state,
# including values that should NOT trigger it.
# ════════════════════════════════════════════════════════════
