extends Node


const NAMESPACE_DEFAULT = '_default'

# Engine Constants

const CHUNKID_START = '_start'
const CHUNKID_END = '_end'

const OPTNAMESEP_NS = ':'
const OPTNAMESEP_CMD = '.'

const TYPE_NAMESPACE = 0
const TYPE_LOCK = 1
const TYPE_VALUE = 2
const TYPE_OPTION = 3
const TYPE_INPUT = 4

const STORYTYPE_CHUNK = 0
const STORYTYPE_CONDITION = 1
const STORYTYPE_CHOICE = 2
const STORYTYPE_INPUT = 3

const VALUETYPE_VALUE = 0
const VALUETYPE_TARGET = 1

# Engine Constants: END

const INPUTTYPE_STRING = 0
const INPUTTYPE_FLOAT = 1

const OPTTYPE_NOVALUE = 0
const OPTTYPE_ACCEPTVALUE = 1
const OPTTYPE_REQUIREVALUE = 2

const EXECCODE_NONE = 0
const EXECCODE_CHOICE = 1
const EXECCODE_COMMAND = 2
const EXECCODE_INPUT = 3

const UPDATE_ATEND = -1


# base class of StoryLock, StoryValue
class StoryData:
	const OPERATOR_NONE = 0

	var _name
	var _value
	var _operator

	func _init(name: String, value, operator: int=OPERATOR_NONE):
		_name = name.to_lower()
		_value = value
		_operator = operator

	func _apply( _listener: StoryListener ): pass
	func _check( _listener: StoryListener ) -> bool: return false


	func get_name(): return _name
	func get_value(): return _value
	func set_value(value): _value = value

# A lock to control access to story chunks
class StoryLock extends StoryData:
	const OPERATOR_SET=1
	const OPERATOR_TGL=2

	const OPERATOR_IS=-1
	const OPERATOR_ISN=-2

	func _init(name: String, value, operator: int=OPERATOR_NONE).(name, value, operator): pass


	func _apply( listener: StoryListener ):
		var lock = listener.get_lock(_name)

		if _operator == OPERATOR_SET:
			if _value is String: lock._value = bool(listener.get_lock(_value)._value)
			else: lock._value = bool(_value)
		elif _operator == OPERATOR_TGL: lock._value = not bool(lock._value)

		listener.set_lock( lock )

	func _check( listener: StoryListener ) -> bool:
		var value = listener.get_lock(_name)._value
		if _value is String: _value = bool(listener.get_value(_value)._value)

		match( _operator ):
			OPERATOR_IS: return (value == _value)
			OPERATOR_ISN: return (value != _value)

		return false


	func on() -> StoryLock:
		if _operator != OPERATOR_NONE: return self
		return StoryLock.new(_name, true, OPERATOR_SET)
	func off() -> StoryLock:
		if _operator != OPERATOR_NONE: return self
		return StoryLock.new(_name, false, OPERATOR_SET)
	func toggle() -> StoryLock:
		if _operator != OPERATOR_NONE: return self
		return StoryLock.new(_name, true, OPERATOR_TGL)

	func is_on() -> StoryLock:
		if _operator != OPERATOR_NONE: return self
		return StoryLock.new(_name, true, OPERATOR_IS)
	func is_off() -> StoryLock:
		if _operator != OPERATOR_NONE: return self
		return StoryLock.new(_name, false, OPERATOR_IS)

# A values to keep track of story data
# the parameter [code]value[/code] of the operation methods can be a [code]float[/code], a [code]String[/code] or a [code]StoryValue[/code]
class StoryValue extends StoryData:
	const OPERATOR_SET=1
	const OPERATOR_ADD=2
	const OPERATOR_MULT=3

	const OPERATOR_EQ=-1
	const OPERATOR_NEQ=-2
	const OPERATOR_LT=-3
	const OPERATOR_LTE=-4
	const OPERATOR_GT=-5
	const OPERATOR_GTE=-6

	func _init(name: String, value, operator: int=OPERATOR_NONE).(name, value, operator): pass


	func _eval( listener: StoryListener ) -> StoryValue:
		var value = listener.get_value(_name)

		var other_value = _value
		if _value is String:
			other_value = listener.get_value(_value)._value
		elif _value is StoryValue:
			other_value = _value._eval(listener)._value

		match( _operator ):
			OPERATOR_ADD: value._value += float(other_value)
			OPERATOR_MULT: value._value *= float(other_value)
			OPERATOR_SET: value._value = float(other_value)

		return value

	func _apply( listener: StoryListener ):
		var value = _eval(listener)
		listener.set_value( value )

	func _check( listener: StoryListener ) -> bool:
		var value = float(listener.get_value(_name)._value)

		if _value is String:
			_value = listener.get_value(_value)._value
		elif _value is StoryValue:
			_value = _value._eval(listener)._value

		match( _operator ):
			OPERATOR_EQ: return (value == float(_value))
			OPERATOR_NEQ: return (value != float(_value))
			OPERATOR_LT: return (value < float(_value))
			OPERATOR_LTE: return (value <= float(_value))
			OPERATOR_GT: return (value > float(_value))
			OPERATOR_GTE: return (value >= float(_value))

		return false


	func eq(value) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_EQ)
	func neq(value) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_NEQ)
	func lt(value) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_LT)
	func lte(value) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_LTE)
	func gt(value) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_GT)
	func gte(value) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_GTE)

	func add(value) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_ADD)
	func mult(value) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_MULT)
	func set_to(value) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_SET)


const StoryChunkPayloadKeys = {
	current_position = 'cur_pos',
	is_last_position = 'is_last_pos'
}
const StoryChunkChoiceKeys = {
	name = 'name',
	description = 'description',
	story_chunk_ids = 'story_chunk_ids'
}
const StoryChunkUpdateKeys = {
	at = 'at',
	data = 'data'
}

const StoryChunkInputKeys = {
	name = 'name',
	type = 'type',
	min = 'min',
	max = 'max'
}
# A chunk of story to show on command, after delay or directly
# [i]Can have condition to validate before showing them[/i]
class StoryChunk:
	var _id
	var _teller: StoryTeller
	var _delay = 0

	var _namespace_changes = []
	var _tests = []
	var _test_inversed = false
	var _next_updates = []

	var _content
	var _content_size
	var _content_position = 0

	var _next = []
	var _choices = {}
	var _end_story = false

	var _expected_input = null;

	# returns a normalize data.
	# useful for StoryInterpreter
	static func normalize_data(filler: Dictionary) -> Dictionary:
		var data = {
			id = '',
			content = '',
			delay = 0,

			conditions = [],
			condition_only = false,
			inverse_condition = false,

			updates = [],

			choices = [],

			input_name = '',
			input_type = INPUTTYPE_FLOAT,
			input_min = 0,
			input_max = 0
		}

		for key in filler: data[key] = filler[key]
		return data

	func _init(id: String, content: String = ''):
		_id = id.to_lower()
		_content = content.split('\n', true)
		_content_size = _content.size()

	func _is_locked():
		var lock = !_test_inversed

		if len(_tests) == 0: return !lock

		var unlocked
		for test in _tests:
			unlocked = true
			for t in test:
				unlocked = (unlocked && t._check( _teller._listener ))

			if unlocked: return !lock

		return lock

	func _get_text():
		if _is_locked():
			_teller._ignore_current_chunk()
			return

		# at the beginning of chunk
		if (_content_position == 0):
			for nsch in _namespace_changes:
				_teller._listener.set_command_namespace_state(
					nsch[ StoryCommandNsKeys.name ],
					nsch[StoryCommandNsKeys.active] )

		# at the end of chunk
		if (_content_position == _content_size):
			_content_position = 0
			_teller._ignore_current_chunk()

			for update in _next_updates:
				if update[StoryChunkUpdateKeys.at] == UPDATE_ATEND:
					update[StoryChunkUpdateKeys.data]._apply( _teller._listener )

			if _end_story: _teller.stop()
			else:
				_teller._register_chunks( _next )
				if _expected_input != null:
					_teller._expected_input = _expected_input
				elif (len(_choices) > 0):
					_teller._avail_choices.append(_choices.values())

			return

		# at each line of the chunk
		for update in _next_updates:
			if update[StoryChunkUpdateKeys.at] == _content_position:
				update[StoryChunkUpdateKeys.data]._apply( _teller._listener )


		var can_get_text = true
		if _teller._listener.has_method(_id):
			var payload = {
				StoryChunkPayloadKeys.current_position: _content_position,
				StoryChunkPayloadKeys.is_last_position: (_content_position >= (_content_size-1))
			}
			can_get_text = (_teller._listener.call( _id, payload ) != false)


		var ret = _content[ _content_position ] if can_get_text else null
		_content_position += 1

		return ret

	# define condition to unlock the chunk
	# to define a condition call a condition method on a [code]StoryValue[/code] or a [code]StoryLock[/code]
	func unlock_if( tests: Array, inverse: bool = false ) -> StoryChunk:
		var _test
		var _as_and_test = true

		_tests.clear()
		_test_inversed = inverse

		if len(tests) > 0:
			for test in tests:
				_test = []
				_as_and_test = (_as_and_test && (test is StoryData))

				if _as_and_test: continue

				if test is Array:
					for t in test:
						if t is StoryData: _test.append(t)

				if len(_test) > 0: _tests.append(_test)

			if _as_and_test: _tests.append(tests)

		return self

	# define the chunk as the end of a storyline
	# the story ends once this chunk has finished
	func end() -> StoryChunk:
		_end_story = true
		return self

	# define the updates to apply at the beginning of the chunk
	# to define an update call an operation method on a [code]StoryValue[/code] or a [code]StoryLock[/code]
	func update_data( updates: Array ) -> StoryChunk:
		for u in updates:
			if (u[StoryChunkUpdateKeys.at] is int) and (u[StoryChunkUpdateKeys.data] is StoryData):
				_next_updates.append(u)
		return self

	# register the next chunks to read at the end of the chunk
	# if at least one choice is registered with [code]register_choice()[/code], the method has no effect
	func register_next_chunks( next_chunk_ids: Array ) -> StoryChunk:
		if (len(_choices) == 0):
			for id in next_chunk_ids:
				if id is String:
					_next.append( id.to_lower() )
		return self

	# register a choice leading to another story chunk
	# if a choice is registered, the next chunks defined with [code]register_next_chunks()[/code] are removed
	func register_choice(name: String, description: String, story_chunk_ids: Array):
		if _expected_input == null:
			var choice = {
				StoryChunkChoiceKeys.name: name.to_lower(),
				StoryChunkChoiceKeys.description: description,
				StoryChunkChoiceKeys.story_chunk_ids: []
			}

			for id in story_chunk_ids:
				if id is String:
					choice[StoryChunkChoiceKeys.story_chunk_ids].append(id.to_lower())

			if len(choice[StoryChunkChoiceKeys.story_chunk_ids]) > 0:
				_choices[ choice[StoryChunkChoiceKeys.name] ] = choice
				_next.clear()

		return self

	# specifies that the chunk expects an input
	# [code]_min[/code] and [code]_max[/code] are:
	# - if [code]type[/code] is string, the minimum and maximum sizes
	# - if [code]type[/code] is float, the minimum and maximum values
	func expect_input(input_name: String, type: int, _min: float, _max: float):
		if (len(_choices) == 0) and not input_name.empty():
			_expected_input = {
				StoryChunkInputKeys.name: input_name.to_lower(),
				StoryChunkInputKeys.type: type,
				StoryChunkInputKeys.min: _min,
				StoryChunkInputKeys.max: _max
			}
		return self

	# set a delay between the call and the beginning of the chunk
	func delay( secs: float ) -> StoryChunk:
		_delay = secs
		return self

	# enable a namespace to give access to its commands
	func in_namespace( namespace: String ) -> StoryChunk:
		_namespace_changes.append({
			StoryCommandNsKeys.name: namespace.to_lower(),
			StoryCommandNsKeys.active: true })
		return self

	# enable namespaces to give access to their commands
	func in_namespaces( namespaces: Array ) -> StoryChunk:
		for ns in namespaces:
			if ns is String:
				in_namespace(ns)
		return self

	# disable a namespace to restrict access to its commands
	func out_namespace( namespace: String ) -> StoryChunk:
		_namespace_changes.append({
			StoryCommandNsKeys.name: namespace.to_lower(),
			StoryCommandNsKeys.active: false })
		return self

	# disable namespaces to restrict access to their commands
	func out_namespaces( namespaces: Array ) -> StoryChunk:
		for ns in namespaces:
			if ns is String:
				out_namespace(ns)
		return self


const StoryCommandDataKeys = {
	name = 'name',
	options = 'options'
}
# A command that start one or two [code]StoryChunk[/code]
class StoryCommand:
	var _ns
	var _name
	var _options = {} #no exec if empty
	var _main_chunk_id = ''
	var _always_return = false

	var _callable = false
	var _listener: StoryListener


	# parse a line of command
	# return a dictionnary:
	#	- the [code]name[/code] of the command
	#	- a dictionnary (name-value) of [code]options[/code]
	static func parse( command: String ):
		var ret = {StoryCommandDataKeys.options: {}}
		if command.empty(): return ret

		var cmd_parts = command.to_lower().split(' ', false)
		if len(cmd_parts) < 1: return ret

		ret[StoryCommandDataKeys.name] = cmd_parts[0]
		cmd_parts.remove(0)

		var opt_data
		for opt in cmd_parts:
			opt_data = opt.split('=', false)
			match len(opt_data):
				1: ret[StoryCommandDataKeys.options][opt_data[0]] = null
				2: ret[StoryCommandDataKeys.options][opt_data[0]] = opt_data[1]

		return ret


	func _init(name: String, chunk_id: String='', always_return: bool=false) -> void:
		if name.empty(): return

		_name = name.to_lower().split(' ', false, 1)
		if len(_name) > 0: _name = _name[0]
		if _name != name:
			printerr("/!\\ The command name must be one word ('%s' given, '%s' taken)" % [name, _name])

		if not chunk_id.empty():
			_main_chunk_id = chunk_id.to_lower()
			_callable = true

		_always_return = always_return

	func _exec(payload: Dictionary) -> Array:
		if not _callable: return []

		var chunk_ids = []

		if _always_return or len(payload) == 0:
			if not _main_chunk_id.empty():
				chunk_ids.append(_main_chunk_id)

		var pl_keys = payload.keys()
		pl_keys.invert()

		var set_value
		for key in pl_keys:
			var val = payload[key]

			if _options.has( key ):
				set_value = false

				var type = _options[key].type
				if (type == OPTTYPE_REQUIREVALUE) and val != null:
					type = OPTTYPE_NOVALUE
					set_value = true
				elif (type == OPTTYPE_ACCEPTVALUE):
					val = val if (val != null) else _options[key].default
					type = OPTTYPE_NOVALUE
					set_value = true

				if type == OPTTYPE_NOVALUE:
					chunk_ids.append( _options[key].chunk_id )

				if set_value: _listener.set_value( StoryValue.new(StoryListener.option_to_value(_ns._name, _name, key), float(val)))

		chunk_ids.invert()
		return chunk_ids


	# add an option to the command.
	# if the command is correctly called with this option, the corresponding [code]StoryChunk[/code] is started
	func add_option(name: String, chunk_id: String, type: int=OPTTYPE_NOVALUE, default=null) -> StoryCommand:
		_options[name.to_lower()] = { chunk_id = chunk_id.to_lower(), type = type, default = default }
		_callable = true

		return self


const StoryCommandNsKeys = {
	name = 'name',
	active = 'active'
}
# A namespace for commands
# it works like a box of commands to active or deactivate
class StoryCommandNamespace:
	var _name
	var _active
	var _commands = {}
	var _listener: StoryListener

	func _init(name: String, active: bool = false):
		_name = name.to_lower()
		_active = active

	# set the state of the namespace (enabled or disabled)
	func set_state( active: bool ):
		_active = active

	# add a [code]StoryCommand[/code] to the namespace
	func add_command( command: StoryCommand ) -> StoryCommandNamespace:
		command._ns = self
		command._listener = _listener
		_commands[command._name] = command
		return self

	# return a [code]StoryCommand[/code] (or [code]null[/code], if the namespace is disabled)
	func get_command( StoryCommand_name: String ) -> StoryCommand:
		if _active == false: return null
		return _commands.get(StoryCommand_name.to_lower())


const StoryTellerDelayedKeys = {
	moment = 'moment',
	chunk_id = 'chunk_id'
}
# The collection and reader of story chunks
class StoryTeller:
	var _can_tell = true
	var _avail_choices = []
	var _expected_input = null;

	var _chunks = {}

	var _elapsed_time: float = 0
	var _listener: StoryListener


	var _execution_thread = []
	var _next_ids = []
	var _delayed_ids = []


	func _init(listener: StoryListener):
		_listener = listener


	func _register_chunks( chunk_ids ):
		if len(chunk_ids) > 0:
			var delay
			var direct_ids = []

			for c in chunk_ids:
				if _chunks.has( c ):
					if _chunks[ c ]._delay > 0:
						_delayed_ids.append({
							StoryTellerDelayedKeys.moment: _elapsed_time + _chunks[ c ]._delay,
							StoryTellerDelayedKeys.chunk_id: c })
					else: direct_ids.append( c )

			_next_ids = direct_ids + _next_ids

	func _ignore_current_chunk():
		_execution_thread.remove(0)

	func _clear_queues():
		_execution_thread = []
		_next_ids = []
		_delayed_ids = []


	# load an array of [code]StoryChunk[/code] to be processed by the teller
	func load_story_chunks( chunks: Array ) -> StoryTeller:
		var id
		var found = {}

		for chunk in chunks:
			if chunk is StoryChunk:
				id = chunk._id
				if _chunks.has( id ):
					if found.has( id ): found[ id ] += 1
					else: found[ id ] = 2
					continue

				chunk._teller = self
				_chunks[ chunk._id ] = chunk

		if found.size() > 0:
			printerr( '[ duplicated Keysx found: {0} ]'.format( [str(found)] ) )

		return self

	# set the [code]StoryChunks[/code] to start from
	func set_start_point( chunk_id: String ) -> void:
		_can_tell = true
		_register_chunks( [chunk_id.to_lower()] )

	# stop the teller from processing [code]StoryChunks[/code]
	func stop() -> void:
		_can_tell = false
		_clear_queues()

	# check if the teller can still tell
	func can_tell() -> bool: return _can_tell

	# check if the teller if idle
	func is_idle() -> bool:
		return not _can_tell \
		or (_execution_thread.empty() \
		and _next_ids.empty() \
		and _delayed_ids.empty())

	# give a teller a choice or a command to execute
	# if a choice is expected, it has a priority on commands
	func execute( input: String ) -> int:
		if not _can_tell: return EXECCODE_NONE

		# execute a choice
		if len(_avail_choices) > 0:
			var chunk_ids
			for choice in _avail_choices[0]:
				if choice[StoryChunkChoiceKeys.name] == input.to_lower():
					chunk_ids = choice[StoryChunkChoiceKeys.story_chunk_ids]
					break

			if chunk_ids != null:
				_avail_choices.remove(0)
				_execution_thread = chunk_ids + _execution_thread
				return EXECCODE_CHOICE

		# execute the command
		var cmd_data = StoryCommand.parse( input )

		var cmd = _listener.find_command( cmd_data[StoryCommandDataKeys.name] )
		if cmd:
			var chunk_ids = cmd._exec( cmd_data[StoryCommandDataKeys.options] )
			_execution_thread = chunk_ids + _execution_thread

			if len(chunk_ids) > 0: return EXECCODE_COMMAND

		# capture input
		if _expected_input != null:
			var input_set = false
			match(_expected_input[StoryChunkInputKeys.type]):
				INPUTTYPE_STRING:
					if len(input) >= _expected_input[StoryChunkInputKeys.min]:
						if len(input) > _expected_input[StoryChunkInputKeys.max]:
							input = input.substr(0, _expected_input[StoryChunkInputKeys.max])
						_listener.set_input(StoryData.new(_expected_input[StoryChunkInputKeys.name], input))
						input_set = true
				INPUTTYPE_FLOAT:
					var value = float(input)
					if (value >= _expected_input[StoryChunkInputKeys.min]) \
					and (value <= _expected_input[StoryChunkInputKeys.max]):
						_listener.set_value(StoryValue.new(_expected_input[StoryChunkInputKeys.name], value))
						input_set = true

			if input_set:
				_expected_input = null
				return EXECCODE_INPUT

		return EXECCODE_NONE

	# retrieve a text from the teller. [code]delta[/code] is useful for delayed chunks
	# if the teller is stopper or a choice is expected, [code]null[/code] is returned
	# ---
	# values are inserted in text through formats ([code]{varname}[/code]). [code]user_data[/code] are external values
	# [i]- To force internal values: [code]{v:varname}[/code][/i]
	# [i]- To force user values ([code]user_data[/code]): [code]{u:varname}[/code][/i]
	func tell( delta: float, user_data: Dictionary = {}):
		_elapsed_time += delta

		var i = 0
		while i < _delayed_ids.size():
			if _delayed_ids[i][ StoryTellerDelayedKeys.moment ] <= _elapsed_time:
				_execution_thread.push_front(_delayed_ids[i][StoryTellerDelayedKeys.chunk_id])
				_delayed_ids.remove( i )
				break
			i += 1

		if (_expected_input == null) and (len(_avail_choices) == 0) and _can_tell:
			if (_execution_thread.size() == 0) and (_next_ids.size() > 0):
				_execution_thread.append(_next_ids[0])
				_next_ids.remove(0)

		if _execution_thread.size() > 0:
			var text= _chunks[ _execution_thread[0] ]._get_text()
			if text == null: return null

			print("Test OnlY: " + text)
			var regex = RegEx.new()

			# handle patterns as internal values
			regex.compile('\\{(?:value:)?([\\w_.-]+)\\}')
			text = regex.sub(text, '{$1}', true).format(_listener._values)

			# handle patterns as internal locks
			regex.compile('\\{([\\w_.-]+) *\\? *([\\w_.-]+) *: *([\\w_.-]+)\\}')
			var found = regex.search_all(text)
			for f in found:
				text = regex.sub(text,
					(f.get_string(2) if _listener._locks[f.get_string(1)] else f.get_string(3)), true)

			# handle options pattern
			regex.compile('\\{([\\w_.-]+)\\' + OPTNAMESEP_NS + '([\\w_.-]+)\\' + OPTNAMESEP_CMD + '([\\w_.-]+)\\}')
			text = regex.sub(text, '{' + StoryListener.option_to_value('$1', '$2', '$3') + '}', true).format(_listener._values)

			# handle input pattern
			regex.compile('\\{(?:input:)?([\\w_.-]+)\\}')
			text = regex.sub(text, '{$1}', true).format(_listener._inputs).format(_listener._values)

			# handle user_data pattern
			regex.compile('\\{([\\w_.-]+)\\}')
			text = regex.sub(text, '{$1}', true).format(user_data)

			return text

	# return a boolean specifying if a choice is waited
	func must_choose() -> bool: return (len(_avail_choices) > 0)

	# return a Dictionary of available commands grouped by namespace
	func get_available_choices(): return _avail_choices

	# return a Dictionary of available commands grouped by namespace
	func get_available_commands():
		return _listener.get_available_commands()


# The collection of locks, values
# it also handles namespaces, commands and their options
# ---
# it can be useful to extend that class
# a method having a [code]StoryChunk[/code] id as name is called before each line of the chunk
# that method receives a dictionnary as unique parameter with keys in [code]StoryChunkPayloadKeys[/code]
class StoryListener:
	var _locks = {}
	var _values = {}
	var _inputs = {}

	var _commands = {}

	func _init(locks: Dictionary={}, values: Dictionary={}):
		load_locks(locks)
		load_values(values)


	# turns option coordinates into a value name
	static func option_to_value(nsname: String, cmd: String, option: String) -> String:
		var name = nsname + OPTNAMESEP_NS + cmd
		if not option.empty(): name += OPTNAMESEP_CMD + option
		return name


	# loads an array of namespaces containing commands
	func load_commands( commands: Array ) -> StoryListener:
		for ns in commands:
			if ns is StoryCommandNamespace:
				ns._listener = self
				_commands[ns._name] = ns

		return self

	# finds a command using his name
	func find_command(StoryCommand_name: String) -> StoryCommand:
		var cmd = null
		for ns in _commands.values():
			cmd = ns.get_command( StoryCommand_name )
			if cmd: break

		return cmd

	# sets the state of a command namespace
	func set_command_namespace_state(namespace: String, active: bool):
		var ns = _commands.get( namespace.to_lower() )
		if ns: ns.set_state( active )

	# return a Dictionary of available commands grouped by namespace
	func get_available_commands():
		var ret = {}
		for ns_name in _commands:
			if not _commands[ns_name]._active: continue
			ret[ns_name] = {}
			for cmd_name in _commands[ns_name]._commands:
				ret[ns_name][cmd_name] = {
					main_chunk_id = _commands[ns_name]._commands[cmd_name]._main_chunk_id
				}
				for option_name in _commands[ns_name]._commands[cmd_name]._options:
					ret[ns_name][cmd_name][option_name] = _commands[ns_name]._commands[cmd_name]._options[option_name]

		return ret


	# loads locks with a dictionary name to value
	func load_locks(locks: Dictionary):
		for k in locks: _locks[k.to_lower()] = bool(locks[k])

	# returns a lock
	func get_lock(name: String) -> StoryLock:
		return StoryLock.new( name, _locks.get(name.to_lower(), false) )

	# returns the dictionary of all locks
	func get_locks() -> Dictionary: return _locks

	# sets a lock
	# if it exists, its data is updated
	func set_lock(lock: StoryLock):
		_locks[ lock._name ] = lock._value

	# deletes all locks
	func clear_locks(): _locks.clear()


	# loads values with a dictionary name to value
	func load_values(values: Dictionary):
		for k in values: _values[k.to_lower()] = float(values[k])

	# returns a value
	func get_value(name: String) -> StoryValue:
		return StoryValue.new(name, _values.get(name.to_lower(), 0))

	# returns the dictionary of all values
	func get_values() -> Dictionary: return _values

	# sets a value
	# if it exists, its data is updated
	func set_value(value: StoryValue):
		_values[ value._name ] = value._value

	# deletes all values
	func clear_values(): _values.clear()


	# loads inputs with a dictionary name to value
	func load_inputs(inputs: Dictionary):
		for k in inputs: _inputs[k.to_lower()] = inputs[k]

	# returns a input
	func get_input(name: String) -> StoryData:
		return StoryData.new( name, _inputs.get(name.to_lower()) )

	# returns the dictionary of all inputs
	func get_inputs() -> Dictionary: return _inputs

	# sets a input
	# if it exists, its data is updated
	func set_input(input: StoryData):
		_inputs[ input._name ] = input._value

	# deletes all inputs
	func clear_inputs(): _inputs.clear()


# The story file interpreter
class StoryInterpreter:
	const FileExt = '.story'

	const NODENAME_START = 'StartNode'
	const NODENAME_END = 'EndNode'

	var _base_path: String = ''
	var _db: Dictionary = {}

	static func get_default_value(type: int):
		if type in [st.TYPE_VALUE, st.TYPE_OPTION]: return 0
		elif type in [st.TYPE_LOCK, st.TYPE_NAMESPACE]: return false
		elif type == st.TYPE_INPUT: return st.INPUTTYPE_STRING

	static func data_to_template(data: Dictionary):
		var id = str(data.id)
		match(data.type):
			TYPE_LOCK: return "{L=" + id + "?on:off}"
			TYPE_VALUE: return "{V=" + id + "}"
			TYPE_OPTION: return "{O=" + id + "}"
			TYPE_INPUT: return "{I=" + id + "}"



	func _get_data(type: int, id: int):
		var target
		var tmp = {id=-1, name='', ini_val=get_default_value(type)}
		match(type):
			TYPE_NAMESPACE: target = _db.get('namespaces', [])
			TYPE_LOCK: target = _db.get('locks', [])
			TYPE_VALUE: target = _db.get('values', [])
			TYPE_OPTION: target = _db.get('options', [])
			TYPE_INPUT: target = _db.get('inputs', [])

		for i in range(len(target)):
			if target[i].id == id:
				tmp = target[i].duplicate()
				break

		tmp.type = type
		return tmp

	func _simplify_content(content: String):
		var regex = RegEx.new()
		var matches = null

		# handle patterns as internal locks
		regex.compile('\\{L=(\\d+) *\\? *([\\w_.-]+) *: *([\\w_.-]+)\\}')
		matches = regex.search_all(content)
		for m in matches:
			if m.get_group_count() > 0:
				content = content.replace(m.get_string(0),
					'{' + _get_data(TYPE_LOCK, int(m.get_string(1))).name + '?' + m.get_string(2) + ':' + m.get_string(3) + '}')

		# handle patterns as values
		regex.compile('\\{V=(\\d+)\\}')
		matches = regex.search_all(content)
		for m in matches:
			if m.get_group_count() > 0:
				content = content.replace(m.get_string(0),
					'{value:' + _get_data(TYPE_VALUE, int(m.get_string(1))).name + '}')

		# handle patterns as options
		regex.compile('\\{O=(\\d+)\\}')
		for m in matches:
			if m.get_group_count() > 0:
				content = content.replace(m.get_string(0),
					'{' + _get_data(TYPE_OPTION, int(m.get_string(1))).name + '}')

		# handle patterns as inputs
		regex.compile('\\{I=(\\d+)\\}')
		matches = regex.search_all(content)
		for m in matches:
			if m.get_group_count() > 0:
				content = content.replace(m.get_string(0),
					'{input:' + _get_data(TYPE_INPUT, int(m.get_string(1))).name + '}')

		return content



	func _init(path: String=''):
		set_base_path(path)

	func _build_command(cmd_data, data) -> StoryCommand:
		var tmp = _get_related_chunks(cmd_data.node_name, data.links, data.story_chunks)
		if len(tmp) == 0: return null

		var cmd = StoryCommand.new(cmd_data.data.name, tmp.get(0, [''])[0], cmd_data.data.default_always)

		var i = 0
		var chk_id
		for opt in cmd_data.data.options:
			i += 1
			chk_id = tmp.get(i, [''])[0]
			if chk_id == '': continue
			cmd.add_option(opt.name, chk_id, opt.type,
				(opt.default if opt.type == OPTTYPE_ACCEPTVALUE else null))

		return cmd

	func _build_story_chunk(chk_data, data) -> StoryChunk:
		chk_data.data = StoryChunk.normalize_data(chk_data.data)

		var tmp = _get_related_chunks(chk_data.node_name, data.links, data.story_chunks)

		var chunks = [ StoryChunk.new(chk_data.data.id,
			('' if chk_data.data.condition_only else _simplify_content(chk_data.data.content)) ) ]

		var conditions = []
		var condition

		for cond in chk_data.data.conditions:
			condition = []
			for c in cond:
				var target = {}
				target = _get_data(c.target.type, c.target.id)
				if target.id == -1: continue

				if c.value.type == st.VALUETYPE_TARGET:
					c.value.content = _get_data(c.value.content.type, c.value.content.id).name

				if target.type == TYPE_LOCK:
					condition.append(StoryLock.new(target.name, c.value.content, c.operator))
				elif target.type in [TYPE_VALUE, TYPE_OPTION, TYPE_INPUT]:
					condition.append(StoryValue.new(target.name, c.value.content, c.operator))

			conditions.append(condition)

		var yes_part = chunks[0]
		if not chk_data.data.condition_only:
			chunks[0].delay(chk_data.data.delay)

			if len(chk_data.data.choices) > 0:
				var i = 0
				var chk_ids
				for c in chk_data.data.choices:
					chk_ids = tmp.get(i, [])
					if (not chk_ids is Array) or (len(chk_ids) == 0): continue
					chunks[0].register_choice(c.name, c.description, chk_ids)
					i += 1

			for u in chk_data.data.updates:
				var target = _get_data(u.target.type, u.target.id)
				if target.id == -1: continue

				if u.value.type == st.VALUETYPE_TARGET:
					u.value.content = _get_data(u.value.content.type, u.value.content.id).name

				if target.type == TYPE_NAMESPACE:
					if u.value: chunks[0].in_namespace(target.name)
					else: chunks[0].out_namespace(target.name)
				elif target.type == TYPE_LOCK:
					chunks[0].update_data([{
						StoryChunkUpdateKeys.at: u.get('at', UPDATE_ATEND),
						StoryChunkUpdateKeys.data: StoryLock.new(target.name, u.value.content, u.operator)
					}])
				elif target.type in [TYPE_VALUE, TYPE_OPTION, TYPE_INPUT]:
					chunks[0].update_data([{
						StoryChunkUpdateKeys.at: u.get('at', UPDATE_ATEND),
						StoryChunkUpdateKeys.data: StoryValue.new(target.name, u.value.content, u.operator)
					}])

			if not chk_data.data.input_name.empty():
				chunks[0].expect_input(chk_data.data.input_name, chk_data.data.input_type, chk_data.data.input_min, chk_data.data.input_max)
		else:
			yes_part = StoryChunk.new(chk_data.data.id + '_yes')
			var no_part = StoryChunk.new(chk_data.data.id + '_no')

			no_part.unlock_if(conditions, not chk_data.data.inverse_condition)
			no_part.register_next_chunks( tmp.get(1, []) )

			chunks[0].register_next_chunks([yes_part._id, no_part._id])
			chunks.append(yes_part)
			chunks.append(no_part)

		yes_part.unlock_if(conditions, chk_data.data.inverse_condition)
		if len(chk_data.data.choices) == 0:
			yes_part.register_next_chunks( tmp.get(0, []) )

		return chunks


	func _add_in_grouped_list(list: Dictionary, where, what):
		if list.has(where):
			list[where].append(what)
		else: list[where] = [what]

	func _get_related_chunks(from: String, links: Array, chunks: Array):
		var rel = {}
		for l in links:
			if l.from != from:
				continue

			if l.to == NODENAME_END:
				_add_in_grouped_list(rel, l.from_port, CHUNKID_END)
				continue

			for c in chunks:
				if c.node_name == l.to:
					_add_in_grouped_list(rel, l.from_port, c.data.id)
					break

		return rel


	# set the base path to load stories
	func set_base_path(path: String='') -> StoryInterpreter:
		if not path.empty() and path.is_abs_path():
			_base_path = path
		return self

	# unset the base path to load stories
	func unset_base_path(): set_base_path()

	# load a story from a path
	# can be given a custom [code]StoryListener[/code]
	# *it is possible to omit the extension*
	# returns the corresponding [code]StoryTeller[/code]
	func load_story(path: String='', listener: StoryListener = null) -> StoryTeller:
		var file = File.new()
		if listener == null:
			listener = StoryListener.new()

		if not _base_path.empty():
			path = _base_path+'/'+path

		if not path.ends_with(FileExt):
			path += FileExt

		if not path.is_abs_path() \
		or file.open(path, File.READ) != OK:
			return StoryTeller.new( listener )

		var data = file.get_var()
		file.close()
		if data == null: return StoryTeller.new( listener )

		var s_ini = {}
		for s in data.locks:
			s_ini[s.name] = s.ini_val

		var v_ini = {}
		for v in data.values:
			v_ini[v.name] = v.ini_val

		listener.load_locks(s_ini)
		listener.load_values(v_ini)

		var n_ini = {}
		for n in data.namespaces:
			n_ini[n.id] = StoryCommandNamespace.new(n.name, n.ini_val)
			n_ini[n.id]._listener = listener

		var ns
		var cmd
		for c in data.commands:
			ns = n_ini.get(c.data.namespace_id)
			if ns == null: continue

			cmd = _build_command(c, data)
			if cmd != null: ns.add_command(cmd)

		listener.load_commands(n_ini.values())

		var teller = StoryTeller.new(listener)

		_db.namespaces = data.get('namespaces', [])
		_db.values = data.get('values', [])
		_db.locks = data.get('locks', [])
		_db.options = data.get('options', [])
		_db.inputs = data.get('inputs', [])

		var start_next = _get_related_chunks(NODENAME_START, data.links, data.story_chunks)
		start_next = start_next[0] if (len(start_next) > 0) else []

		var chunks = [
			StoryChunk.new(CHUNKID_START).register_next_chunks( start_next ),
			StoryChunk.new(CHUNKID_END).end()
		]
		for sc in data.story_chunks:
			for c in _build_story_chunk(sc, data):
				chunks.append( c )
		teller.load_story_chunks( chunks )
		teller.set_start_point(CHUNKID_START)

		return teller



var _default_interpreter
# returns a default interpreter
func get_default_interpreter() -> StoryInterpreter:
	if _default_interpreter == null:
		_default_interpreter = StoryInterpreter.new()
	return _default_interpreter
