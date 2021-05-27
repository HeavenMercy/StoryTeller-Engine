tool
extends MarginContainer

class_name TestUpdateItem

export (NodePath) var DisplayView
export (NodePath) var DeleteView

export (NodePath) var Prefix
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
	target = {type = -1, id = -1},
	operator = -1,
	value = null
}

func for_test(): _fortest = true


func update_data(newdata: Dictionary):
	_data.value = newdata.value
	_data.operator = newdata.operator

	_data.target = newdata.target.duplicate()

	var oper = stedb.get_operators(_data.target.type, _fortest)[_data.operator]
	var name = stedb.get_data(_data.target.type, _data.target.id).name

	var text = ""
	match(newdata.target.type):
		stedb.TYPE_NAMESPACE: text += "namespace [" + name + "]: " + oper \
			+ " " + ("ENABLED" if _data.value > 0 else "DISABLED")
		stedb.TYPE_LOCK: text += "lock [" + name + "]: " + oper + " " \
			+ ("ON" if _data.value else "OFF")
		stedb.TYPE_VALUE: text += "value [" + name + "]: " + oper + " " \
			+ str(_data.value)

	(get_node(HintLabel) as Label).text = text


func request_data_edit(): emit_signal("data_edit_request", self)

func delete_data():
	emit_signal("data_deleted", get_index())
	call_deferred("queue_free")


func get_prefix():
	return (get_node(Prefix) as Label).text

func set_prefix(prefix: String):
	(get_node(Prefix) as Label).text = prefix

# ---------------------------------------------------------------------------

var displayView
var deleteView

func _ready():
	displayView = get_node(DisplayView)
	deleteView = get_node(DeleteView)
	_switch_view(1)

	(get_node(EditButton) as Button).connect("pressed", self, "request_data_edit")
	(get_node(DeleteButton) as Button).connect("pressed", self, "_switch_view", [2])

	(get_node(ConfirmLbl) as Label).text = "delete " + ("condition" if _fortest else "update") + "\"?"
	(get_node(YesBtn) as Button).connect("pressed", self, "delete_data")
	(get_node(NoBtn) as Button).connect("pressed", self, "_switch_view", [1])

#	_fortest = false
#	set_prefix("")
#	stedb.add(stedb.TYPE_VALUE, "myvar")
#	update_data({target = {type = stedb.TYPE_VALUE, id = 0}, operator = 2, value = 15})

func _switch_view(id: int):
	displayView.visible = (id == 1)
	deleteView.visible = (id == 2)
