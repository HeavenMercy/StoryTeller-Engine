tool
extends _StoryBaseNode

export (NodePath) var IdInput
export (NodePath) var IntroInput
export (NodePath) var AddOptionBtn

export (PackedScene) var BaseChoiceLine

# -----------------------------------------------------------------------------

func get_data():
	_data.id = (get_node(IdInput) as LineEdit).text
	_data.content = (get_node(IntroInput) as LineEdit).text

	_data.choices = []
	for node in get_children():
		if node is StoryChoiceLine:
			_data.choices.append(node.get_data())

	return .get_data()


func update_data(data: Dictionary):
	.update_data(data)

	(get_node(IdInput) as LineEdit).text = data('id', '')
	(get_node(IntroInput) as LineEdit).text = data('content', '')

	for child in get_children():
		if child is StoryChoiceLine:
			child.delete_option()

	for choice in data('choices', []):
		add_choice().set_from_data(choice)


func add_choice():
	var count = get_child_count()
	var choice = BaseChoiceLine.instance()

	add_child(choice)
	choice.update_index()
	set_slot(count, false,0,Color.white, true,0,Color.white)
	choice.connect('choice_line_deleted', self, '_on_choice_line_deleted')

	mainEditor._storyList_set_modified("add choice in node [" + get_name() + "]")

	return choice

# -----------------------------------------------------------------------------

var idInput

func _ready():
	idInput = (get_node(IdInput) as LineEdit)

	expected_data['choices'] = []

	fix_view()
	get_node(AddOptionBtn).connect('pressed', self, 'add_choice')
	idInput.connect('focus_exited', self, '_update_id')


func _update_id(id: String = ""):
	if id.empty(): id = idInput.text
	id = ste.str_to_key(id)

	var last_caret_pos = idInput.caret_position
	idInput.text = id
	idInput.caret_position = last_caret_pos

	_data.id = id
	update_title()
	mainEditor._update_node_listview(0)
	mainEditor._storyList_set_modified("change id of choice to [" + get_name() + "]")


func _on_choice_line_deleted(obj):
	unlink(obj._index)
	fix_view()

	for child in get_children():
		if not child is StoryChoiceLine: continue

		var last_index = child._index
		child.update_index()
		update_from_port(last_index, child._index)

	mainEditor._storyList_set_modified("delete choice in node [" + get_name() + "]")
