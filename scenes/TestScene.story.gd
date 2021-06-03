extends Object

var default_activate = false
var teller

func _init(listener: st.StoryListener = null).():
	if listener == null:
		listener = st.StoryListener.new(
			{ "useless_lock": true },
			{ "useless_value": 1.94 }
		)

	# listener.load_commands([
	# 	st.StoryCommandNamespace.new("_default", default_activate) \
	# 	.add_command(st.StoryCommand.new("hi", "said_hi")) \
	# 	.add_command(st.StoryCommand.new("ignore", "ignored"))
	# ])

	teller = st.StoryTeller.new(listener) \
		.load_story_chunks([
			st.StoryChunk.new("start", ["[color=yellow][wave]from script[/wave][/color]", ""]) \
				.register_next_chunks(["intro"]),

			st.StoryChunk.new("intro", ["The story teller says \"Hello\" to you!",
			"[color=gray]you can answer [color=aqua]hi[/color] or [color=aqua]ignore[/color] him[/color]"]) \
				.register_choice("hi", "You reply to the storyteller", ["said_hi"]) \
				.register_choice("ignore", "You ignore the storyteller", ["ignored"]),
				# .in_namespace("_default"),

			st.StoryChunk.new("said_hi", ["[color=gray]You reply to the storyteller.[/color]",
			"He smiles to  the ears like a freaking maniac.",
			"\"Welcome to my new world\", he says"]).end(),

			st.StoryChunk.new("ignored", ["[color=gray]You ignore the storyteller[/color]",
			"His eyes start to shine with a strange feeling of malice.",
			"\"Welcome to my new world\", he says"]).end()
		])

	teller.set_start_point("start")
