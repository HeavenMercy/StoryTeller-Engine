tool
extends _GraphNodeEnhanced

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
	option.update_index()
	set_slot(count, false, 0, Color.white, true, 0, Color.white)
	option.connect('option_line_deleted', self, '_on_option_line_deleted')
	option._command = self
	option.mainEditor = mainEditor

	mainEditor._storyList_set_modified("add option in command [" + get_name() + "]")

	return option

func get_name():
	if commandNameInput != null:
		return commandNameInput.text
	else: return ""

func get_ns_name(): return ste.get_data(st.TYPE_NAMESPACE, namespace_id).name

func get_data():
	var ret = {
		namespace_id = namespace_id,
		name = commandNameInput.text,
		default_always = defaultAlwaysCheck.pressed,
		options = []
	}

	for child in get_children():
		if not child is CommandOptionLine: continue
		ret.options.append(child.get_data())

	return ret

func set_namespace(id: int):
	namespace_id = id
	title = "namespace: '" + get_ns_name() + "'"

func update_data(data: Dictionary):
	set_namespace(data.namespace_id)
	_update_name(str(data.name))

	var _tmp
	for option in data.options:
		_tmp = add_option()
		_tmp.set_from_data(option)

# ---------------------------------------------------------

var commandNameInput: LineEdit
var defaultAlwaysCheck: CheckBox

var mainEditor

func _ready():
	fix_view()

	commandNameInput = (get_node(CommandNameInput) as LineEdit)
	defaultAlwaysCheck = (get_node(DefaultAlwaysCheck) as CheckBox)

	(get_node(ChangeNamespaceBtn) as Button).connect('pressed', mainEditor, 'change_namespace', [self])
	(get_node(AddOptionBtn) as Button).connect('pressed', self, 'add_option')

	commandNameInput.connect('text_changed', self, '_update_name')

func _update_name(name):
	name = ste.str_to_key(name)

	var last_caret_pos = commandNameInput.caret_position
	commandNameInput.text = str(name)
	commandNameInput.caret_position = last_caret_pos
	mainEditor._update_node_listview(1)

func _on_option_line_deleted(obj):
	unlink(obj._index)
	fix_view()

	for child in get_children():
		if child.get('_index') == null: continue

		var last_index = child._index
		child.update_index()
		update_from_port(last_index, child._index)

	mainEditor._storyList_set_modified("delete option in command [" + get_name() + "]")
