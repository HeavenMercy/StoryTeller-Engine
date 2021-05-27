extends RichTextLabel

class_name DialogArea

export (bool) var activate_bbcode = true
export (bool) var insert_newline = true

enum TypingSpeed{ OFF=999, LOW = 15, MEDIUM = 25, HIGH = 50 }
export (TypingSpeed) var typing_speed = TypingSpeed.OFF

# emitted when the display is updated
# [code]added_text[/code] is the text added to teh display
signal display_updated( added_text )

# emitted when there is no text to show.
# [code]delta[/code] is the elapsed from the last time there was no text to show
signal no_text_to_show( delta )


# to show a text in the display
func show_text( text: String ):
	_text += text + ("\n" if insert_newline else " ")

# skeps the typing animation
func skip_animation():
	if not _text.empty():
		_set_content( _get_content() + _text )
		_text = ""

# clears the display
func clear(): _set_content( "" )

# ---------------------------------------------------------------------------------

var _text = ""
var _char_delay = 0
var _delta_cumul = 0
var _empty_duration = 0

func _ready() -> void:
	set('bbcode_enabled', activate_bbcode)
	_char_delay = (1.0/typing_speed)

func _text_process(delta: float):
	_delta_cumul += delta
	_empty_duration += delta

	if _text.empty():
		emit_signal("no_text_to_show", _empty_duration)
		_empty_duration = 0
		return

	while _delta_cumul > _char_delay:


		var length = 0
		if _text.begins_with('['): length = _text.find(']')+1
		else: length = 1

		var text_chunk = _text.substr(0, length)
		_set_content( _get_content() + text_chunk )
		emit_signal("display_updated", text_chunk)
		_text = _text.right( length )
		_delta_cumul -= _char_delay

func _get_content():
	return (bbcode_text if activate_bbcode else text)

func _set_content(_text: String):
	if activate_bbcode:
		bbcode_text = _text
	else: text = _text


func _physics_process(delta: float) -> void:
	_text_process(delta)
