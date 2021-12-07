tool
extends _StoryBaseNode

export (NodePath) var ContentLabel
export (NodePath) var EditBtn
export (NodePath) var DelayLabel

# -----------------------------------------------------------------------------

func update_data(data: Dictionary):
	.update_data(data)

	(get_node(ContentLabel) as Label).text = data('content', '')

	var delay = data('delay', 0)
	var delayView = (get_node(DelayLabel) as Label)

	delayView.visible = (delay > 0)
	delayView.text = 'after delay of ' + str(delay) + ' secs'

	fix_view()

# -----------------------------------------------------------------------------

func _ready():
	expected_data['delay'] = 0
	expected_data['updates'] = []
	expected_data['conditions'] = []
	expected_data['inverse_condition'] = false

	get_node(EditBtn).connect('pressed', mainEditor, 'edit_node', [self])
