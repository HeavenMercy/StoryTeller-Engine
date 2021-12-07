tool
extends WindowDialog

export (NodePath) var TargetView
export (NodePath) var TargetValueView
export (NodePath) var OperatorInput
export (NodePath) var ValueType
export (NodePath) var ValueInput
export (NodePath) var StateInput
export (NodePath) var SaveBtn

signal select_data(specific_type)
signal data_save_request(data)

# ---------------------------------------------------------------------------

var _fortest: bool = false
var _data: Dictionary

func on_target_selected(target: Dictionary = {}):
	var done = false
	if target.get('type', -1) != -1:
		set_trgtview(target, _for_target)
		done = true
		if _for_target:
			_data.value.content = target.duplicate(true)
		else:
			_data.target = target.duplicate(true)

			valuetype.clear()
			valuetype.add_item('Value', st.VALUETYPE_VALUE)
			if target.type != st.TYPE_NAMESPACE:
				valuetype.add_item('Target', st.VALUETYPE_TARGET)

			operinput.clear()
			var i = 0
			for oper in ste.get_operators(target.type, _fortest, target.ini_val):
				operinput.add_item(oper.name, oper.value)
				if oper.value == -1: # fix -1 as default value
					operinput.set_item_id(i, oper.value)
				i += 1

			on_valuetype_selected( valuetype.get_item_index(_data.value.type) )
			on_operinput_selected( operinput.get_item_index(_data.operator) )

	return done

func on_operinput_selected(idx):
	operinput.selected = idx
	valuetype.visible = true

	if _data.target.type in [st.TYPE_NAMESPACE, st.TYPE_LOCK]:
		var hide = (operinput.get_selected_id() == st.StoryLock.OPERATOR_TGL)

		valuetype.visible = not hide
		stateinput.visible = not hide

func on_valuetype_selected(idx, preserve_value := false):
	if idx == -1: idx = 0

	var newtype = valuetype.get_item_id(idx)
	if _data.value.type == newtype: preserve_value = true

	valuetype.selected = idx
	_data.value.type = newtype
	if _data.value.type == st.VALUETYPE_TARGET:
		if not preserve_value:
			_data.value.content = {}
			trgtvalueview.text = '[click to select a target]'

		stateinput.visible = false
		valueinput.visible = false
		trgtvalueview.visible = true
	else:
		trgtvalueview.visible = false
		match(_data.target.type):
			st.TYPE_LOCK, st.TYPE_NAMESPACE:
				if not preserve_value:
					_data.value.content = 0
					stateinput.selected = _data.value.content
				stateinput.visible = true
				valueinput.visible = false
			st.TYPE_VALUE, st.TYPE_OPTION, st.TYPE_INPUT:
				if not preserve_value:
					_data.value.content = 0
					valueinput.value = _data.value.content
				stateinput.visible = false
				valueinput.visible = true

func open(title: String, fortest: bool = false, data: Dictionary = {}):
	_data = data.duplicate(true)
	_fortest = fortest
	window_title = title

	if not on_target_selected(data.target):
		trgtview.text = '[click to select a target]'
		stateinput.visible = false
		valueinput.visible = false
		operinput.clear()

	if data.value.type == st.VALUETYPE_TARGET:
		_for_target = true
		if not on_target_selected(data.value.content):
			trgtvalueview.text = '[click to select a target]'
	elif data.value.type == st.VALUETYPE_VALUE:
		match(data.target.type):
			st.TYPE_NAMESPACE, st.TYPE_LOCK: stateinput.selected = (1 if data.value.content else 0)
			st.TYPE_VALUE, st.TYPE_OPTION, st.TYPE_INPUT: valueinput.value = data.value.content

	is_open = true

func close():
	is_open = false
	visible = false


func save_data():
	if _data.target.type != -1:
		_data.operator = operinput.get_selected_id()

		_data.value.type = valuetype.get_selected_id()

		if _data.value.type == st.VALUETYPE_VALUE:
			match(_data.target.type):
				st.TYPE_NAMESPACE, st.TYPE_LOCK: _data.value.content = bool(stateinput.selected)
				st.TYPE_VALUE, st.TYPE_OPTION, st.TYPE_INPUT: _data.value.content = float(valueinput.value)

		emit_signal('data_save_request', _data)
		close()

func request_select_data(_for_target := false):
	self._for_target = _for_target
	emit_signal('select_data', (_data.target.type if _for_target else -1))

# ---------------------------------------------------------------------------

var is_open := false
var _for_target := false

var trgtview: Button
var trgtvalueview: Button

var valueinput: SpinBox
var stateinput: OptionButton
var operinput: OptionButton
var valuetype: OptionButton

func _ready():
	trgtview = (get_node(TargetView) as Button)
	trgtvalueview = (get_node(TargetValueView) as Button)
	valueinput = (get_node(ValueInput) as SpinBox)
	stateinput = (get_node(StateInput) as OptionButton)
	operinput = (get_node(OperatorInput) as OptionButton)
	valuetype = (get_node(ValueType) as OptionButton)

	get_close_button().connect('pressed', self, 'close')
	trgtview.connect('pressed', self, 'request_select_data')
	trgtvalueview.connect('pressed', self, 'request_select_data', [true])
	operinput.connect('item_selected', self, 'on_operinput_selected')
	valuetype.connect('item_selected', self, 'on_valuetype_selected')
	(get_node(SaveBtn) as Button).connect('pressed', self, 'save_data')

#	ste.add_data(st.TYPE_VALUE, 'myvar')
#	open('Edit Update!', false, {target = {type = st.TYPE_VALUE, id = 0}, operator = 1, value = 7})


func _physics_process(delta):
	if is_open and not visible:
		call_deferred('popup')

func set_trgtview(target: Dictionary = {}, _for_target := false):
	if target.get('type', -1) == -1: return

	var _target
	if _for_target: _target = trgtvalueview
	else: _target = trgtview

	_for_target = false

	_target.text = ''
	match(target.type):
		st.TYPE_NAMESPACE: _target.text = 'namespace: '
		st.TYPE_LOCK: _target.text = 'lock: '
		st.TYPE_VALUE: _target.text = 'value: '
		st.TYPE_OPTION: _target.text = 'option: '
		st.TYPE_INPUT: _target.text = 'input: '

	_target.text += ste.get_data(target.type, target.id).name
