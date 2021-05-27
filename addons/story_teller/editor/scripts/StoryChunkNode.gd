tool
extends StoryBaseNode

export (NodePath) var ContentLbl
export (NodePath) var ElseLbl
export (NodePath) var EditBtn
export (NodePath) var ConditionToggleBtn


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

func get_data(): return _data

func update_data(data: Dictionary):
	_data = data.duplicate(true)
	toggle_condition(_data.condition_only)
	contentLbl.text = _data.content
	title = str(_data.id)

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

var mainEditor

func _ready():
	contentLbl = (get_node(ContentLbl) as Label)
	elseLbl = (get_node(ElseLbl) as Label)
	conditionToggleBtn = (get_node(ConditionToggleBtn) as Button)

	connect("close_request", self, "_delete")
	conditionToggleBtn.connect("toggled", self, "toggle_condition")

func _delete(merge_mode: int = UndoRedo.MERGE_DISABLE):
	var undo_redo = mainEditor._undoRedo
	undo_redo.create_action("delete Story node", merge_mode)
	undo_redo.add_undo_method(mainEditor, "build_node",
		false, {node_name=name, data=get_data(), offset=offset}, get_connections())
	undo_redo.add_do_method(mainEditor, "delete_node", name)
	undo_redo.commit_action()

var set = false
func _physics_process(delta):
	if not set and mainEditor:
		(get_node(EditBtn) as Button).connect("pressed", mainEditor, "edit_node", [self])
		set = true

