# collects long (like paths) and returns the shortest uniq name possible
class_name UniqNameTree


var _name_tree := {}
var _excluded_parts = []
var _separator = '/'


# creates a the tree:
# - sets parts of the registered data to exclude
# - sets the data separator (for a path: [code]/[/code])
func _init(excluded_parts := [], separator := '/'):
	_separator = separator
	for part in excluded_parts:
		if part is String:
			_excluded_parts.append(part)

func _get_parts_inverted(name):
	for part in _excluded_parts:
		name = name.replace(part, '')

	var parts = name.split(_separator)
	parts.invert()
	return parts


# register the name in the process for uniq name
func register_name(name: String):
	var name_parts = _get_parts_inverted(name)

	var head = _name_tree
	for part in name_parts:
		if not head.has(part): head[part] = {}
		head = head[part]


# unregister the name from the process for uniq name
func unregister_name(name: String):
	var name_parts = _get_parts_inverted(name)

	var head = _name_tree
	for part in name_parts:
		if not head.has(part): break
		if len(head[part]) < 2:
			head.erase(part)
			break
		head = head[part]


# returns the uniq name related to the given name
func get_uniqname(name):
	var _name = ''
	var name_parts = _get_parts_inverted(name)

	var head = _name_tree
	for part in name_parts:
		_name = part + (_separator if len(_name) > 0 else '') + _name
		if not head.has(part) or (len(head[part]) < 2): break
		head = head[part]

	return _name
