tool
extends StoryBaseNode

export (NodePath) var ChangeNamespaceBtn
export (NodePath) var CommandNameInput
export (NodePath) var AddOptionBtn
export (NodePath) var DefaultAlwaysCheck

export (PackedScene) var CommandOptionLineBase

# ---------------------------------------------------------

var namespace_id

func add_option():
	var count = get_child_count()
	var option = CommandOptionLineBase.instance()

	add_child(option)
	set_slot(count, false, 0, Color.white, true, 0, Color.white)
	option.connect("option_line_deleted", self, "_on_option_line_deleted")

	mainEditor.set_current_as_modified(true)

	return option

func get_command_name():
	return commandNameInput.text

func get_data():
	var ret = {
		namespace_id = namespace_id,
		name = commandNameInput.text,
		default_always = defaultAlwaysCheck.pressed,
		options = []
	}

	for child in get_children():
		if child.get_index() == 0: continue
		ret.options.append(child.get_data())

	return ret

func set_namespace(id: int):
	namespace_id = id
	title = "namespace: '" + stedb.get_data(stedb.TYPE_NAMESPACE, id).name + "'"
	mainEditor.set_current_as_modified(true)

func update_data(data: Dictionary):
	var _tmp

	set_namespace(data.namespace_id)
	commandNameInput.text = str(data.name)
	for option in data.options:
		_tmp = add_option()
		_tmp.set_from_data(option)

# ---------------------------------------------------------

var commandNameInput: LineEdit
var defaultAlwaysCheck: CheckBox

var mainEditor

func _ready():
	commandNameInput = (get_node(CommandNameInput) as LineEdit)
	defaultAlwaysCheck = (get_node(DefaultAlwaysCheck) as CheckBox)

	(get_node(ChangeNamespaceBtn) as Button).connect("pressed", mainEditor, "change_namespace", [self])
	(get_node(AddOptionBtn) as Button).connect("pressed", self, "add_option")
	connect("close_request", self, "_delete")

func _delete(merge_mode: int = UndoRedo.MERGE_DISABLE):
	var undo_redo = mainEditor._undoRedo
	undo_redo.create_action("delete Story node", merge_mode)
	undo_redo.add_undo_method(mainEditor, "build_node",
		true, {node_name=name, data=get_data(), offset=offset}, get_connections())
	undo_redo.add_do_method(mainEditor, "delete_node", name)
	undo_redo.commit_action()

func _on_option_line_deleted(obj):
	unlink(obj._index)
	set_size( Vector2(rect_size.x, 0) )

	for child in get_children():
		if child.get("_index") == null: continue
		update_from_port(child._index, child.get_index())
		child._index = child.get_index()

	mainEditor.set_current_as_modified(true)
