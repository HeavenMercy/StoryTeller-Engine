tool
extends MarginContainer

class_name StoryChoiceLine

export (NodePath) var DisplayView
export (NodePath) var DeleteView

export (NodePath) var ChoiceNameInput
export (NodePath) var ChoiceDescriptionInput
export (NodePath) var OptionDeleteBtn

export (NodePath) var ConfirmLbl
export (NodePath) var YesBtn
export (NodePath) var NoBtn

signal choice_line_deleted(obj)

# ---------------------------------------------------------

func get_data():
	return {
		name = choiceNameInput.text,
		description = choiceDescriptionInput.text
	}

func set_from_data(data: Dictionary):
	choiceNameInput.text = str(data.name)
	choiceDescriptionInput.text = str(data.description)

func delete_option():
	get_parent().remove_child(self)
	emit_signal("choice_line_deleted", self)
	queue_free()

# ---------------------------------------------------------

var displayView
var deleteView

var choiceNameInput: LineEdit
var choiceDescriptionInput: LineEdit

var _index: int = -1 setget _set_index
func _set_index(val: int):
	_index = val - 3

func _ready():
	_set_index(get_index())

	displayView = get_node(DisplayView)
	deleteView = get_node(DeleteView)
	_switch_view(1)

	choiceNameInput = (get_node(ChoiceNameInput) as LineEdit)
	choiceDescriptionInput = (get_node(ChoiceDescriptionInput) as LineEdit)

	(get_node(OptionDeleteBtn) as Button).connect("pressed", self, "_switch_view", [2])
	(get_node(YesBtn) as Button).connect("pressed", self, "delete_option")
	(get_node(NoBtn) as Button).connect("pressed", self, "_switch_view", [1])

func _switch_view(id: int):
	displayView.visible = (id == 1)
	deleteView.visible = (id == 2)

	if (id == 2):
		(get_node(ConfirmLbl) as Label).text = "delete \"" + choiceNameInput.text + "\"?"
