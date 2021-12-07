tool
extends MarginContainer

class_name CommandOptionLine

export (NodePath) var DisplayView
export (NodePath) var DeleteView

export (NodePath) var OptionTypeBtn
export (NodePath) var OptionNameInput
export (NodePath) var OptionDefaultInput
export (NodePath) var OptionDeleteBtn

export (NodePath) var ConfirmLbl
export (NodePath) var YesBtn
export (NodePath) var NoBtn

signal option_line_deleted(obj)

# ---------------------------------------------------------

var optionTypes = [
	{text='N', hint='No Value', value=st.OPTTYPE_NOVALUE},
	{text='A', hint='Accept Value', value=st.OPTTYPE_ACCEPTVALUE},
	{text='R', hint='Require Value', value=st.OPTTYPE_REQUIREVALUE},
]
var optionTypeIndex = -1

func update_option_type(index: int = -1):
	if index < 0: optionTypeIndex += 1
	else: optionTypeIndex = index

	if optionTypeIndex == len(optionTypes):
		optionTypeIndex = 0

	var ot = optionTypes[optionTypeIndex]

	optionTypeBtn.text = ot.text
	optionTypeBtn.hint_tooltip = ot.hint
	optionDefaultInput.visible = (ot.value == st.OPTTYPE_ACCEPTVALUE)

	if ot.value == st.OPTTYPE_NOVALUE:
		if _command != null:
			ste.remove_option(_command.namespace_id, _command.get_name(), _current_name)
	else: ste.add_option(_command.namespace_id, _command.get_name(), _current_name)

func get_data():
	return {
		type = optionTypes[optionTypeIndex].value,
		name = _current_name,
		default = optionDefaultInput.value
	}

func set_from_data(data: Dictionary):
	for i in range(len(optionTypes)):
		if optionTypes[i].value == data.type:
			optionTypeIndex = i
			break

	optionDefaultInput.value = float(data.default)
	update_option_type(optionTypeIndex)
	_update_option_data(str(data.name))


func delete_option():
	get_parent().remove_child(self)
	emit_signal('option_line_deleted', self)

	if optionTypes[optionTypeIndex].value != st.OPTTYPE_NOVALUE:
		ste.remove_option(_command.namespace_id, _command.get_name(), _current_name)
	queue_free()

# ---------------------------------------------------------

var displayView
var deleteView

var optionTypeBtn: Button
var optionNameInput: LineEdit
var optionDefaultInput: SpinBox

var _command
var _current_name = ''

var mainEditor

var _index: int = -1
func update_index(): _index = get_index()

func _ready():
	displayView = get_node(DisplayView)
	deleteView = get_node(DeleteView)
	_switch_view(1)

	optionTypeBtn = (get_node(OptionTypeBtn) as Button)
	optionNameInput = (get_node(OptionNameInput) as LineEdit)
	optionDefaultInput = (get_node(OptionDefaultInput) as SpinBox)

	optionTypeBtn.connect('pressed', self, 'update_option_type')
	(get_node(OptionDeleteBtn) as Button).connect('pressed', self, '_switch_view', [2])
	(get_node(YesBtn) as Button).connect('pressed', self, 'delete_option')
	(get_node(NoBtn) as Button).connect('pressed', self, '_switch_view', [1])

	optionNameInput.connect('focus_exited', self, '_update_option_data')

	update_option_type()

func _update_option_data(name: String = ""):
	if name.empty(): name = optionNameInput.text
	name = ste.str_to_key(name)

	var last_caret_pos = optionNameInput.caret_position
	optionNameInput.text = name
	optionNameInput.caret_position = last_caret_pos

	if name == _current_name: return

	ste.remove_option(_command.namespace_id, _command.get_name(), _current_name)
	if optionTypes[optionTypeIndex].value != st.OPTTYPE_NOVALUE:
		ste.add_option(_command.namespace_id, _command.get_name(), name)

	_current_name = name
	mainEditor._storyList_set_modified("update option name to '" + _current_name + "' (command: " + _command.get_name() + ")")

func _switch_view(id: int):
	displayView.visible = (id == 1)
	deleteView.visible = (id == 2)

	if (id == 2):
		(get_node(ConfirmLbl) as Label).text = 'delete \'' + optionNameInput.text + '\'?'
