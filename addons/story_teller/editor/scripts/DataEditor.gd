tool
extends WindowDialog

export (NodePath) var NamespaceContainer
export (NodePath) var ValueContainer
export (NodePath) var LockContainer

export (NodePath) var AddNamespaceBtn
export (NodePath) var AddDataBtn

export (PackedScene) var BaseDataItem
export (Array, NodePath) var ForCommand_ToHide
export (Array, NodePath) var ForTest_ToHide

func clear_view(update_listview: bool = true):
	stedb.namespaces = []
	stedb.values = []
	stedb.locks = []

	if update_listview:
		_update_container(stedb.TYPE_NAMESPACE)
		_update_container(stedb.TYPE_VALUE)
		_update_container(stedb.TYPE_LOCK)

func get_ns_node(ns_id: int):
	for node in namespaceContainer.get_children():
		if node.id == ns_id: return node
	return null

func open():
	for path in ForCommand_ToHide:
		get_node(path).visible = not for_cmd

	for path in ForTest_ToHide:
		get_node(path).visible = not for_test

	if for_cmd or for_test: stedb.selection_mode = true

	_update_container(stedb.TYPE_NAMESPACE)
	_update_container(stedb.TYPE_VALUE)
	_update_container(stedb.TYPE_LOCK)

	popup_centered()

func close():
	for_cmd = false
	for_test = false
	stedb.selection_mode = false


# ---------------------------------------------------------------------------------------

var namespaceContainer: VBoxContainer
var valueContainer: VBoxContainer
var lockContainer: VBoxContainer

var addDataBtn: Button
var addNamespaceBtn: Button

var valueContainerVisible: bool = true
var for_cmd: bool = false
var for_test: bool = false

var conditionUpdateEditor
var mainEditor

func _ready():
	namespaceContainer = (get_node(NamespaceContainer) as Control)
	valueContainer = (get_node(ValueContainer) as Control)
	lockContainer = (get_node(LockContainer) as Control)

	addNamespaceBtn = (get_node(AddNamespaceBtn) as Button)
	addDataBtn = (get_node(AddDataBtn) as Button)

	addNamespaceBtn.connect("pressed", self, "_add_data", [true])
	addDataBtn.connect("pressed", self, "_add_data", [false])
	connect("popup_hide", self, "close")

func _on_data_updated(type: int, id: int):
	mainEditor.set_current_as_modified(true)
	if(type == stedb.TYPE_NAMESPACE):
		mainEditor._update_command_nodes(id)


func _on_data_deleted(type: int, id: int):
	#_update_container(type)
	mainEditor.set_current_as_modified(true)
	if(type == stedb.TYPE_NAMESPACE):
		mainEditor._delete_command_nodes(id)

func _physics_process(delta):
	if not visible: return
	valueContainerVisible = valueContainer.get_parent().visible
	addDataBtn.text = "+ Add " + ("Value" if valueContainerVisible else "Lock")

func _update_container(type: int):
	var target: VBoxContainer
	var target_data: Array

	if type == stedb.TYPE_NAMESPACE:
		target = namespaceContainer
		target_data = stedb.namespaces
	elif type == stedb.TYPE_VALUE:
		target = valueContainer
		target_data = stedb.values
	elif type == stedb.TYPE_LOCK:
		target = lockContainer
		target_data = stedb.locks

	if target == null: return

	for node in target.get_children(): node.call_deferred("queue_free")
	for data in target_data:
		var node = BaseDataItem.instance()
		node.type = type
		node.id = data.id
		if type == stedb.TYPE_NAMESPACE:
			node._count = mainEditor.get_cmd_count(data.id)
		node.connect("data_updated", self, "_on_data_updated")
		node.connect("data_deleted", self, "_on_data_deleted")
		node.connect("add_command_request", self, "_build_command")
		if for_cmd and (type == stedb.TYPE_NAMESPACE):
			node.connect("data_selected", mainEditor, "on_namespace_selected")
		else: node.connect("data_selected", conditionUpdateEditor, "on_target_selected")
		target.add_child(node)


func _build_command(id: int):
	var tmp_node = mainEditor.build_command_node(id, true)

	var data = {
		node_name = tmp_node.name,
		data = tmp_node.get_data(),
		offset = tmp_node.offset
	}
	tmp_node.remove()

	mainEditor._undoRedo.create_action("duplicate Story node")
	mainEditor._undoRedo.add_undo_method(mainEditor, "delete_node", data.node_name)
	mainEditor._undoRedo.add_do_method(mainEditor, "build_node", true, data)
	mainEditor._undoRedo.commit_action()

func _add_data(is_ns: bool):
	if is_ns:
		stedb.add_data(stedb.TYPE_NAMESPACE,
			"namespace_" + str(stedb.get_last_id(stedb.TYPE_NAMESPACE)+1), false)
		mainEditor.set_current_as_modified(true)
		_update_container(stedb.TYPE_NAMESPACE)
	elif valueContainerVisible:
		stedb.add_data(stedb.TYPE_VALUE,
			"value_" + str(stedb.get_last_id(stedb.TYPE_VALUE)+1), 0)
		mainEditor.set_current_as_modified(true)
		_update_container(stedb.TYPE_VALUE)
	else:
		stedb.add_data(stedb.TYPE_LOCK,
			"lock_" + str(stedb.get_last_id(stedb.TYPE_LOCK)+1), false)
		mainEditor.set_current_as_modified(true)
		_update_container(stedb.TYPE_LOCK)
