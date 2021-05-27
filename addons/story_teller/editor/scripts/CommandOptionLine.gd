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
	{text="N", hint="No Value", value=st.StoryCommand.OPTTYPE_NOVALUE},
	{text="A", hint="Accept Value", value=st.StoryCommand.OPTTYPE_ACCEPTVALUE},
	{text="R", hint="Require Value", value=st.StoryCommand.OPTTYPE_REQUIREVALUE},
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
	optionDefaultInput.visible = (ot.value == st.StoryCommand.OPTTYPE_ACCEPTVALUE)

func get_data():
	return {
		type = optionTypes[optionTypeIndex].value,
		name = optionNameInput.text,
		default = optionDefaultInput.value
	}

func set_from_data(data: Dictionary):
	for i in range(len(optionTypes)):
		if optionTypes[i].value == data.type:
			optionTypeIndex = i

	optionNameInput.text = str(data.name)
	optionDefaultInput.value = float(data.default)
	update_option_type(optionTypeIndex)

func delete_option():
	get_parent().remove_child(self)
	emit_signal("option_line_deleted", self)
	queue_free()

# ---------------------------------------------------------

var displayView
var deleteView

var optionTypeBtn: Button
var optionNameInput: LineEdit
var optionDefaultInput: SpinBox

var _index: int = -1

func _ready():
	_index = get_index()

	displayView = get_node(DisplayView)
	deleteView = get_node(DeleteView)
	_switch_view(1)

	optionTypeBtn = (get_node(OptionTypeBtn) as Button)
	optionNameInput = (get_node(OptionNameInput) as LineEdit)
	optionDefaultInput = (get_node(OptionDefaultInput) as SpinBox)

	optionTypeBtn.connect("pressed", self, "update_option_type")
	(get_node(OptionDeleteBtn) as Button).connect("pressed", self, "_switch_view", [2])
	(get_node(YesBtn) as Button).connect("pressed", self, "delete_option")
	(get_node(NoBtn) as Button).connect("pressed", self, "_switch_view", [1])

	update_option_type()

func _switch_view(id: int):
	displayView.visible = (id == 1)
	deleteView.visible = (id == 2)

	if (id == 2):
		(get_node(ConfirmLbl) as Label).text = "delete \"" + optionNameInput.text + "\"?"
