extends Node

@onready var http_neighbors = $HTTP
@onready var http_pos       = $HTTPPos

var graph: Dictionary = {}
var _pending_neighbor_word: String = ""
var _pending_pos_word: String = ""
var _use_offline: bool = false
var _pos_cache: Dictionary = {}

func _ready():
	http_neighbors.request_completed.connect(_on_neighbors_completed)
	http_pos.request_completed.connect(_on_pos_completed)
	_load_offline_fallback()

# ── Offline fallback ─────────────────────────────────────────────

func _load_offline_fallback():
	var path = "res://data/word_chain/compound_words.json"
	if not FileAccess.file_exists(path): return
	var f = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Dictionary: return
	for pair in data.get("pairs", []):
		var a: String = pair[0]
		var b: String = pair[1]
		if not graph.has(a): graph[a] = []
		if not graph[a].has(b): graph[a].append(b)

# ── Public API ───────────────────────────────────────────────────

func generate_puzzle(start_word: String, chain_length: int = 4) -> Dictionary:
	await _prefetch_chain(start_word, chain_length)

	var all_chains: Array = []
	_dfs(start_word, [start_word], {}, chain_length, all_chains)

	if all_chains.is_empty(): return {}

	all_chains.sort_custom(func(a, b): return _score(b) < _score(a))
	var best: Array = all_chains[0]

	var tiles: Array = best.slice(1)
	tiles.append_array(_red_herrings(best, 2))
	tiles.shuffle()

	return {
		"start":       best[0],
		"tiles":       tiles,
		"solution":    best.slice(1),
		"valid_pairs": _pairs(best)
	}

func is_valid_pair(a: String, b: String) -> bool:
	return graph.get(a, []).has(b)

# ── Fetching ─────────────────────────────────────────────────────

func _prefetch_chain(word: String, depth: int):
	if depth == 0 or _use_offline: return
	await _fetch_neighbors(word)
	for neighbor in graph.get(word, []):
		await _prefetch_chain(neighbor, depth - 1)

func _fetch_neighbors(word: String):
	if graph.has(word): return
	_pending_neighbor_word = word
	var url = "https://api.datamuse.com/words?rel_bga=%s&max=20&md=p" \
		% word.uri_encode()
	var err = http_neighbors.request(url)
	if err != OK:
		graph[word] = graph.get(word, [])
		_use_offline = true
		return
	await http_neighbors.request_completed

func _on_neighbors_completed(
		_result: int,
		response_code: int,
		_headers: PackedStringArray,
		body: PackedByteArray):

	if response_code != 200:
		if not graph.has(_pending_neighbor_word):
			graph[_pending_neighbor_word] = []
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	var candidates: Array = []

	if json is Array:
		for entry in json:
			var w: String = entry.get("word", "")
			var tags: Array = entry.get("tags", [])

			var has_function_tag = (
				tags.has("conj") or
				tags.has("prep") or
				tags.has("det")  or
				tags.has("pron") or
				tags.has("u")
			)

			if has_function_tag:
				continue

			var is_noun_or_verb = tags.has("n") or tags.has("v")

			if w != "" and " " not in w \
					and w.length() >= 3 \
					and is_noun_or_verb:
				candidates.append(w)

	var confirmed: Array = graph.get(_pending_neighbor_word, []).duplicate()
	for candidate in candidates:
		if await _confirm_pos(candidate):
			if not confirmed.has(candidate):
				confirmed.append(candidate)

	graph[_pending_neighbor_word] = confirmed

# ── POS validation ───────────────────────────────────────────────

func _confirm_pos(word: String) -> bool:
	if _pos_cache.has(word):
		return _pos_cache[word]

	_pending_pos_word = word
	var url = "https://api.datamuse.com/words?sp=%s&md=p&max=1" \
		% word.uri_encode()
	var err = http_pos.request(url)
	if err != OK:
		_pos_cache[word] = false
		return false
	await http_pos.request_completed
	return _pos_cache.get(word, false)

func _on_pos_completed(
		_result: int,
		response_code: int,
		_headers: PackedStringArray,
		body: PackedByteArray):

	if response_code != 200:
		_pos_cache[_pending_pos_word] = false
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	var confirmed = false

	if json is Array and json.size() > 0:
		var tags: Array = json[0].get("tags", [])

		var has_function_tag = (
			tags.has("conj") or
			tags.has("prep") or
			tags.has("det")  or
			tags.has("pron") or
			tags.has("u")
		)

		if not has_function_tag:
			confirmed = tags.has("n") or tags.has("v")

	_pos_cache[_pending_pos_word] = confirmed

# ── Graph search ─────────────────────────────────────────────────

func _dfs(word: String, path: Array, visited: Dictionary,
		target_len: int, results: Array):
	if path.size() == target_len + 1:
		results.append(path.duplicate())
		return
	for nb in graph.get(word, []):
		if not visited.has(nb):
			path.append(nb)
			visited[nb] = true
			_dfs(nb, path, visited, target_len, results)
			path.pop_back()
			visited.erase(nb)

func _score(chain: Array) -> int:
	var s = 0
	for w in chain.slice(0, -1):
		s += graph.get(w, []).size()
	return s

func _red_herrings(chain: Array, count: int) -> Array:
	var cs = {}
	for w in chain: cs[w] = true
	var decoys: Array = []
	for w in chain:
		for nb in graph.get(w, []):
			if not cs.has(nb) and not decoys.has(nb):
				decoys.append(nb)
	decoys.shuffle()
	return decoys.slice(0, count)

func _pairs(chain: Array) -> Array:
	var p: Array = []
	for i in range(chain.size() - 1):
		p.append([chain[i], chain[i + 1]])
	return p
