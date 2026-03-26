extends Node

var graph: Dictionary = {}


func _ready():
	_load_path()

# ── Offline fallback ─────────────────────────────────────────────

func _load_path():
	var path = "res://compound_words.json"
	if not FileAccess.file_exists(path):
		return

	var f = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()

	if not data is Dictionary:
		return

	# 🔥 NEW: iterate letter groups
	for letter in data.keys():
		var word_list: Array = data[letter]

		for compound in word_list:
			var parts = compound.split(" ")
			if parts.size() != 2:
				continue

			var a: String = parts[0]
			var b: String = parts[1]

			if not graph.has(a):
				graph[a] = []

			if not graph[a].has(b):
				graph[a].append(b)

func generate_puzzle(start_word: String, chain_length: int = 4) -> Dictionary:
	

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
