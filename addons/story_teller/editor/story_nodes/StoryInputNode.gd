tool
extends _StoryBaseNode

export (NodePath) var IdInput
export (NodePath) var IntroInput
export (NodePath) var TypeSelect
export (NodePath) var NameInput
export (NodePath) var ConstraintsLabel
export (NodePath) var MinInput
export (NodePath) var MaxInput

# -----------------------------------------------------------------------------

var input_id = -1

var current_type = -1
var current_name = ""

func get_data():
	_data.id = (get_node(IdInput) as LineEdit).text
	_data.content = (get_node(IntroInput) as LineEdit).text

	_data.input_type = typeSelect.get_item_metadata(typeSelect.selected)
	_data.input_name = (get_node(NameInput) as LineEdit).text

	_data.input_min = (get_node(MinInput) as SpinBox).value
	_data.input_max = (get_node(MaxInput) as SpinBox).value

	return .get_data()


func update_data(data: Dictionary):
	.update_data(data)

	(get_node(IdInput) as LineEdit).text = data('id', '')
	(get_node(IntroInput) as LineEdit).text = data('content', '')

	(get_node(NameInput) as LineEdit).text = data('input_name', '')
	_update_input_data((get_node(NameInput) as LineEdit).text)

	_select_type(data('input_type', st.INPUTTYPE_STRING))

	(get_node(MinInput) as SpinBox).value = data('input_min', 0)
	(get_node(MaxInput) as SpinBox).value = data('input_max', 0)


# -----------------------------------------------------------------------------

var typeSelect: OptionButton

func _ready():
	typeSelect = (get_node(TypeSelect) as OptionButton)

	expected_data['input_name'] = ''
	expected_data['input_type'] = st.INPUTTYPE_STRING
	expected_data['input_min'] = 0
	expected_data['input_max'] = 0

	typeSelect.connect("item_selected", self, "_on_type_selected")
	(get_node(NameInput) as LineEdit).connect("text_changed", self, "_update_input_data")

	fix_view()

func remove():
	ste.delete_data(current_type, input_id)
	.remove()


func _update_input_data(name):
	current_name = ste.str_to_key(name)
	_assure_exists()
	ste.rename_data(st.TYPE_INPUT, input_id, current_name, true)


func _build_typeInput():
	var types = [
		{name = "String", value = st.INPUTTYPE_STRING},
		{name = "Number", value = st.INPUTTYPE_FLOAT}
	]

	typeSelect.clear()
	for t in types:
		typeSelect.add_item(t.name)
		typeSelect.set_item_metadata(typeSelect.get_item_count()-1, t.value)

	#_select_type(data('input_type', st.INPUTTYPE_STRING))

func _select_type(type: int):
	if typeSelect == null: return

	if current_type == -1: _build_typeInput()

	var i = 0
	while i < typeSelect.get_item_count():
		if typeSelect.get_item_metadata(i) == type:
			typeSelect.select(i)
			_on_type_selected(i)
			break
		i += 1


func _on_type_selected(idx):
	current_type = typeSelect.get_item_metadata(idx)
	var label = (get_node(ConstraintsLabel) as Label)

	label.text = ""
	if current_type == st.INPUTTYPE_STRING: label.text = "SIZE "
	elif current_type == st.INPUTTYPE_FLOAT: label.text = "VALUE "
	label.text += "CONSTRAINTS"

	_assure_exists()
	ste.set_ini_val(st.TYPE_INPUT, input_id, current_type, true)


func _assure_exists():
	if input_id == -1:
		input_id = ste.add_data(st.TYPE_INPUT, current_name, st.INPUTTYPE_STRING, false)