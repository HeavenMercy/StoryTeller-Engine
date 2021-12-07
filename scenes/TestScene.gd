extends Panel

var TestSceneStory := preload('TestScene.story.gd')

class MyStoryListener extends st.StoryListener:
	var global
	func _init(_global: Node):
		global = _global

	# a chunk listener with the name identical to the id the chunk listened
	func ignored(payload):
		if payload[st.StoryChunkPayloadKeys.is_last_position]:
			global.output.show_text('[color=red]Seems like you did something wrong[/color]')



var teller = null

onready var input = $VBoxContainer/ST_CommandArea
onready var output = $VBoxContainer/ST_DialogArea

func get_teller(from_script := false, with_choice := false):
	var _teller
	var _listener = MyStoryListener.new(self)

	if from_script:
		_teller = TestSceneStory.new(_listener).teller
	else:
		var story_name = ('test_with_choices' if with_choice else 'test_with_commands')
		# story_name = 'test_with_input' # force a story

		_teller = st.get_default_interpreter() \
			.set_base_path('res://assets/stories') \
			.load_story(story_name, _listener)

	return _teller

func _ready():
	teller = get_teller(false, false)
	input.connect('command_entered', self, '_on_command_entered')


func _on_command_entered(command) -> void:
	if command.empty(): output.skip_animation()
	else: teller.execute( command )

func _process(delta):
	var text = teller.tell( delta )
	if (text != null) and not text.empty(): output.show_text( text )
