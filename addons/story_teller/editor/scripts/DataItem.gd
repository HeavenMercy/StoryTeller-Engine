tool
extends MarginContainer

export (NodePath) var DisplayView
export (NodePath) var EditView
export (NodePath) var DeleteView

export (NodePath) var DisplayIdLbl
export (NodePath) var NameLbl
export (NodePath) var ValueSpin
export (NodePath) var StateOption
export (NodePath) var RenameBtn
export (NodePath) var SelectBtn
export (NodePath) var DeleteBtn
export (NodePath) var AddCmdPnl
export (NodePath) var AddCmdBtn

export (NodePath) var EditIdLbl
export (NodePath) var NameField
export (NodePath) var OkBtn
export (NodePath) var CancelBtn

export (NodePath) var ConfirmLbl
export (NodePath) var YesBtn
export (NodePath) var NoBtn

signal add_command_request(id)
signal data_deleted(type, id)
signal data_selected(data)
signal data_updated(type, id)

# ---------------------------------------------------------------------------------------

var type: int
var id: int

func edit_data():
	_switch_view(2)

	nameField.select_all()
	nameField.grab_focus()

func save_data(text: String = ""):
	if text.empty():
		if nameField.text.empty(): return
		else: text = nameField.text

	stedb.rename_data(type, id, text)
	emit_signal("data_updated", type, id)
	_exit_edit()

func delete_data():
	stedb.delete_data(type, id)
	emit_signal("data_deleted", type, id)
	call_deferred("queue_free")

func select_data():
	emit_signal("data_selected", {type=type, id=id})
	visible = false

# ---------------------------------------------------------------------------------------

var displayView
var editView
var deleteView

var _count: int = 1

var valueSpin: SpinBox
var stateOption: OptionButton
var renameBtn: Button
var selectBtn: Button
var deleteBtn: Button

var nameField: LineEdit

func _ready():
	displayView = get_node(DisplayView)
	editView = get_node(EditView)
	deleteView = get_node(DeleteView)
	_switch_view(1)

	valueSpin = (get_node(ValueSpin) as SpinBox)
	stateOption = (get_node(StateOption) as OptionButton)

	nameField = (get_node(NameField) as LineEdit)

	renameBtn = (get_node(RenameBtn) as Button)
	deleteBtn = (get_node(DeleteBtn) as Button)
	selectBtn = (get_node(SelectBtn) as Button)
	selectBtn.visible = false

	valueSpin.connect("value_changed", self, "_set_ini_val")
	stateOption.connect("item_selected", self, "_set_ini_val")

	renameBtn.connect("pressed", self, "edit_data")
	selectBtn.connect("pressed", self, "select_data")
	(get_node(DeleteBtn) as Button).connect("pressed", self, "_switch_view", [3])
	(get_node(AddCmdBtn) as Button).connect("pressed", self, "_send_cmdadd_request")

	nameField.connect("text_entered", self, "save_data")
	(get_node(OkBtn) as Button).connect("pressed", self, "save_data")
	(get_node(CancelBtn) as Button).connect("pressed", self, "_exit_edit")

	(get_node(YesBtn) as Button).connect("pressed", self, "delete_data")
	(get_node(NoBtn) as Button).connect("pressed", self, "_exit_edit")


	get_node(AddCmdPnl).visible = (type == stedb.TYPE_NAMESPACE)
	_exit_edit()
	selectBtn.visible = stedb.selection_mode

func _switch_view(id: int):
	displayView.visible = (id == 1)
	editView.visible = (id == 2)
	deleteView.visible = (id == 3)

func _send_cmdadd_request():
	emit_signal("add_command_request", id)

func _exit_edit():
	_switch_view(1)

	var data = stedb.get_data(type, id)
	(get_node(DisplayIdLbl) as Label).text = str(data.id)
	(get_node(EditIdLbl) as Label).text = str(data.id)
	(get_node(NameLbl) as Label).text = data.name
	(get_node(ConfirmLbl) as Label).text = "delete \"" + data.name + "\"?"

	nameField.text = data.name


	var editable = ((type != stedb.TYPE_NAMESPACE) or (id != 0))

	valueSpin.visible = (editable and (type == stedb.TYPE_VALUE))
	stateOption.visible = (editable and (type != stedb.TYPE_VALUE))

	renameBtn.visible = editable
	deleteBtn.visible = editable

	if type != stedb.TYPE_VALUE:
		stateOption.selected = (1 if data.ini_val else 0)
	else: valueSpin.value = float(data.ini_val)

func _set_ini_val(val):
	if type != stedb.TYPE_VALUE: val = (val == 1)
	stedb.set_ini_val(type, id, val)
	emit_signal("data_updated", type, id)
