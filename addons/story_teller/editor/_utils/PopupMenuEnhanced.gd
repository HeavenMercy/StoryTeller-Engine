tool
extends PopupMenu

class_name _PopupMenuEnhanced


signal data_selected(data)

# ------------------------------------------------------------

var payload

func set_payload(payload):
	self.payload = payload

# pops up at the given position
# if no position is given, the global cursor position used
func popup_at(pos := Vector2.ZERO, global := false):
	popup()
	set_as_minsize()
	if pos == Vector2.ZERO:
		set_global_position(get_global_mouse_position())
	else:
		if global: set_global_position(pos)
		else: set_position(pos)

# builds the structure of the popup
# [code]data[/code] is an array of [code]{'text':String, 'meta':Variant}[/code]
func configure(data: Array):
	clear()
	for d in data:
		if (d is Dictionary):
			if not d.has('text'): continue

			add_item(d.text)
			if d.has('meta'):
				set_item_metadata(get_item_count()-1, d.meta)

# ------------------------------------------------------------

func _ready():
	connect('index_pressed', self, '_on_index_pressed')

func _on_index_pressed(idx):
	var meta = get_item_metadata(idx)
	emit_signal('data_selected', {
		idx = idx,
		meta = meta,
		payload = payload
	})
