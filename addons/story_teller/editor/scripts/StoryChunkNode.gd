tool
extends StoryBaseNode

export (NodePath) var ContentLbl
export (NodePath) var ElseLbl
export (NodePath) var EditBtn
export (NodePath) var AddChoiceBtn
export (NodePath) var ConditionToggleBtn

export (PackedScene) var StoryChoiceLineBase

# ---------------------------------------------------------------------------

var _data = {
	id = "",
	content = "",
	delay = 0,

	condition_only = false, # only a condition node
	inverse_condition = false,
	conditions = [], # array of array (pages) of condition
	updates = [] # array of updates
}

func add_choice():
	var count = get_child_count()
	var choice = StoryChoiceLineBase.instance()

	add_child(choice)
	set_slot(count, false,0,Color.white, true,0,Color.white)
	choice.connect("choice_line_deleted", self, "_on_choice_line_deleted")

	mainEditor.set_current_as_modified(true)

	return choice

func get_data():
	var ret = _data
	ret.choices = []

	for child in get_children():
		if child.get_index() < 3: continue
		ret.choices.append(child.get_data())

	return _data

func update_data(data: Dictionary):
	_data = data.duplicate(true)
	toggle_condition(_data.condition_only)
	contentLbl.text = _data.content
	title = str(_data.id)

	var _tmp
	_data.erase('choices')
	for choice in data.get('choices', []):
		_tmp = add_choice()
		_tmp.set_from_data(choice)

func toggle_condition(pressed: bool):
	if not pressed: unlink(1)

	conditionToggleBtn.pressed = pressed
	_data.condition_only = pressed
	elseLbl.visible = pressed
	set_slot(1, false,0,Color.white, pressed,0,Color.white)
	mainEditor.set_current_as_modified(true)

# ---------------------------------------------------------------------------------------

var contentLbl: Label
var elseLbl: Label
var conditionToggleBtn: Button
var addChoiceBtn: Button

var mainEditor

func _ready():
	# fix strange size
	set_size( Vector2(rect_size.x, 0) )

	contentLbl = (get_node(ContentLbl) as Label)
	elseLbl = (get_node(ElseLbl) as Label)
	conditionToggleBtn = (get_node(ConditionToggleBtn) as Button)
	addChoiceBtn = (get_node(AddChoiceBtn) as Button)

	connect("close_request", self, "_delete")
	conditionToggleBtn.connect("toggled", self, "toggle_condition")
	addChoiceBtn.connect("pressed", self, "add_choice")

func _delete(merge_mode: int = UndoRedo.MERGE_DISABLE):
	var undo_redo = mainEditor._undoRedo
	undo_redo.create_action("delete Story node", merge_mode)
	undo_redo.add_undo_method(mainEditor, "build_node",
		false, {node_name=name, data=get_data(), offset=offset}, get_connections())
	undo_redo.add_do_method(mainEditor, "delete_node", name)
	undo_redo.commit_action()

var set = false
func _physics_process(delta):
	conditionToggleBtn.visible = (get_child_count() <= 3)
	addChoiceBtn.visible = not conditionToggleBtn.pressed and not (is_linked_on_port(0) and (get_child_count() <= 3))
	set_slot(0, true,0,Color.white, (get_child_count() <= 3),0,Color.white)

	if not set and mainEditor:
		(get_node(EditBtn) as Button).connect("pressed", mainEditor, "edit_node", [self])
		set = true


func _on_choice_line_deleted(obj):
	unlink(obj._index)
	set_size( Vector2(rect_size.x, 0) )

	for child in get_children():
		if child.get("_index") == null: continue

		var last_index = child._index
		child._index = child.get_index()
		update_from_port(last_index, child._index)

	mainEditor.set_current_as_modified(true)
