extends Node

var graph: Dictionary = {}

func _ready():
	_load_graph()

func _load_graph() -> void:
	var f = FileAccess.open("res://compound_words.json", FileAccess.READ)
	if not f: return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Dictionary: return
	for letter in data.keys():
		for compound in data[letter]:
			var parts = compound.split(" ")
			if parts.size() != 2: continue
			if not graph.has(parts[0]): graph[parts[0]] = []
			if not graph[parts[0]].has(parts[1]):
				graph[parts[0]].append(parts[1])

# Returns just the chain array e.g. ["fire", "side", "walk", "out"]
# or [] if no chain found
func generate_puzzle(start_word: String, chain_length: int = 4) -> Array:
	var results: Array = []
	_dfs(start_word, [start_word], {}, chain_length, results)
	if results.is_empty(): return []
	results.sort_custom(func(a, b): return _score(b) < _score(a))
	return results[0]

func is_valid_pair(a: String, b: String) -> bool:
	return graph.get(a, []).has(b)

func _dfs(word: String, path: Array, visited: Dictionary, target: int, results: Array) -> void:
	if path.size() == target + 1:
		results.append(path.duplicate())
		return
	for nb in graph.get(word, []):
		if not visited.has(nb):
			visited[nb] = true
			path.append(nb)
			_dfs(nb, path, visited, target, results)
			path.pop_back()
			visited.erase(nb)

func _score(chain: Array) -> int:
	var s = 0
	for w in chain.slice(0, -1):
		s += graph.get(w, []).size()
	return s
