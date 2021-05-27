tool
extends WindowDialog

export (NodePath) var TargetView
export (NodePath) var OperatorInput
export (NodePath) var ValueInput
export (NodePath) var StateInput
export (NodePath) var SaveBtn

signal select_data
signal data_save_request(data)

# ---------------------------------------------------------------------------

var _fortest: bool = false
var _data: Dictionary = {
	target = {type = -1, id = -1},
	operator = -1,
	value = null
}


func on_target_selected(target: Dictionary = {}):
	if target.get("type", -1) == -1 \
	or target.get("id", -1) == -1: return false

	_data.target = target.duplicate(true)
	set_trgtview(_data.target)

	match(_data.target.type):
		0:
			stateinput.visible = true
			valueinput.visible = false
		1:
			stateinput.visible = false
			valueinput.visible = false
		2:
			stateinput.visible = false
			valueinput.visible = true

	update_operator(target.type)
	if _data.has("operator"):
		operinput.selected = int(min(
			_data.operator, operinput.get_item_count()-1))

	return true


func open(title: String, fortest: bool = false, data: Dictionary = {}):
	_fortest = fortest
	window_title = title

	_data.value = data.get("value", 0)
	_data.operator = data.get("operator", 0)

	if not data.has("target") or not (data.target is Dictionary) \
	or not on_target_selected(data.target):
		trgtview.text = "[click to select]"
		stateinput.visible = false
		valueinput.visible = false
		operinput.clear()
	elif _data.has("value"):
		match(_data.target.type):
			0: stateinput.selected = int(_data.value)
			1: stateinput.selected = (1 if _data.value else 0)
			2: valueinput.value = _data.value

	is_open = true

func close():
	is_open = false
	visible = false


func update_operator(type: int):
	operinput.clear()
	for oper in stedb.get_operators(type, _fortest):
		operinput.add_item(oper)

func save_data():
	_data.operator = operinput.selected

	if _data.target.id != -1:
		match(_data.target.type):
			stedb.TYPE_NAMESPACE: _data.value = stateinput.selected
			stedb.TYPE_LOCK: _data.value = (stateinput.selected == 1)
			stedb.TYPE_VALUE: _data.value = valueinput.value

		emit_signal("data_save_request", _data)
		close()

func request_select_data():
	emit_signal("select_data")

# ---------------------------------------------------------------------------

var is_open = false

var trgtview: Button
var valueinput: SpinBox
var stateinput: OptionButton
var operinput: OptionButton

func _ready():
	trgtview = (get_node(TargetView) as Button)
	valueinput = (get_node(ValueInput) as SpinBox)
	stateinput = (get_node(StateInput) as OptionButton)
	operinput = (get_node(OperatorInput) as OptionButton)

	get_close_button().connect("pressed", self, "close")
	trgtview.connect("pressed", self, "request_select_data")
	(get_node(SaveBtn) as Button).connect("pressed", self, "save_data")

#	stedb.add_data(stedb.TYPE_VALUE, "myvar")
#	open("Edit Update!", false, {target = {type = stedb.TYPE_VALUE, id = 0}, operator = 1, value = 7})


func _physics_process(delta):
	if is_open and not visible:
		call_deferred("popup")

	if visible:
		if _data.has("target") and _data.target.has("type") \
		and (_data.target.type == stedb.TYPE_LOCK):
			stateinput.visible = not (operinput.selected == 1)

func set_trgtview(target: Dictionary = {}):
	if not target.has("type"): return

	match(target.type):
		stedb.TYPE_NAMESPACE: trgtview.text = "namespace: "
		stedb.TYPE_LOCK: trgtview.text = "lock: "
		stedb.TYPE_VALUE: trgtview.text = "value: "

	trgtview.text += stedb.get_data(target.type, target.id).name
