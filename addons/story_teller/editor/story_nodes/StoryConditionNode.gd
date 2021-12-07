tool
extends _StoryBaseNode

export (NodePath) var IfLabel
export (NodePath) var EditBtn

# -----------------------------------------------------------------------------

func update_data(data: Dictionary):
	.update_data(data)

	(get_node(IfLabel) as Label).text = data('content', '')

	fix_view()

# -----------------------------------------------------------------------------

func _ready():
	expected_data['conditions'] = []
	expected_data['inverse_condition'] = false
	expected_data['condition_only'] = true

	get_node(EditBtn).connect('pressed', mainEditor, 'edit_node', [self, true])
