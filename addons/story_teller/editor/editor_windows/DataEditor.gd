tool
extends WindowDialog

export (NodePath) var NamespaceContainer
export (NodePath) var ValueContainer
export (NodePath) var LockContainer

export (NodePath) var AddNamespaceBtn
export (NodePath) var AddDataBtn

export (PackedScene) var BaseDataItem

func clear_view(update_listview: bool = true):
	ste.namespaces = []
	ste.values = []
	ste.locks = []

	if update_listview:
		_update_container(st.TYPE_NAMESPACE)
		_update_container(st.TYPE_VALUE)
		_update_container(st.TYPE_LOCK)

func get_ns_node(ns_id: int):
	for node in namespaceContainer.get_children():
		if node.id == ns_id: return node
	return null

func open(with_extra_tab := false):
	_update_container(st.TYPE_NAMESPACE)
	_update_container(st.TYPE_VALUE)
	_update_container(st.TYPE_LOCK)

	var tabContainer = (valueContainer.get_parent().get_parent() as TabContainer)

	if with_extra_tab:
		_build_options_view(tabContainer)
		_build_inputs_view(tabContainer)

	popup_centered()

func close():
	for_cmd = false
	for_template = false
	ste.set_selection_mode_types()

	if _options_tab != null:
		_options_tab.queue_free()
		_options_tab = null

	if _inputs_tab != null:
		_inputs_tab.queue_free()
		_inputs_tab = null


# ---------------------------------------------------------------------------------------

var namespaceContainer: VBoxContainer
var valueContainer: VBoxContainer
var lockContainer: VBoxContainer

var addDataBtn: Button
var addNamespaceBtn: Button

var valueContainerVisible: bool = true

var storyChunkEditor
var conditionUpdateEditor
var mainEditor

var for_cmd: bool = false
var for_template: bool = false

func _ready():
	namespaceContainer = (get_node(NamespaceContainer) as Control)
	valueContainer = (get_node(ValueContainer) as Control)
	lockContainer = (get_node(LockContainer) as Control)

	addNamespaceBtn = (get_node(AddNamespaceBtn) as Button)
	addDataBtn = (get_node(AddDataBtn) as Button)

	addNamespaceBtn.connect('pressed', self, '_add_data', [true])
	addDataBtn.connect('pressed', self, '_add_data', [false])
	connect('popup_hide', self, 'close')

func _physics_process(delta):
	if not visible: return
	var lockContainerVisible = lockContainer.get_parent().visible
	valueContainerVisible = valueContainer.get_parent().visible

	addDataBtn.visible = (valueContainerVisible or lockContainerVisible)
	if addDataBtn.visible:
		if valueContainerVisible: addDataBtn.text = '+ Add Value'
		elif lockContainer.get_parent().visible: addDataBtn.text = '+ Add Lock'


func _on_data_updated(type: int, id: int):
	if(type == st.TYPE_NAMESPACE):
		mainEditor._update_command_nodes(id)
	mainEditor._storyList_set_modified("update " + ste.type_to_str(type) + " [" + str(id) + "]")

func _on_data_deleted(type: int, id: int):
	if(type == st.TYPE_NAMESPACE):
		mainEditor._delete_command_nodes(id)
	mainEditor._storyList_set_modified("delete " + ste.type_to_str(type) + " [" + str(id) + "]")

func _on_data_selected(payload):
	if for_cmd and (payload.type == st.TYPE_NAMESPACE):
		mainEditor.on_namespace_selected(payload)
	elif for_template:
		storyChunkEditor.on_data_selected(payload)
	else:
		conditionUpdateEditor.on_target_selected(payload)
	visible = false


func _update_container(type: int):
	var target: VBoxContainer
	var target_data: Array

	if type == st.TYPE_NAMESPACE:
		target = namespaceContainer
		target_data = ste.namespaces
	elif type == st.TYPE_VALUE:
		target = valueContainer
		target_data = ste.values
	elif type == st.TYPE_LOCK:
		target = lockContainer
		target_data = ste.locks

	if target == null: return

	for node in target.get_children(): node.queue_free()
	_build_items(target_data, target)

func _build_items(data: Array, parent: Node):
	for d in data:
		var node = BaseDataItem.instance()
		node.type = d.type
		node.id = d.id
		if d.type == st.TYPE_NAMESPACE:
			node._count = mainEditor.get_cmd_count(d.id)
		node.connect('data_selected', self, '_on_data_selected')
		node.connect('data_updated', self, '_on_data_updated')
		node.connect('data_deleted', self, '_on_data_deleted')
		node.connect('add_command_request', self, '_build_command')
		parent.add_child(node)

func _build_command(id: int):
	var tmp_node = mainEditor.build_command_node(id)
	var data = {
		node_name = tmp_node.name,
		data = tmp_node.get_data(),
		offset = tmp_node.offset
	}
	tmp_node.remove()
	mainEditor.build_node(true, data)

func _add_data(is_ns: bool):
	var type = -1
	var id = -1

	if is_ns:
		type = st.TYPE_NAMESPACE
		id = (ste.get_last_id(type) + 2)
		ste.add_data(type, 'namespace_' + str(id), false)
		_update_container(st.TYPE_NAMESPACE)
	elif valueContainerVisible:
		type = st.TYPE_VALUE
		id = (ste.get_last_id(type) + 2)
		ste.add_data(type, 'value_' + str(id), 0)
		_update_container(st.TYPE_VALUE)
	else:
		type = st.TYPE_LOCK
		id = (ste.get_last_id(type) + 2)
		ste.add_data(type, 'lock_' + str(id), false)
		_update_container(st.TYPE_LOCK)

	if type != -1: mainEditor._storyList_set_modified("add " + ste.type_to_str(type) + " [" + str(id) + "]")

func _build_tab_container():
	var scroll = ScrollContainer.new()
	scroll.set('size_flags_horizontal', SIZE_EXPAND_FILL)
	scroll.set('size_flags_vertical', SIZE_EXPAND_FILL)

	var hbox = VBoxContainer.new()
	hbox.set('size_flags_horizontal', SIZE_EXPAND_FILL)
	scroll.add_child(hbox)

	return {root = scroll, leaf = hbox}

var _options_tab
func _build_options_view(tabContainer: TabContainer):
	if len(ste.options) == 0: return

	_options_tab = _build_tab_container()
	_build_items(ste.options, _options_tab.leaf)
	_options_tab = _options_tab.root

	_options_tab.name = 'Options'
	tabContainer.add_child(_options_tab)

var _inputs_tab
func _build_inputs_view(tabContainer: TabContainer):
	var inputs = ste.inputs
	if not for_template:
		inputs = []
		for input in ste.inputs:
			if input.ini_val == st.INPUTTYPE_FLOAT:
				inputs.append(input)

	if len(inputs) == 0: return

	_inputs_tab = _build_tab_container()
	_build_items(inputs, _inputs_tab.leaf)
	_inputs_tab = _inputs_tab.root

	_inputs_tab.name = 'Inputs'
	tabContainer.add_child(_inputs_tab)
