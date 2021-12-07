tool
extends Node

var namespaces = []
var locks = []
var values = []

var options = []
var inputs = []

# ---------------------------------------------------------

func add_data(type: int, name: String, ini_val, editable := true):
	name = name.strip_edges()

	var target
	match(type):
		st.TYPE_NAMESPACE: target = namespaces
		st.TYPE_LOCK: target = locks
		st.TYPE_VALUE: target = values
		st.TYPE_OPTION: target = options
		st.TYPE_INPUT: target = inputs

	if (target == null) or not _valid_name(name, target): return -1

	var id = get_last_id(type) + 1

	target.append({
		id = id,
		type = type,
		name = name,
		ini_val = _fix_value(type, ini_val),

		editable = editable
	})

	return id

func delete_data(type: int, id: int):
	var target
	match(type):
		st.TYPE_NAMESPACE: target = namespaces
		st.TYPE_LOCK: target = locks
		st.TYPE_VALUE: target = values
		st.TYPE_OPTION: target = options
		st.TYPE_INPUT: target = inputs

	if (target == null): return

	for i in range(len(target)):
		if target[i].id == id:
			target.remove(i)
			break

func rename_data(type: int, id: int, name: String, force_edit := false):
	name = name.strip_edges()

	var target
	match(type):
		st.TYPE_NAMESPACE: target = namespaces
		st.TYPE_LOCK: target = locks
		st.TYPE_VALUE: target = values
		st.TYPE_OPTION: target = options
		st.TYPE_INPUT: target = inputs

	if (target == null) or not _valid_name(name, target): return

	for i in range(len(target)):
		if target[i].id == id:
			if target[i].editable or force_edit:
				target[i].name = name
			break

func set_ini_val(type: int, id: int, ini_val, force_edit := false):
	ini_val = _fix_value(type, ini_val)

	var target
	match(type):
		st.TYPE_NAMESPACE: target = namespaces
		st.TYPE_LOCK: target = locks
		st.TYPE_VALUE: target = values
		st.TYPE_OPTION: target = options
		st.TYPE_INPUT: target = inputs

	for i in range(len(target)):
		if target[i].id == id:
			if target[i].editable or force_edit:
				target[i].ini_val = ini_val
			break

func get_data(type: int, id: int):
	var target
	var tmp = {id=id, name='', ini_val=st.StoryInterpreter.get_default_value(type)}
	match(type):
		st.TYPE_NAMESPACE: target = namespaces
		st.TYPE_LOCK: target = locks
		st.TYPE_VALUE: target = values
		st.TYPE_OPTION: target = options
		st.TYPE_INPUT: target = inputs

	for i in range(len(target)):
		if target[i].id == id:
			tmp = target[i].duplicate()
			break

	return tmp

func get_last_id(type: int):
	var target
	match(type):
		st.TYPE_NAMESPACE: target = namespaces
		st.TYPE_LOCK: target = locks
		st.TYPE_VALUE: target = values
		st.TYPE_OPTION: target = options
		st.TYPE_INPUT: target = inputs

	if (target == null) or (len(target) == 0): return -1

	var last_id = -1
	for data in target:
		if data.id > last_id:
			last_id = data.id

	return last_id


func add_option(ns_id: int, cmd: String, option: String):
	if cmd.empty() or option.empty(): return

	var ns = get_data(st.TYPE_NAMESPACE, ns_id).name
	if ns.empty(): return

	add_data(st.TYPE_OPTION, st.StoryListener.option_to_value(ns, cmd, option), -1, false)

func remove_option(ns_id: int, cmd: String, option: String):
	var ns = get_data(st.TYPE_NAMESPACE, ns_id).name
	if ns.empty(): return

	var id = -1
	var name = st.StoryListener.option_to_value(ns, cmd, option)
	for opt in options:
		if opt.name == name:
			id = opt.id
			break

	if id != -1: delete_data(st.TYPE_OPTION, id)

func remove_options(ns_id: int, cmd: String = ''):
	var ns = get_data(st.TYPE_NAMESPACE, ns_id).name
	if ns.empty(): return

	var filter = st.StoryListener.option_to_value(ns, cmd, '')
	for opt in options:
		if opt.name.begins_with(filter):
			options.erase(opt)



func fix_default_ns():
	for ns in namespaces:
		if ns.name == st.NAMESPACE_DEFAULT:
			ns.editable = false
			ns.ini_val = true
			return

	add_data(st.TYPE_NAMESPACE, st.NAMESPACE_DEFAULT, true, false)

func clear_data():
	namespaces = []
	locks = []
	values = []

	options = []
	inputs = []

	fix_default_ns()

func get_operators(type: int, fortest: bool = false, extra = null):
	var operinput = []

	match(type):
		st.TYPE_LOCK, st.TYPE_NAMESPACE:
			operinput.append({ name='is (=)', value=(st.StoryLock.OPERATOR_IS if fortest else st.StoryLock.OPERATOR_SET) })
			if st.TYPE_LOCK:
				if fortest: operinput.append({ name='is not (!=)', value=st.StoryLock.OPERATOR_ISN })
				else: operinput.append({ name='toggle (!)', value=st.StoryLock.OPERATOR_TGL })
		st.TYPE_VALUE, st.TYPE_OPTION, st.TYPE_INPUT:
			operinput.append({ name='equals (=)', value=(st.StoryValue.OPERATOR_EQ if fortest else st.StoryValue.OPERATOR_SET) })

			if not fortest:
				operinput.append({ name='add (+)', value=st.StoryValue.OPERATOR_ADD })
				operinput.append({ name='multiply by (*)', value=st.StoryValue.OPERATOR_MULT })
			else:
				operinput.append({ name='is not (!=)', value=st.StoryValue.OPERATOR_NEQ })
				operinput.append({ name='is less than (<)', value=st.StoryValue.OPERATOR_LT })
				operinput.append({ name='is less than or equals (<=)', value=st.StoryValue.OPERATOR_LTE })
				operinput.append({ name='is greater than (>)', value=st.StoryValue.OPERATOR_GT })
				operinput.append({ name='is greater than or equals (>=)', value=st.StoryValue.OPERATOR_GTE })

	return operinput

func str_to_key(what):
	what = what.replace(' ', '_')
	return what

func type_to_str(type: int):
	match(type):
		st.TYPE_NAMESPACE: return "namespace"
		st.TYPE_LOCK: return "lock"
		st.TYPE_VALUE: return "value"
		st.TYPE_OPTION: return "option"
		st.TYPE_INPUT: return "input"

# ---------------------------------------------------------

var selection_mode_types = []
func set_selection_mode_types(namespace := false, lock := false, value := false):
	selection_mode_types.clear()
	if namespace: selection_mode_types.append(st.TYPE_NAMESPACE)
	if lock: selection_mode_types.append(st.TYPE_LOCK)
	if value:
		selection_mode_types.append(st.TYPE_VALUE)
		selection_mode_types.append(st.TYPE_OPTION)
		selection_mode_types.append(st.TYPE_INPUT)

var uniq_name_tree = UniqNameTree.new(['res://'], '/')

# ---------------------------------------------------------

func _ready():
	clear_data()

func _valid_name(name: String, target: Array):
	if (name == null) or (name == ''): return false

	for data in target:
		if data.name == name:
			return false

	return true

func _fix_value(type: int, ini_val):
	if type in [st.TYPE_VALUE, st.TYPE_OPTION]:
		if not (ini_val is float): ini_val = 0
	elif type in [st.TYPE_LOCK, st.TYPE_NAMESPACE]:
		if not (ini_val is bool): ini_val = false

	return ini_val
