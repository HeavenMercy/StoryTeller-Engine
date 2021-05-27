tool
extends Node

const TYPE_NAMESPACE = 0
const TYPE_LOCK = 1
const TYPE_VALUE = 2

var namespaces = []
var locks = []
var values = []

var selection_mode: bool = false


func add_data(type: int, name: String, ini_val):
	name = name.strip_edges()
	if not _valid_name(type, name): return

	var target
	match(type):
		TYPE_NAMESPACE: target = namespaces
		TYPE_LOCK: target = locks
		TYPE_VALUE: target = values

	if target == null: return

	var id = 0
	if len(target) > 0: id = target.back().id + 1

	if type == TYPE_VALUE:
		if not ini_val is float: ini_val = 0
	elif not ini_val is bool: ini_val = false

	target.append({id = id, name = name})
	set_ini_val(type, id, ini_val)
	return id

func delete_data(type: int, id: int):
	if (type == TYPE_NAMESPACE) \
	and id == 0: return

	var target
	match(type):
		TYPE_NAMESPACE: target = namespaces
		TYPE_LOCK: target = locks
		TYPE_VALUE: target = values

	for i in range(len(target)):
		if target[i].id == id:
			target.remove(i)
			break

func rename_data(type: int, id: int, name: String):
	name = name.strip_edges()
	if not _valid_name(type, name): return

	var target
	match(type):
		TYPE_NAMESPACE: target = namespaces
		TYPE_LOCK: target = locks
		TYPE_VALUE: target = values

	for i in range(len(target)):
		if target[i].id == id:
			target[i].name = name
			break

func set_ini_val(type: int, id: int, ini_val):
	if type == TYPE_VALUE:
		if not ini_val is float: ini_val = 0
	elif not ini_val is bool: ini_val = false
		
	var target
	match(type):
		TYPE_NAMESPACE: target = namespaces
		TYPE_LOCK: target = locks
		TYPE_VALUE: target = values

	for i in range(len(target)):
		if target[i].id == id:
			target[i].ini_val = ini_val
			break
			
func get_data(type: int, id: int):
	var target
	var tmp = {id=-1, name="", ini_val=(0 if type == TYPE_VALUE else false)}
	match(type):
		TYPE_NAMESPACE: target = namespaces
		TYPE_LOCK: target = locks
		TYPE_VALUE: target = values

	for i in range(len(target)):
		if target[i].id == id:
			tmp = target[i].duplicate()
			break


	tmp.type = type
	return tmp

func get_last_id(type: int):
	var target
	match(type):
		TYPE_NAMESPACE: target = namespaces
		TYPE_LOCK: target = locks
		TYPE_VALUE: target = values

	if target == null: return -1

	var id = 0
	if len(target) > 0: id = target.back().id
	return id


func clear_data(choice = -1):
	namespaces = []
	locks = []
	values = []
	
	add_data(TYPE_NAMESPACE, "default", true)

func get_operators(type: int, fortest: bool = false):
	var operinput = []

	operinput.append("is")

	match(type):
		TYPE_LOCK:
			if not fortest: operinput.append("toggle")
		TYPE_VALUE:
			if not fortest:
				operinput.append("add")
				operinput.append("multiply by")
			else:
				operinput.append("is not")
				operinput.append("is less than")
				operinput.append("is less than or equals")
				operinput.append("is greater than")
				operinput.append("is greater than or equals")

	return operinput

# ---------------------------------------------------------

func _ready():
	add_data(TYPE_NAMESPACE, "default", true)

func _valid_name(type: int, name: String):
	if (name == null) or (name == ""): return false

	match(type):
		TYPE_NAMESPACE: return not namespaces.has(name)
		TYPE_LOCK: return not locks.has(name)
		TYPE_VALUE: return not values.has(name)

