extends LineEdit

class_name CommandArea

export (bool) var empty_is_previous_command = false

var history = []
var index = 0

# emitted when a command is entered
# [code]comman[/code] is the command entered
signal command_entered( command )

# clear the history of commands entered
func clear_history():
	history.clear()

# -------------------------------------------------------------------------

func _ready() -> void:
	connect('text_entered', self, '_on_text_entered')
	grab_focus()

func _input(_event: InputEvent) -> void:
	if (not _event is InputEventKey) or _event.echo: return

	if not _event.is_pressed() \
	and ((_event.scancode == KEY_UP) or (_event.scancode == KEY_DOWN)):
		caret_position = len(text)
		return

	if _event.scancode == KEY_UP and index > 0:
		index -= 1
		text = history[ index ]
	if _event.scancode == KEY_DOWN and index < history.size():
		index += 1
		text = '' if (index == history.size()) else history[ index ]


func _on_text_entered(new_text: String) -> void:
	var histlen = history.size()

	if new_text.empty():
		if empty_is_previous_command and (histlen > 0):
			new_text = history[histlen - 1]

	if new_text.empty():
		new_text = new_text.strip_edges()

		if not new_text in history:
			history.append( new_text )

	emit_signal('command_entered', new_text)
	index = history.size()
	text = ''
