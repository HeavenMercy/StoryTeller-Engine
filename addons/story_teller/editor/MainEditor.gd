tool
extends Control

class_name MainEditor

export (NodePath) var StoryChunkEditor
export (NodePath) var ConditionUpdateEditor
export (NodePath) var DataEditor
export (NodePath) var ConfirmDialog
export (NodePath) var SaveFileDialog
export (NodePath) var StoryTypePopup

export (NodePath) var StoryView
export (NodePath) var StartNode
export (NodePath) var EndNode

export (PackedScene) var BaseStoryChunkNode
export (PackedScene) var BaseStoryConditionNode
export (PackedScene) var BaseStoryChoiceNode
export (PackedScene) var BaseStoryInputNode
export (PackedScene) var BaseCommandNode

export (NodePath) var MenuContainer
export (NodePath) var StoryListFilter
export (NodePath) var StoryList

export (NodePath) var ChunkList
export (NodePath) var CommandList

export (String) var NewFilename = ''

# ---------------------------------------------------------------------------------------

var edited_node
var edited_condUpd

var to_save: bool = false
var file = File.new()

var menu_config = [
	{
		name='File',
		items=[
			{name='Open', target=self, action='open_file', shortcut={scancode=KEY_O, ctrl=true}},
			{name='                           '},
			{name='Save', target=self, action='save_file', shortcut={scancode=KEY_S, ctrl=true}},
			{name='Save As...', target=self, action='save_file_as', shortcut={scancode=KEY_S, ctrl=true, shift=true}},
			{name='Save All', target=self, action='save_all'},
			{name='                           '},
			{name='Close', target=self, action='close_current_story', shortcut={scancode=KEY_W, ctrl=true}}
		]
	},
	{
		name='Edit',
		items=[
			{name='Open Data Editor', target='dataEditor', action='open', shortcut={scancode=KEY_E, ctrl=true}},
			{name='                           '},
			{name='Clear Data', target=self, action='clear_data'},
			{name='                           '},
			{name='Clear View', target=self, action='delete_nodes', shortcut={scancode=KEY_L, ctrl=true}}
		]
	}
]

var last_node_id = -1
var last_offset = Vector2.ZERO
func build_story_node(type: int, pos: Vector2 = Vector2.ZERO, shiftFlag: int = 0):
	var node
	if type == st.STORYTYPE_CHUNK: node = BaseStoryChunkNode.instance()
	elif type == st.STORYTYPE_CONDITION: node = BaseStoryConditionNode.instance()
	elif type == st.STORYTYPE_CHOICE: node = BaseStoryChoiceNode.instance()
	elif type == st.STORYTYPE_INPUT: node = BaseStoryInputNode.instance()

	if node == null: return

	node.mainEditor = self
	node.graphEdit = storyView

	node.offset = _update_position(node.rect_size, pos)
	if shiftFlag < 0: node.offset -= node.rect_size * Vector2(1, .3)
	elif shiftFlag > 0: node.offset -= node.rect_size * Vector2(0, .3)

	node.fix_offset()

	last_node_id += 1
	node.update_data({ id = 'Chunk_'+str(last_node_id) })

	storyView.add_child(node)
	return node

func edit_node(node, for_condition: bool = false):
	edited_node = node
	storyChunkEditor.open(edited_node._data, for_condition)

func update_nodeData(data):
	if edited_node:
		edited_node.update_data(data)
		_update_node_listview(0)
		_storyList_set_modified("update node [" + edited_node.get_name() + "] data")


func edit_condUpd(condUpd):
	edited_condUpd = condUpd

	conditionUpdateEditor.open(
		('Condition Editor' if edited_condUpd._fortest else 'Update Editor'),
		edited_condUpd._fortest, edited_condUpd._data )

func update_condUpdData(data):
	if edited_condUpd: edited_condUpd.update_data(data)

func build_command_node(ns_id: int):
	var node = BaseCommandNode.instance()
	node.graphEdit = storyView
	node.mainEditor = self
	node.set_namespace(ns_id)

	node.offset = _update_position(node.rect_size)
	if dataEditor.visible:
		dataEditor.get_ns_node(ns_id)._count = get_cmd_count(ns_id)

	storyView.add_child(node)
	return node

func get_cmd_count(ns_id: int = -1):
	var count = 0
	for node in storyView.get_children():
		if not (node is GraphNode) \
		or (node == start) or (node == end):
			continue

		if (node in command_list) and \
			((ns_id == -1) or (node.namespace_id == ns_id)):
			count += 1

	return count


func link_to_new_node(from: String, from_slot: int, position: Vector2):
	var from_node = storyView.get_node(from)
	if (from_node != start) and (from_node != end) \
	and (from_node.OnePerPort):
		for conn in storyView.get_connection_list():
			if (conn.from == from) and (conn.from_port == from_slot):
				return

	storyTypePopup.set_payload({
		position = storyView.get_local_mouse_position(),
		from = from,
		from_slot = from_slot,
	})
	storyTypePopup.popup_at()

func link_to_node(from: String, from_slot: int, to: String, to_slot: int):
	var from_node = storyView.get_node(from)
	if (from_node != start) and (from_node != end) \
		and (from_node.OnePerPort):
			for conn in storyView.get_connection_list():
				if (conn.from == from) and (conn.from_port == from_slot):
					return

	storyView.connect_node(from, from_slot, to, to_slot)
	_storyList_set_modified("link node [" + from_node.get_name() + "] to node [" + storyView.get_node(to).get_name() + "]")

func unlink_to_node(from: String, from_slot: int, to: String, to_slot: int):
	for conn in storyView.get_connection_list():
		if (conn.from == from) and (conn.from_port == from_slot) \
		and (conn.to == to) and (conn.to_port == to_slot):
			storyView.disconnect_node(conn.from, conn.from_port, conn.to, conn.to_port)
			_storyList_set_modified("unlink node [" + storyView.get_node(from).get_name() + "] to node [" + storyView.get_node(to).get_name() + "]")
			return


func delete_node(node_name: String):
	for node in storyView.get_children():
		if node.name == node_name:
			node.remove()
			_storyList_set_modified("delete node [" + node.get_name() + "]")
			_unregister_node_in_listview((0 if (node in chunk_list) else 1), node)
			return true
	return false

func build_node(is_command: bool, node_data, connections=[], with_undo := true):
	var node
	if not is_command:
		node = build_story_node(node_data.get('node_type', st.STORYTYPE_CHUNK))
	else:
		node = build_command_node(node_data.data.namespace_id)

	if not node_data.node_name.empty():
		node.name = node_data.node_name
	node.update_data(node_data.data)
	node.offset = node_data.offset

	for conn in connections:
		storyView.connect_node(conn.from, conn.from_port, conn.to, conn.to_port)

	_register_node_in_listview((1 if is_command else 0), node)
	if with_undo:
		_storyList_set_modified("build node [" + node.get_name() + "]")

func duplicate_nodes():
	for node in storyView.get_children():
		if not ((node is GraphNode) and node.selected) \
		or (node == start) or (node == end): continue

		node.selected = false

		var tmp_node
		if node in chunk_list:
			tmp_node = build_story_node(node.type)
		elif node in command_list:
			tmp_node = build_command_node(node.namespace_id)

		var data = {
			node_type = tmp_node.type,
			node_name = tmp_node.name,
			data = node.get_data(),
			offset = node.offset + (Vector2.ONE * OFFSET)
		}
		tmp_node.remove()

		build_node((node in command_list), data)

func delete_nodes(selected_only: bool= false, with_undo := true):
	var deleted = false
	for node in storyView.get_children():
		if (node == start) or (node == end) \
		or not ((node is GraphNode) and ((not selected_only) or node.selected)): continue

		if (node in chunk_list) \
		or (node in command_list):
			node.remove()
			deleted = true
			_unregister_node_in_listview((0 if (node in chunk_list) else 1), node)

	if with_undo and deleted:
		_storyList_set_modified("delete " + ("selected" if selected_only else "all") + " nodes")



func change_namespace(cmd_node):
	edited_node = cmd_node
	ste.set_selection_mode_types(true, false, false)
	dataEditor.for_cmd = true
	dataEditor.open()

func on_namespace_selected(target: Dictionary = {}):
	if edited_node != null:
		edited_node.set_namespace(target.id)
		_storyList_set_modified("set namespace of node [" + edited_node.get_name() + "]")
		dataEditor.visible = false

func clear_data(choice = -1):
	if choice == -1:
		confirmDialog.set_buttons('Yes', 'No')
		confirmDialog.open('Delete all data?', 'All the data and the custom namespaces will also be permanently deleted.' +
			'Do you really want to clear all data?', self, 'clear_data')
	elif choice == confirmDialog.BUTTON_OK:
		ste.clear_data()
		for node in storyView.get_children():
			if (node == start) or (node == end) \
			or not (node is GraphNode): continue

			if (node in command_list) \
			and (node.namespace_id != 0):
				node.remove()

		_storyList_set_modified("clear data")



func save_file(force_dialog: bool = false):
	to_save = true

	var filepath = storyList.get_item_metadata(_storyList_current_idx).path
	if file.file_exists(filepath) and not force_dialog:
		apply_action(filepath)
	else:
		saveFileDialog.invalidate()
		saveFileDialog.mode = FileDialog.MODE_SAVE_FILE
		saveFileDialog.popup_centered()

		# set filename to filter text (quick naming)
		saveFileDialog.deselect_items()
		saveFileDialog.get_line_edit().text = storyListFilter.text

func save_file_as(): save_file(true)

func save_all():
	var i = 1
	while i < storyList.get_item_count():
		_storyList_current_idx = i
		save_file(false)
		i += 1

	_storyList_current_idx = storyList.get_selected_items()[0] if storyList.is_anything_selected() else 0

func open_file():
	to_save = false

	saveFileDialog.invalidate()
	saveFileDialog.mode = FileDialog.MODE_OPEN_FILE
	saveFileDialog.popup_centered()

func apply_action(filepath: String):
	if to_save:
		if file.open(filepath, File.WRITE) != OK: return
		var data = storyList.get_item_metadata(_storyList_current_idx).snapman.get_current_snapshot().data
		if data == null: return

		file.store_var(data)
		file.close()

		if _storyList_current_idx == 0:
			close_current_story(3)

		_storyList_set_modified("", false)
		_storyList_edit_story(filepath, data)
	else:
		if file.open(filepath, File.READ) != OK: return
		var data = file.get_var()
		file.close()

		if data == null: return
		_storyList_edit_story(filepath, data)


# ---------------------------------------------------------------------------------------

var storyChunkEditor: WindowDialog
var conditionUpdateEditor: WindowDialog
var dataEditor: WindowDialog
var saveFileDialog: FileDialog

var confirmDialog
var storyTypePopup

var storyView: GraphEdit
var storyList: ItemList
var storyListFilter: LineEdit

var newBtn: Button
var openBtn: Button
var saveBtn: Button
var saveAsBtn: Button

var start: GraphNode
var end: GraphNode

func _ready():
	storyChunkEditor = (get_node(StoryChunkEditor) as WindowDialog)
	conditionUpdateEditor = (get_node(ConditionUpdateEditor) as WindowDialog)
	dataEditor = (get_node(DataEditor) as WindowDialog)
	saveFileDialog = (get_node(SaveFileDialog) as FileDialog)

	confirmDialog = get_node(ConfirmDialog)
	storyTypePopup = (get_node(StoryTypePopup) as _PopupMenuEnhanced)

	storyView = (get_node(StoryView) as GraphEdit)
	storyList = (get_node(StoryList) as ItemList)
	storyListFilter = (get_node(StoryListFilter) as LineEdit)

	start = get_node(StartNode)
	end = get_node(EndNode)

	storyChunkEditor.connect('data_save_request', self, 'update_nodeData')
	conditionUpdateEditor.connect('data_save_request', self, 'update_condUpdData')
	saveFileDialog.connect('file_selected', self, 'apply_action')
	storyList.connect('item_selected', self, '_storyList_on_item_selected')
	storyListFilter.connect('text_changed', self, '_storyList_filter')

	(get_node(ChunkList) as ItemList).connect('item_selected', self, '_focus_node', [0])
	(get_node(CommandList) as ItemList).connect('item_selected', self, '_focus_node', [1])

	storyView.connect('connection_to_empty', self, 'link_to_new_node')
	storyView.connect('connection_request', self, 'link_to_node')
	storyView.connect('disconnection_request', self, 'unlink_to_node')
	storyView.connect('duplicate_nodes_request', self, 'duplicate_nodes')
	storyView.connect('delete_nodes_request', self, 'delete_nodes', [true])
	storyView.connect('gui_input', self, '_on_storyView_gui_input')

	var i = -1; var j = -1
	var tmp: MenuButton
	for menu in menu_config:
		i += 1; j=-1
		tmp = MenuButton.new()
		tmp.text = menu.name
		for item in menu.items:
			j += 1
			tmp.get_popup().add_item(item.name)
			tmp.get_popup().set_item_disabled(j, (item.name.strip_edges() == ''))
			if item.has('shortcut'):
				var shortcut = ShortCut.new()
				var key = InputEventKey.new()
				key.scancode = item.shortcut.scancode
				key.control = item.shortcut.get('ctrl', false)
				key.shift = item.shortcut.get('shift', false)
				key.alt = item.shortcut.get('alt', false)
				shortcut.shortcut = key
				tmp.get_popup().set_item_shortcut(j, shortcut, true)
		tmp.get_popup().connect('id_pressed', self, '_on_menu_id_pressed', [i])
		get_node(MenuContainer).add_child(tmp)

	conditionUpdateEditor.connect('select_data', self, '_select_data')
	dataEditor.conditionUpdateEditor = conditionUpdateEditor
	dataEditor.storyChunkEditor = storyChunkEditor
	storyChunkEditor.dataEditor = dataEditor

	saveFileDialog.filters = PoolStringArray(['*' + st.StoryInterpreter.FileExt + ' ; StoryTeller File'])
	storyChunkEditor.mainEditor = self
	dataEditor.mainEditor = self

	_config_popup()
	storyList.clear()
	_storyList_edit_story(NewFilename, {})

func _on_menu_id_pressed(item_id, menu_id):
	var item = menu_config[menu_id].items[item_id]
	if item == null: return

	if item.target is String:
		item.target = get(item.target)
	item.target.call_deferred(item.action)

const OFFSET = 20
func _update_position(size: Vector2, pos: Vector2 = Vector2.ZERO):
	if pos == Vector2.ZERO:
		pos = last_offset + (Vector2(.5, .5) * OFFSET)

	last_offset = pos
	var viewrect = Rect2(Vector2.ZERO, storyView.rect_size)
	var noderect = Rect2(last_offset, size)
	if not viewrect.encloses(noderect) \
	and not viewrect.intersects(noderect):
		last_offset = Vector2(1, 3.5) * OFFSET

	return last_offset + storyView.scroll_offset

func _delete_command_nodes(ns_id: int = -1):
	for node in storyView.get_children():
		if(not(node is GraphNode) or (node == start) or (node == end)): continue

		if (ns_id == -1) or ((node in command_list) and (node.namespace_id == ns_id)):
			delete_node(node.name)

func _update_command_nodes(ns_id: int = -1):
	for node in storyView.get_children():
		if(not(node is GraphNode) or (node == start) or (node == end)): continue

		if (ns_id == -1) or ((node in command_list) and (node.namespace_id == ns_id)):
			node.set_namespace(ns_id)

func _select_data(specific_type):
	if specific_type != -1:
		ste.set_selection_mode_types(
			(specific_type == st.TYPE_NAMESPACE),
			(specific_type == st.TYPE_LOCK),
			(specific_type in [st.TYPE_VALUE, st.TYPE_OPTION, st.TYPE_INPUT]) )
	else:
		ste.set_selection_mode_types(not edited_condUpd._fortest, true, true)

	dataEditor.open(edited_condUpd._fortest or (specific_type in [st.TYPE_VALUE, st.TYPE_OPTION, st.TYPE_INPUT]))

func unselect_all_nodes():
	for node in storyView.get_children():
		if (not node is GraphNode) or node.selected: continue
		node.selected = false

# ------------------------------------------------------------------------

var _storyList_current_idx = -1

func close_current_story(choice = -1):
	var snapman = storyList.get_item_metadata(_storyList_current_idx).snapman

	if choice == -1:
		if not snapman.is_current_saved():
			confirmDialog.set_buttons('Save and Close', 'Cancel', 'Ignore Changes')
			confirmDialog.open('Close Story?', 'The file has unsaved modifications. Do you really want to close it?',
				self, 'close_current_story')
		else: close_current_story(_ConfirmDialog.BUTTON_DISCARD)
		return
	elif choice == _ConfirmDialog.BUTTON_OK: save_file()
	elif choice == _ConfirmDialog.BUTTON_CANCEL: return

	if _storyList_current_idx == 0:
		delete_nodes(false, false)
		snapman.clear()
	else:
		_storyList_close_story(_storyList_current_idx)


func _storyList_filter(filter: String):
	var i = 1
	var selected = false
	while i < storyList.get_item_count():
		var name = storyList.get_item_text(i)
		storyList.set_item_disabled(i, not filter.is_subsequence_ofi(name))

		if not filter.empty() and not selected \
		and filter.is_subsequence_ofi(name):
			storyList.select(i)
			_storyList_on_item_selected(i)
			selected = true
		i += 1

	if not filter.empty() and not selected:
		storyList.select(0)
		_storyList_on_item_selected(0)

func _storyList_update_item_names():
	var i = 0
	while i < storyList.get_item_count():
		storyList.set_item_text(i,
			ste.uniq_name_tree.get_uniqname(storyList.get_item_metadata(i).path))
		i += 1

func _storyList_find(path: String):
	var i = 0
	while i < storyList.get_item_count():
		if path == storyList.get_item_metadata(i).path:
			return i
		i += 1

	return -1

func _storyList_edit_story(path, data):
	storyListFilter.text = ''
	_storyList_filter(storyListFilter.text)

	var added = false
	var idx = _storyList_find(path)
	if idx == -1:
		ste.uniq_name_tree.register_name(path)
		_storyList_update_item_names()
		added = true

		idx = storyList.get_item_count()
		storyList.add_item(ste.uniq_name_tree.get_uniqname(path))
		storyList.set_item_tooltip(idx, path)
		storyList.set_item_metadata(idx, {}) # to secure the test below

	if (len(storyList.get_item_metadata(idx)) == 0):
		storyList.set_item_metadata(idx, {
			path=path,
			snapman=SnapshotManager.new(data)
		})

	storyList.select(idx)
	_storyList_on_item_selected(idx)

	if added: storyList.sort_items_by_text()

func _storyList_close_story(idx):
	if (idx < 1) or (idx >= storyList.get_item_count()): return

	storyList.select(0)
	_storyList_on_item_selected(0)

	ste.uniq_name_tree.unregister_name(storyList.get_item_metadata(idx).path)
	storyList.remove_item(idx)
	_storyList_update_item_names()

func _storyList_on_item_selected(idx):
	if storyList.is_item_disabled(idx): return

	var data = storyList.get_item_metadata(idx).snapman.get_current_snapshot().data
	if data == null: data = {}

	var last_idx = _storyList_current_idx

	_storyList_current_idx = idx
	last_node_id = data.get('last_node_id', -1)

	ste.namespaces = data.get('namespaces', []).duplicate()
	ste.values = data.get('values', []).duplicate()
	ste.locks = data.get('locks', []).duplicate()
	ste.options = data.get('options', []).duplicate()
	ste.inputs = data.get('inputs', []).duplicate()
	ste.fix_default_ns()

	start.offset = data.get('start_offset', Vector2(50,200))
	end.offset = data.get('end_offset', Vector2(500,200))
	if last_idx != idx:
		storyView.scroll_offset = data.get('scroll_offset', Vector2.ZERO)

	delete_nodes(false, false)

	var node
	for c in data.get('story_chunks', []): build_node(false, c, [], false)
	for c in data.get('commands', []): build_node(true, c, [], false)

	for l in data.get('links', []):
		storyView.connect_node(l.from, l.from_port, l.to, l.to_port)



func _storyList_set_modified(message: String, modified := true, idx := -1):
	if (idx < -1) or (idx >= storyList.get_item_count()): return
	if(idx == -1): idx = _storyList_current_idx

	var snapman = storyList.get_item_metadata(idx).snapman
	# if not modified:
	# 	snapman.set_current_saved()
	# 	return

	var data = {
		last_node_id = last_node_id,

		namespaces = ste.namespaces.duplicate(),
		locks = ste.locks.duplicate(),
		values = ste.values.duplicate(),
		options = ste.options.duplicate(),
		inputs = ste.inputs.duplicate(),

		scroll_offset = storyView.scroll_offset,
		links = storyView.get_connection_list(),

		start_offset = start.offset,
		end_offset = end.offset,

		story_chunks = [],
		commands = [],
	}

	for node in storyView.get_children():
		if not (node is GraphNode) \
		or (node == start) or (node == end) \
		or node.is_removing():
			continue

		if node in chunk_list: data.story_chunks \
			.append({node_type=node.type, node_name=node.name, data=node.get_data(), offset=node.offset})
		elif node in command_list: data.commands \
			.append({node_name=node.name, data=node.get_data(), offset=node.offset})

	snapman.take_snapshot(data, message)
	if not modified:
		snapman.set_current_saved()

func _storyList_undo(idx := -1):
	if (idx < -1) or (idx >= storyList.get_item_count()): return
	if(idx == -1): idx = _storyList_current_idx

	if storyList.get_item_metadata(idx).snapman.undo():
		_storyList_on_item_selected(idx)

func _storyList_redo(idx := -1):
	if (idx < -1) or (idx >= storyList.get_item_count()): return
	if(idx == -1): idx = _storyList_current_idx

	if storyList.get_item_metadata(idx).snapman.redo():
		_storyList_on_item_selected(idx)


# ------------------------------------------------------------------------

var chunk_list = []
var command_list = []

# type can be 0 (story chunk) or 1 (command)

func _register_node_in_listview(type: int, node: GraphNode):
	if node == null: return

	var target_data = null

	if type == 0: target_data = chunk_list
	elif type == 1: target_data = command_list

	if (target_data == null): return

	target_data.append(node)
	_update_node_listview(type)

func _unregister_node_in_listview(type: int, node: GraphNode):
	if node == null: return

	var target_data = null

	if type == 0: target_data = chunk_list
	elif type == 1: target_data = command_list

	if (target_data == null): return

	target_data.erase(node)
	_update_node_listview(type)
	if type == 1:
		ste.remove_options(node.namespace_id, node.get_name())

func _update_node_listview(type: int):
	var target = null
	var target_data = null

	if type == 0:
		target_data = chunk_list
		target = (get_node(ChunkList) as ItemList)
	elif type == 1:
		target_data = command_list
		target = (get_node(CommandList) as ItemList)

	if (target == null) or (target_data == null): return

	target.clear()
	var i = 0
	for node in target_data:
		if node == null: continue

		var name = node.get_name()
		if type == 0: name += ' [' + node.get_type_text() + ']'
		elif type == 1: name += ' [' + node.get_ns_name() + ']'

		target.add_item(name)
		target.set_item_metadata(i, i)
		i += 1

	target.sort_items_by_text()

func _focus_node(idx: int, type: int):
	var target_data = null
	var target = null
	var other_target = null

	if type == 0:
		target_data = chunk_list
		target = (get_node(ChunkList) as ItemList)
		other_target = (get_node(CommandList) as ItemList)
	elif type == 1:
		target_data = command_list
		target = (get_node(CommandList) as ItemList)
		other_target = (get_node(ChunkList) as ItemList)

	if (target_data == null) or (target == null) or (other_target == null): return

	unselect_all_nodes()
	other_target.unselect_all()
	target = target_data[target.get_item_metadata(idx)]
	if target == null: return

	var offset = ((target.rect_size * storyView.zoom) - storyView.rect_size)/2
	storyView.scroll_offset = target.offset + offset
	storyView.set_selected(target)

# ------------------------------------------------------------------------

func _physics_process(delta):
	# handle conditionUpdateEditor not open if storyChunkEditor not open
	if (storyChunkEditor == null) or not storyChunkEditor.is_open:
		if conditionUpdateEditor != null: conditionUpdateEditor.close()


	# handle the modified state of the current story
	if storyList.get_item_count() > 0:
		var current = storyList.get_item_metadata(_storyList_current_idx)
		if (current != null):
			var modified_mark = ' [*]'

			storyList.set_item_text(_storyList_current_idx,
				storyList.get_item_text(_storyList_current_idx).replace(modified_mark, '') )
			if not current.snapman.is_current_saved():
				storyList.set_item_text(_storyList_current_idx,
					storyList.get_item_text(_storyList_current_idx) + modified_mark)

func _config_popup():
	storyTypePopup.configure([
		{text = 'Story Chunk', meta = st.STORYTYPE_CHUNK},
		{text = 'Story Condition', meta = st.STORYTYPE_CONDITION},
		{text = 'Story Choice', meta = st.STORYTYPE_CHOICE},
		{text = 'Story Input', meta = st.STORYTYPE_INPUT},
	])
	storyTypePopup.connect('data_selected', self, '_on_data_selected')

func _on_data_selected(_data):
	var node = build_story_node(_data.meta, _data.payload.position, 1)
	var data = {
		node_type = node.type,
		node_name = node.name,
		offset = node.offset,
		data = node.get_data()
	}
	node.remove()

	var connections = []
	var from = _data.payload.get('from', '')
	var from_slot = _data.payload.get('from_slot', -1)
	if (from != '') and (from_slot != -1):
		connections.append({
			from=from, from_port=from_slot,
			to=data.node_name, to_port=0
		})

	build_node(false, data, connections)
	last_node_id -= 1

func _input(event):
	if not visible: return

	event = (event as InputEventKey)
	if (event == null) \
	or not event.pressed \
	or event.echo: return

	var handled = false
	if event.control:
		if (event.scancode == KEY_Z):
			_storyList_undo()
			handled = true
		if (event.scancode == KEY_Y):
			_storyList_redo()
			handled = true

	if handled:
		get_tree().set_input_as_handled()

func _on_storyView_gui_input(event):
	event = (event as InputEventMouseButton)
	if (event == null) \
	or not event.pressed: return

	if event.button_index == BUTTON_RIGHT:
		storyTypePopup.set_payload({
			position = storyView.get_local_mouse_position()
		})
		storyTypePopup.popup_at()

