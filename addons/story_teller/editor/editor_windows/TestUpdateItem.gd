tool
extends MarginContainer

class_name TestUpdateItem

export (NodePath) var DisplayView
export (NodePath) var DeleteView

export (NodePath) var Prefix
export (NodePath) var AtLine

export (NodePath) var HintLabel
export (NodePath) var EditButton
export (NodePath) var DeleteButton

export (NodePath) var ConfirmLbl
export (NodePath) var YesBtn
export (NodePath) var NoBtn

signal data_edit_request(target)

signal data_deleted(index)

# ---------------------------------------------------------------------------

var _fortest = false
var _data: Dictionary = {
	at = st.UPDATE_ATEND,
	target = {type = -1, id = -1},
	operator = st.StoryData.OPERATOR_NONE,
	value = { type = 0, content = 0 }
}


func update_data(newdata: Dictionary):
	_data.target = newdata.target.duplicate()
	_data.operator = newdata.operator
	_data.value = newdata.value.duplicate()

	set_line(newdata.get('at', st.UPDATE_ATEND))

	var name = ste.get_data(_data.target.type, _data.target.id).name
	if name.empty():
		queue_free()
		return

	var oper = 'NONE'
	for op in ste.get_operators(_data.target.type, _fortest):
		if op.value == _data.operator:
			oper = op.name
			break

	var value = 0
	if _data.value.type == st.VALUETYPE_TARGET:
		value = '{' + ste.get_data(_data.value.content.type, _data.value.content.id).name + '}'
	elif _data.value.type == st.VALUETYPE_VALUE:
		match(newdata.target.type):
			st.TYPE_NAMESPACE: value = ('ENABLED' if _data.value.content else 'DISABLED')
			st.TYPE_LOCK: value = ('ON' if _data.value.content else 'OFF')
			st.TYPE_VALUE, st.TYPE_OPTION, st.TYPE_INPUT: value = str(_data.value.content)

	var text = ''
	match(newdata.target.type):
		st.TYPE_NAMESPACE: text += 'namespace {' + name + '}: ' + oper + ' ' + value
		st.TYPE_LOCK:
			text += 'lock {' + name + '}: ' + oper
			if _data.operator != st.StoryLock.OPERATOR_TGL:
				text += ' ' + value
		st.TYPE_VALUE: text += 'value {' + name + '}: ' + oper + ' ' + value
		st.TYPE_OPTION: text += 'option {' + name + '}: ' + oper + ' ' + value
		st.TYPE_INPUT: text += 'input {' + name + '}: ' + oper + ' ' + value

	(get_node(HintLabel) as Label).text = text


func request_data_edit(): emit_signal('data_edit_request', self)

func delete_data():
	emit_signal('data_deleted', get_index())
	queue_free()

func set_fortest(fortest):
	_fortest = fortest

	prefix.visible = _fortest
	atLine.visible = not _fortest

	if not _fortest:
		atLine.connect('item_selected', self, '_on_line_selected')
	elif atLine.is_connected('item_selected', self, '_on_line_selected'):
		atLine.disconnect('item_selected', self, '_on_line_selected')


func get_prefix(): return prefix.text

func set_prefix(_prefix: String):
	prefix.text = _prefix

func set_line(line: int):
	var idx = 0
	var length = atLine.get_item_count()

	while idx < length:
		if atLine.get_item_metadata(idx) == line:
			atLine.selected = idx
			_data.at = line
			break
		idx += 1

	atLine.selected = 0 if (length == 1) else -1
	_data.at = st.UPDATE_ATEND

func update_lines(line_count: int):
	if line_count < 0: return

	var tmp = _data.at
	if tmp == null: tmp = st.UPDATE_ATEND

	atLine.clear()
	atLine.set_tooltip(
		"at line x: before line's text is displayed" + "\n" +
		"at End: at the end of the chunk, once all text is displayed")

	var value = 0
	while value < line_count:
		atLine.add_item('at line ' + str(value + 1))
		atLine.set_item_metadata(value, value)
		value += 1

	atLine.add_item('at End')
	atLine.set_item_metadata(value, st.UPDATE_ATEND)

	set_line(tmp)

# ---------------------------------------------------------------------------

var displayView
var deleteView

var prefix
var atLine

func _ready():
	displayView = get_node(DisplayView)
	deleteView = get_node(DeleteView)

	prefix = (get_node(Prefix) as Label)
	atLine = (get_node(AtLine) as OptionButton)

	_switch_view(1)

	(get_node(EditButton) as Button).connect('pressed', self, 'request_data_edit')
	(get_node(DeleteButton) as Button).connect('pressed', self, '_switch_view', [2])

	(get_node(ConfirmLbl) as Label).text = 'delete ' + ('condition' if _fortest else 'update') + '\'?'
	(get_node(YesBtn) as Button).connect('pressed', self, 'delete_data')
	(get_node(NoBtn) as Button).connect('pressed', self, '_switch_view', [1])

#	_fortest = false
#	set_prefix('')
#	ste.add(st.TYPE_VALUE, 'myvar')
#	update_data({target = {type = st.TYPE_VALUE, id = 0}, operator = 2, value = 15})

func _switch_view(id: int):
	displayView.visible = (id == 1)
	deleteView.visible = (id == 2)

func _on_line_selected(idx: int):
	_data.at = atLine.get_item_metadata(idx)
