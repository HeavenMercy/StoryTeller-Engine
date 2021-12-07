tool
extends _GraphNodeEnhanced

class_name _StoryBaseNode

enum StoryType {
	Chunk = st.STORYTYPE_CHUNK,
	Condition = st.STORYTYPE_CONDITION,
	Choice = st.STORYTYPE_CHOICE,
	Input = st.STORYTYPE_INPUT }
export (StoryType) var type

# -----------------------------------------------------------------------------

var expected_data = {
	id = '',
	content = ''
}

var _data = {}


func data(key: String, def = null):
	if not key in expected_data: return def
	return _data.get(key, expected_data[key])

func get_name(): return data('id', '')

func get_type_text():
	if type == StoryType.Chunk: return 'Chunk'
	elif type == StoryType.Condition: return 'Condition'
	elif type == StoryType.Choice: return 'Choice'
	elif type == StoryType.Input: return 'Input'
	return ''


func get_data():
	var ret = {}
	for key in expected_data:
		ret[key] = _data.get(key, expected_data[key])
	return ret

func update_data(data: Dictionary):
	for key in data:
		if key in expected_data:
			_data[key] = data[key]

	update_title()


func update_title():
	title = get_type_text() + ': ' + data('id', '')

# -----------------------------------------------------------------------------

var mainEditor = null

func _ready():
	fix_view()
