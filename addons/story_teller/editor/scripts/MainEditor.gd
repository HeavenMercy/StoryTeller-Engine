tool
extends Control

class_name MainEditor

export (NodePath) var StoryChunkEditor
export (NodePath) var ConditionUpdateEditor
export (NodePath) var DataEditor
export (NodePath) var ConfirmDialog
export (NodePath) var SaveFileDialog

export (NodePath) var StoryView
export (NodePath) var StartNode
export (NodePath) var EndNode
export (PackedScene) var BaseStoryChunkNode
export (PackedScene) var BaseCommandNode

export (NodePath) var MenuContainer
export (NodePath) var StoryList

export (String) var NewFilename = ""

# ---------------------------------------------------------------------------------------

var edited_node
var edited_condUpd

var to_save: bool = false
var file = File.new()

var menu_config = [
	{
		name="File",
		items=[
			{name="Open", target=self, action="open_file", shortcut={scancode=KEY_O, ctrl=true}},
			{name="                           "},
			{name="Save", target=self, action="save_file", shortcut={scancode=KEY_S, ctrl=true}},
			{name="Save As...", target=self, action="save_file_as", shortcut={scancode=KEY_S, ctrl=true, shift=true}},
			{name="Save All", target=self, action="save_all"},
			{name="                           "},
			{name="Close", target=self, action="close_current_story", shortcut={scancode=KEY_W, ctrl=true}}
		]
	},
	{
		name="Edit",
		items=[
			{name="Open Data Editor", target="dataEditor", action="open", shortcut={scancode=KEY_E, ctrl=true}},
			{name="                           "},
			{name="Clear Data", target=self, action="clear_data"},
			{name="                           "},
			{name="Clear View", target=self, action="delete_nodes", shortcut={scancode=KEY_L, ctrl=true}}
		]
	}
]

var last_node_id = -1
var last_offset = Vector2.ZERO
func build_chunk_node(pos: Vector2 = Vector2.ZERO, shiftFlag: int = 0):
	var node = BaseStoryChunkNode.instance()
	node.mainEditor = self
	node.graphEdit = storyView

	node.offset = _update_position(node.rect_size, pos)
	if shiftFlag < 0: node.offset -= node.rect_size * Vector2(1, .5)
	elif shiftFlag > 0: node.offset -= node.rect_size * Vector2(0, .5)

	node.fix_offset()

	last_node_id += 1
	node._data.id = "Chunk_"+str(last_node_id)

	return node

func edit_node(node, for_condition: bool = false):
	edited_node = node
	storyChunkEditor.open(edited_node._data)

func update_nodeData(data):
	if edited_node:
		_undoRedo.create_action("update '" + str(edited_node.name) + "' data")
		_undoRedo.add_undo_method(edited_node, "update_data", edited_node.get_data())
		_undoRedo.add_do_method(edited_node, "update_data", data)
		_undoRedo.commit_action()
		set_current_as_modified(true)

func edit_condUpd(condUpd):
	edited_condUpd = condUpd

	conditionUpdateEditor.open(
		("Condition Editor" if edited_condUpd._fortest else "Update Editor"),
		edited_condUpd._fortest, edited_condUpd._data )

func update_condUpdData(data):
	if edited_condUpd: edited_condUpd.update_data(data)

func build_command_node(ns_id: int, auto_add: bool = false):
	var node = BaseCommandNode.instance()
	node.graphEdit = storyView
	node.mainEditor = self
	node.set_namespace(ns_id)
	if auto_add:
		storyView.add_child(node)
		set_current_as_modified(true)

	node.offset = _update_position(node.rect_size)
	if dataEditor.visible:
		dataEditor.get_ns_node(ns_id)._count = get_cmd_count(ns_id)

	return node

func get_cmd_count(ns_id: int = -1):
	var count = 0
	for node in storyView.get_children():
		if not (node is GraphNode) \
		or (node == start) or (node == end):
			continue

		if (node.NodeType == 2) and \
			((ns_id == -1) or (node.namespace_id == ns_id)):
			count += 1

	return count

func link_from_new_node(to: String, to_slot: int, position: Vector2):
	var node = build_chunk_node(position, -1)
	storyView.add_child(node)

	var data = {
		node_name = node.name,
		offset = node.offset,
		data = node._data
	}
	node.remove()

	_undoRedo.create_action("create node '" + data.node_name + "'")
	_undoRedo.add_undo_method(self, "delete_node", data.node_name)
	_undoRedo.add_do_method(self, "build_node", false, data, [{from=data.node_name, from_port=0, to=to, to_port=to_slot}])
	_undoRedo.commit_action()

func link_to_new_node(from: String, from_slot: int, position: Vector2):
	var from_node = storyView.get_node(from)

	if (from_node != start) and (from_node != end) \
	and (from_node.OnePerPort):
		for conn in storyView.get_connection_list():
			if (conn.from == from) and (conn.from_port == from_slot):
				return

	var node = build_chunk_node(position, 1)
	storyView.add_child(node)

	var data = {
		node_name = node.name,
		offset = node.offset,
		data = node._data
	}
	node.remove()

	_undoRedo.create_action("create node '" + data.node_name + "'")
	_undoRedo.add_undo_method(self, "delete_node", data.node_name)
	_undoRedo.add_do_method(self, "build_node", false, data, [{from=from, from_port=from_slot, to=data.node_name, to_port=0}])
	_undoRedo.commit_action()

func link_to_node(from: String, from_slot: int, to: String, to_slot: int):
	var from_node = storyView.get_node(from)

	for conn in storyView.get_connection_list():
		if (conn.from == from) and (conn.from_port == from_slot):
			if (conn.to == to) and (conn.to_port == to_slot):
				storyView.disconnect_node(conn.from, conn.from_port, conn.to, conn.to_port)
				return
			elif (from_node != start) and (from_node != end) and (from_node.OnePerPort):
				return

	storyView.connect_node(from, from_slot, to, to_slot)
	set_current_as_modified(true)


func save_file(force_dialog: bool = false, backup_first: bool = true):
	to_save = true
	if backup_first:
		_storyList_backup(_storyList_current_idx)

	var filepath = storyList.get_item_metadata(_storyList_current_idx).path
	if file.file_exists(filepath) and not force_dialog:	
		apply_action(filepath)
	else:
		saveFileDialog.mode = FileDialog.MODE_SAVE_FILE
		saveFileDialog.popup_centered()

func save_file_as(): save_file(true)

func save_all():
	_storyList_backup(_storyList_current_idx)

	var i = 1
	while i < storyList.get_item_count():
		_storyList_current_idx = i
		save_file(false, false)
		i += 1

	_storyList_current_idx = storyList.get_selected_items()[0] if storyList.is_anything_selected() else 0

func open_file():
	to_save = false
	_storyList_backup(_storyList_current_idx)

	saveFileDialog.mode = FileDialog.MODE_OPEN_FILE
	saveFileDialog.popup_centered()

func apply_action(filepath: String):
	if to_save:
		if file.open(filepath, File.WRITE) != OK: return
		file.store_var(storyList.get_item_metadata(_storyList_current_idx).data)
		file.close()

		saveFileDialog.invalidate()
		set_current_as_modified(false)

		if _storyList_current_idx == 0:
			delete_nodes(false, false)
			set_current_as_modified(false)
			_storyList_edit_story(filepath, storyList.get_item_metadata(0).data)
			storyList.get_item_metadata(0).data = {}
	else:
		if file.open(filepath, File.READ) != OK: return
		var data = file.get_var()
		file.close()

		if data == null: return
		_storyList_edit_story(filepath, data)


func delete_node(node_name: String):
	for node in storyView.get_children():
		if node.name == node_name:
			node.remove()
			set_current_as_modified(true)
			return true
	return false

func build_node(is_command: bool, node_data, connections=[]):
	var node
	if not is_command:
		node = build_chunk_node()
	else:
		node = build_command_node(node_data.data.namespace_id)

	if not node_data.node_name.empty():
		node.name = node_data.node_name
	storyView.add_child(node)
	node.update_data(node_data.data)
	node.offset = node_data.offset
	set_current_as_modified(true)

	for conn in connections:
		storyView.connect_node(conn.from, conn.from_port, conn.to, conn.to_port)

func duplicate_nodes():
	for node in storyView.get_children():
		if not ((node is GraphNode) and node.selected) \
		or (node == start) or (node == end): continue

		node.selected = false

		var tmp_node
		if node.NodeType == 1:
			tmp_node = build_chunk_node()
		elif node.NodeType == 2:
			tmp_node = build_command_node(node.namespace_id)
		
		storyView.add_child(tmp_node)

		var data = {
			node_name = tmp_node.name,
			data = node.get_data(),
			offset = node.offset + (Vector2.ONE * OFFSET)
		}
		tmp_node.remove()

		_undoRedo.create_action("duplicate Story node", UndoRedo.MERGE_ALL)
		_undoRedo.add_undo_method(self, "delete_node", data.node_name)
		_undoRedo.add_do_method(self, "build_node", (node.NodeType == 2), data)
		_undoRedo.commit_action()

func delete_nodes(selected_only: bool= false, with_undo := true):
	for node in storyView.get_children():
		if (node == start) or (node == end) \
		or not ((node is GraphNode) and ((not selected_only) or node.selected)): continue

		if (node.NodeType == 1) \
		or (node.NodeType == 2):
			if with_undo: node._delete(UndoRedo.MERGE_ALL)
			else: node.remove()
			set_current_as_modified(true)

func change_namespace(cmd_node):
	edited_node = cmd_node
	dataEditor.for_cmd = true
	dataEditor.open()

func on_namespace_selected(target: Dictionary = {}):
	if edited_node != null:
		_undoRedo.create_action("set '" + edited_node.get_command_name() + "' namespace")
		_undoRedo.add_undo_method(edited_node, "set_namespace", edited_node.namespace_id)
		_undoRedo.add_do_method(edited_node, "set_namespace", target.id)
		_undoRedo.commit_action()
		dataEditor.visible = false

func clear_data(choice = -1):
	if choice == -1:
		confirmDialog.set_buttons("Yes", "No")
		confirmDialog.open("Delete all data?", "All the data and the custom namespaces will also be permanently deleted." +
			"Do you really want to clear all data?", self, "clear_data")
	elif choice == 1:
		stedb.clear_data()
		set_current_as_modified(true)
		for node in storyView.get_children():
			if (node == start) or (node == end) \
			or not (node is GraphNode): continue
	
			if (node.NodeType == 2) \
			and (node.namespace_id != 0):
				node.remove()

# ---------------------------------------------------------------------------------------

var storyChunkEditor: WindowDialog
var conditionUpdateEditor: WindowDialog
var dataEditor: WindowDialog
var saveFileDialog: FileDialog

var confirmDialog

var storyView: GraphEdit
var storyList: ItemList

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

	storyView = (get_node(StoryView) as GraphEdit)
	storyList = (get_node(StoryList) as ItemList)

	storyView.get_zoom_hbox().visible = false
	start = get_node(StartNode)
	end = get_node(EndNode)

	storyChunkEditor.connect("data_save_request", self, "update_nodeData")
	conditionUpdateEditor.connect("data_save_request", self, "update_condUpdData")
	saveFileDialog.connect("file_selected", self, "apply_action")
	storyList.connect("item_selected", self, "_storyList_on_item_selected")

	storyView.connect("connection_from_empty", self, "link_from_new_node")
	storyView.connect("connection_to_empty", self, "link_to_new_node")
	storyView.connect("connection_request", self, "link_to_node")
	storyView.connect("duplicate_nodes_request", self, "duplicate_nodes")
	storyView.connect("delete_nodes_request", self, "delete_nodes", [true])

	var i = -1; var j = -1
	var tmp: MenuButton
	for menu in menu_config:
		i += 1; j=-1
		tmp = MenuButton.new()
		tmp.text = menu.name
		for item in menu.items:
			j += 1
			tmp.get_popup().add_item(item.name)
			tmp.get_popup().set_item_disabled(j, (item.name.strip_edges() == ""))
			if item.has('shortcut'):
				var shortcut = ShortCut.new()
				var key = InputEventKey.new()
				key.scancode = item.shortcut.scancode
				key.control = item.shortcut.get('ctrl', false)
				key.shift = item.shortcut.get('shift', false)
				key.alt = item.shortcut.get('alt', false)
				shortcut.shortcut = key
				tmp.get_popup().set_item_shortcut(j, shortcut, true)
		tmp.get_popup().connect("id_pressed", self, "_on_id_pressed", [i])
		get_node(MenuContainer).add_child(tmp)

	conditionUpdateEditor.connect("select_data", self, "_select_data")
	dataEditor.conditionUpdateEditor = conditionUpdateEditor

	saveFileDialog.filters = PoolStringArray(["*" + st.StoryInterpreter.FileExt + " ; StoryTeller File"])
	storyChunkEditor.mainEditor = self
	dataEditor.mainEditor = self

	storyList.clear()
	_storyList_edit_story(NewFilename, {})

func _physics_process(delta):
	if (storyChunkEditor == null) or not storyChunkEditor.is_open:
		if conditionUpdateEditor != null: conditionUpdateEditor.close()

func _on_id_pressed(item_id, menu_id):
	var item = menu_config[menu_id].items[item_id]
	if item == null: return

	if item.target is String:
		item.target = get(item.target)
	item.target.call_deferred(item.action)

const OFFSET = 50
func _update_position(size: Vector2, pos: Vector2 = Vector2.ZERO):
	if pos == Vector2.ZERO:
		pos = last_offset + (Vector2.ONE * OFFSET)

	last_offset = pos
	if not Rect2(storyView.scroll_offset, rect_size)\
		.encloses(Rect2( (last_offset + storyView.scroll_offset), size )):
		last_offset = Vector2(2, 3) * OFFSET

	return last_offset + storyView.scroll_offset

func _delete_command_nodes(ns_id: int = -1):
	for node in storyView.get_children():
		if(not(node is GraphNode) or (node == start) or (node == end)): continue

		if (ns_id == -1) or ((node.NodeType == 2) and (node.namespace_id == ns_id)):
			delete_node(node.name)

func _update_command_nodes(ns_id: int = -1):
	for node in storyView.get_children():
		if(not(node is GraphNode) or (node == start) or (node == end)): continue

		if (ns_id == -1) or ((node.NodeType == 2) and (node.namespace_id == ns_id)):
			node.set_namespace(ns_id)

func _select_data():
	dataEditor.for_test = edited_condUpd._fortest
	dataEditor.open()

# ------------------------------------------------------------------------

var _undoRedo: UndoRedo
var _storyList_current_idx = -1
var storyTree = {}


func set_current_as_modified(modified = false):
	var current = storyList.get_item_metadata(_storyList_current_idx)
	if (current != null) and (current.modified != modified):
		var modified_mark = " [*]"
		current.modified = modified
		if modified: storyList.set_item_text(_storyList_current_idx,
			storyList.get_item_text(_storyList_current_idx) + modified_mark)
		else: storyList.set_item_text(_storyList_current_idx,
			storyList.get_item_text(_storyList_current_idx).replace(modified_mark, "") )

func is_current_modified():
	var current = storyList.get_item_metadata(_storyList_current_idx)
	if current == null: return false
	return current.modified

func close_current_story(choice = -1):
	if choice == -1:
		if is_current_modified():
			confirmDialog.set_buttons("Save and Close", "Cancel", "Ignore Changes")
			confirmDialog.open("Close Story?", "The file has unsaved modifications. Do you really want to close it?",
				self, "close_current_story")
		else: close_current_story(1)
		return
	elif choice == 1: save_file()
	elif choice == 2: return

	if _storyList_current_idx == 0:
		delete_nodes(false, false)
		set_current_as_modified(false)
		storyList.get_item_metadata(0).data = {}
	else:
		_storyList_close_story(_storyList_current_idx)


func _storyTree_register_path(path):
	var target = storyTree

	var path_parts = path.replace('res://', '').split('/')
	path_parts.invert()
	for part in path_parts:
		if not target.has(part): target[part] = {}
		target = target[part]

func _storyTree_unregister_path(path):
	var target = storyTree

	var path_parts = path.replace('res://', '').split('/')
	path_parts.invert()
	for part in path_parts:
		if not target.has(part): break
		if len(target[part]) < 2:
			target.erase(part)
			break
		target = target[part]

func _storyTree_get_name(path):
	var target = storyTree
	var name = ""

	var path_parts = path.replace('res://', '').split('/')
	path_parts.invert()
	for part in path_parts:
		name = part + ('/' if len(name) > 0 else '') + name
		if not target.has(part) or (len(target[part]) < 2): break
	
	return name


func _storyList_update_item_names():
	var i = 0
	while i < storyList.get_item_count():
		storyList.set_item_text(i,
			_storyTree_get_name(storyList.get_item_metadata(i).path))
		i += 1

func _storyList_edit_story(path, data):
	var i = 0
	while i < storyList.get_item_count():
		if path == storyList.get_item_metadata(i).path:
			print("Test Only: path found!")
			storyList.select(i)
			return
		i += 1

	_storyTree_register_path(path)
	_storyList_update_item_names()

	storyList.add_item(_storyTree_get_name(path))
	storyList.set_item_metadata(i, {
		path=path,
		data=data, modified=false,
		undoRedo=UndoRedo.new()
	})

	storyList.select(i)
	_storyList_on_item_selected(i)

func _storyList_close_story(idx):
	if idx < 1: return

	var to_remove = idx
	if idx < (storyList.get_item_count() - 1):
		to_remove += 1
		storyList.move_item(to_remove-1, to_remove)

	var path = storyList.get_item_metadata(to_remove).path

	storyList.select(to_remove-1)
	_storyList_on_item_selected(to_remove-1, false)
	storyList.remove_item(to_remove)

	_storyTree_unregister_path(path)
	_storyList_update_item_names()

func _storyList_backup(idx):
	if (idx == -1) or (idx >= storyList.get_item_count()): return

	var data = {
		last_node_id = last_node_id,

		namespaces = stedb.namespaces,
		locks = stedb.locks,
		values = stedb.values,

		scroll_offset = storyView.scroll_offset,
		links = storyView.get_connection_list(),

		start_offset = start.offset,
		end_offset = end.offset,

		story_chunks = [],
		commands = [],
	}

	for node in storyView.get_children():
		if not (node is GraphNode) \
		or (node == start) or (node == end):
			continue

		if node.NodeType == 1: data.story_chunks \
			.append({node_name=node.name, data=node.get_data(), offset=node.offset})
		elif node.NodeType == 2: data.commands \
			.append({node_name=node.name, data=node.get_data(), offset=node.offset})

	storyList.get_item_metadata(idx).data = data

func _storyList_on_item_selected(idx, backup = true):
	if backup: _storyList_backup(_storyList_current_idx)

	_storyList_current_idx = idx
	_undoRedo = storyList.get_item_metadata(idx).undoRedo

	var last_modified = storyList.get_item_metadata(idx).modified
	var data = storyList.get_item_metadata(idx).data

	delete_nodes(false, false)

	last_node_id = data.get('last_node_id', -1)

	stedb.namespaces = data.get('namespaces', [])
	stedb.values = data.get('values', [])
	stedb.locks = data.get('locks', [])

	storyView.scroll_offset = data.get('scroll_offset', Vector2.ZERO)
	start.offset = data.get('start_offset', Vector2(50,200))
	end.offset = data.get('end_offset', Vector2(500,200))

	var node
	for c in data.get('story_chunks', []): build_node(false, c)
	for c in data.get('commands', []): build_node(true, c)

	for l in data.get('links', []):
		storyView.connect_node(l.from, l.from_port, l.to, l.to_port)

	set_current_as_modified(last_modified)


func _input(event):
	if not visible: return

	event = (event as InputEventKey)
	if (event == null) \
	or not event.pressed \
	or event.echo: return

	var handled = false
	if event.control and (_undoRedo != null):
		if (event.scancode == KEY_Z):
			if _undoRedo.has_undo(): _undoRedo.undo()
			handled = true
		if (event.scancode == KEY_Y):
			if _undoRedo.has_redo(): _undoRedo.redo()
			handled = true

	if handled:	
		get_tree().set_input_as_handled()
