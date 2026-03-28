extends GutTest

var Scram = preload("res://Scripts/wordle_like.gd").new()

# ════════════════════════════════════════════════════════════
# TEST 1 — char_counts()
# Verifies that characters and their frequencies are recorded
# correctly across normal words, repeated letters, and
# single-character edge cases.
# ════════════════════════════════════════════════════════════
func test_char_counts_normal_word() -> void:
	# Normal case: "hello" has h×1, e×1, l×2, o×1
	var chars := []
	var counts := []
	Scram.char_counts("hello", chars, counts)
 
	assert_eq(chars.size(), 4,    "Should find 4 unique characters in 'hello'")
	var l_idx := chars.find("l")
	assert_ne(l_idx, -1,          "'l' must be present in chars")
	assert_eq(counts[l_idx], 2,   "'l' should appear twice in 'hello'")
	var h_idx := chars.find("h")
	assert_eq(counts[h_idx], 1,   "'h' should appear once in 'hello'")
 
func test_char_counts_all_same_letters() -> void:
	# Edge case: every character is identical → one unique char, count = word length
	var chars := []
	var counts := []
	Scram.char_counts("aaaa", chars, counts)
 
	assert_eq(chars.size(), 1,    "Only 1 unique character in 'aaaa'")
	assert_eq(chars[0], "a",      "That character should be 'a'")
	assert_eq(counts[0], 4,       "'a' should be counted 4 times")
 
func test_char_counts_single_character() -> void:
	# Edge case: single-letter word
	var chars := []
	var counts := []
	Scram.char_counts("z", chars, counts)
 
	assert_eq(chars.size(), 1,    "Single-char word produces 1 unique char")
	assert_eq(counts[0], 1,       "Count for that char should be 1")
 
func test_char_counts_empty_string() -> void:
	# Error / boundary case: empty string → no chars, no counts
	var chars := []
	var counts := []
	Scram.char_counts("", chars, counts)
 
	assert_eq(chars.size(), 0,    "Empty string should produce no unique chars")
	assert_eq(counts.size(), 0,   "Empty string should produce no counts")

# ════════════════════════════════════════════════════════════
# TEST 2 — find_possible()
# Verifies that only anagrams of the target word survive the
# filter, including degenerate lists and duplicate entries.
# ════════════════════════════════════════════════════════════
func test_find_possible_returns_anagrams_only() -> void:
	# Normal case: "listen" anagrams include "enlist", "tinsel", "silent"
	var target_chars := []
	var target_counts := []
	Scram.char_counts("listen", target_chars, target_counts)
 
	var pool = ["enlist", "tinsel", "silent", "hello", "world", "listed"]
	var result = Scram.find_possible(pool, target_chars, target_counts)
 
	assert_true(result.has("enlist"),  "'enlist' is an anagram of 'listen'")
	assert_true(result.has("tinsel"),  "'tinsel' is an anagram of 'listen'")
	assert_true(result.has("silent"),  "'silent' is an anagram of 'listen'")
	assert_false(result.has("hello"),  "'hello' is NOT an anagram of 'listen'")
	assert_false(result.has("listed"), "'listed' has different chars than 'listen'")
 
func test_find_possible_empty_pool() -> void:
	# Edge case: empty candidate list → result must also be empty
	var target_chars := []
	var target_counts := []
	Scram.char_counts("apple", target_chars, target_counts)
 
	var result = Scram.find_possible([], target_chars, target_counts)
	assert_eq(result.size(), 0, "Empty pool should return empty result")
 
func test_find_possible_no_matching_anagrams() -> void:
	# Error case: no word in the pool is an anagram → empty result
	var target_chars := []
	var target_counts := []
	Scram.char_counts("xyz", target_chars, target_counts)
 
	var pool = ["abc", "def", "ghi", "hello"]
	var result = Scram.find_possible(pool, target_chars, target_counts)
	assert_eq(result.size(), 0, "No anagrams should produce an empty result")
 
func test_find_possible_exact_match_included() -> void:
	# Edge case: the target word itself is in the pool → must be returned
	var target_chars = []
	var target_counts = []
	Scram.char_counts("earth", target_chars, target_counts)
 
	var pool = ["earth", "heart", "ocean"]
	var result = Scram.find_possible(pool, target_chars, target_counts)
 
	assert_true(result.has("earth"), "The word itself should be a valid answer")
	assert_true(result.has("heart"), "'heart' is an anagram of 'earth'")
	assert_false(result.has("ocean"), "'ocean' is not an anagram of 'earth'")
 
# ════════════════════════════════════════════════════════════
# TEST 3 — scramble_word()
# Verifies that the rotation-based scramble produces the
# correct output, handles boundary indices, and preserves
# all characters.
# ════════════════════════════════════════════════════════════
func test_scramble_word_mid_index() -> void:
	# Normal case: split "apple" at index 2 → "pleap"
	Scram.scrambles = 1
	var result = Scram.scramble("apple", 2)
	assert_eq(result, "pleap", "Scrambling 'apple' at index 2 should give 'pleap'")
 
func test_scramble_word_preserves_all_chars() -> void:
	# Invariant: scrambled word must contain every char of the original
	var original = "listen"
	var result   = Scram.scramble(original)
 
	assert_eq(result.length(), original.length(),
		"Scrambled word must have the same length as the original")
 
	for i in range(original.length()):
		assert_true(result.find(original[i]) != -1,
			"Every character of the original must appear in the scramble")
 
func test_scramble_word_index_at_one() -> void:
	# Edge case: index 1 moves only the first character to the end
	Scram.scrambles = 1
	var result = Scram.scramble("abcde", 1)
	assert_eq(result, "bcdea", "Index 1 should rotate first char to the end")
 
func test_scramble_word_full_length_minus_one() -> void:
	# Edge case: largest valid index — one char stays, rest rotates
	Scram.scrambles = 1
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
