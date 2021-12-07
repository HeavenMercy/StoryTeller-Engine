extends Label

var t

func _ready():
	var l = st.StoryListener.new({},{
		age = '20',
		adult_min_age = 18
	})

	l.set_value(st.StoryValue.new(st.StoryListener.option_to_value(st.NAMESPACE_DEFAULT, 'year', 'pass'), 26))

	l.get_value('age').add(st.StoryListener.option_to_value('_default', 'year', 'pass'))._apply(l)

	l.load_commands([
		st.StoryCommandNamespace.new('_default', true) \
			.add_command(st.StoryCommand.new('command_1', 'chunk_1')) \
			.add_command(st.StoryCommand.new('command_2').add_option('option_1', 'chunk_3', st.OPTTYPE_NOVALUE)),

		st.StoryCommandNamespace.new('namespace_1', true) \
			.add_command(st.StoryCommand.new('command_1', 'chunk_1')) \
			.add_command(st.StoryCommand.new('command_2').add_option('option_1', 'chunk_3', st.OPTTYPE_NOVALUE))
	])

	t = st.StoryTeller.new(l) \
		.load_story_chunks([
			st.StoryChunk.new('start', '{' + st.StoryListener.option_to_value('_default', 'year', 'pass')
				+ '} years passed... now you are {age} yo') \
				.register_next_chunks(['adult', 'twice_adult']),

			st.StoryChunk.new('adult', 'You are now an adult!') \
				.unlock_if([ l.get_value('age').gte('adult_min_age') ]),

			st.StoryChunk.new('twice_adult', 'Wow... You are twice an adult!') \
				.unlock_if([ l.get_value('age').eq( l.get_value('adult_min_age').mult(2) ) ])
		])

	t.set_start_point('start')

	Log('\n' + str(t.get_available_commands()))


func _physics_process(delta):
	var txt = t.tell(delta)
	if txt != null:
		Log(txt)
		Log(str(t.get_available_choices()))

func Log(what):
	if what: text += str(what) + '\n'
