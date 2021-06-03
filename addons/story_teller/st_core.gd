extends Node


# base class of StoryLock, StoryValue
class StoryData:
	const OPERATOR_NONE = 0

	var _name
	var _value
	var _operator

	func _init(name: String, value, operator: int=OPERATOR_NONE):
		_name = name
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
	const OPERATOR_TOG=2

	const OPERATOR_TST=-1

	func _init(name: String, value: bool, operator: int=OPERATOR_NONE).(name, value, operator): pass

	func _apply( listener: StoryListener ):
		var lock = listener.get_lock(_name)

		if _operator == OPERATOR_SET: lock._value = _value
		elif _operator == OPERATOR_TOG: lock._value = not lock._value
		listener.set_lock( lock )

	func _check( listener: StoryListener ) -> bool:
		if _operator != OPERATOR_TST: return false
		return (listener.get_lock(_name)._value == _value)

	func on() -> StoryLock:
		if _operator != OPERATOR_NONE: return self
		return StoryLock.new(_name, true, OPERATOR_SET)
	func off() -> StoryLock:
		if _operator != OPERATOR_NONE: return self
		return StoryLock.new(_name, false, OPERATOR_SET)
	func toggle() -> StoryLock:
		if _operator != OPERATOR_NONE: return self
		return StoryLock.new(_name, true, OPERATOR_TOG)

	func is_on() -> StoryLock:
		if _operator != OPERATOR_NONE: return self
		return StoryLock.new(_name, true, OPERATOR_TST)
	func is_off() -> StoryLock:
		if _operator != OPERATOR_NONE: return self
		return StoryLock.new(_name, false, OPERATOR_TST)

# A values to keep track of story data
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

	func _init(name: String, value: float, operator: int=OPERATOR_NONE).(name, value, operator): pass

	func _apply( listener: StoryListener ):
		if _value == null: return

		var value = listener.get_val(_name)
		if value._value == null: return

		match( _operator ):
			OPERATOR_ADD: value._value += _value
			OPERATOR_MULT: value._value *= _value
			OPERATOR_SET: value._value = _value

		listener.set_val( value )

	func _check( listener: StoryListener ) -> bool:
		if _value == null: return false

		var value = listener.get_val(_name)._value
		if value == null: return false

		match( _operator ):
			OPERATOR_EQ: return (value == _value)
			OPERATOR_NEQ: return (value != _value)
			OPERATOR_LT: return (value < _value)
			OPERATOR_LTE: return (value <= _value)
			OPERATOR_GT: return (value > _value)
			OPERATOR_GTE: return (value >= _value)

		return false

	func eq(value: float) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_EQ)
	func neq(value: float) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_NEQ)
	func lt(value: float) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_LT)
	func lte(value: float) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_LTE)
	func gt(value: float) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_GT)
	func gte(value: float) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_GTE)

	func add(value: float) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_ADD)
	func mult(value: float) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_MULT)
	func set_to(value: float) -> StoryValue:
		if _operator != OPERATOR_NONE: return self
		return StoryValue.new(_name, value, OPERATOR_SET)


const StoryChunkPayloadKeys = {
	current_position = "cur_pos",
	is_last_position = "is_last_pos"
}
const StoryChunkChoiceKeys = {
	name = "name",
	description = "description",
	story_chunk_ids = "story_chunk_ids"
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
	var _choices = []
	var _end_story = false

	func _init(id: String, content: PoolStringArray = [""]):
		_id = id
		_content = Array(content)
		_content_size = _content.size()

	func _is_locked():
		var lock = (true && !_test_inversed)

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
			_teller._ignore_current_chunk( true )
			return

		if (_content_position == _content_size):
			_content_position = 0
			_teller._ignore_current_chunk()
			return

		if _content_position == 0:
			for update in _next_updates:
				update._apply( _teller._listener )

		if _content_position == (_content_size-1):
			if _end_story: _teller.stop()
			else:
				_teller._register_chunks( _next )
				_teller._must_choose = (len(_choices) > 0)

		var can_play = true
		if _teller._listener.has_method(_id):
			var payload = {
				StoryChunkPayloadKeys.current_position: _content_position,
				StoryChunkPayloadKeys.is_last_position: (_content_position >= (_content_size-1))
			}
			can_play = (_teller._listener.call( _id, payload ) != false)

		var ret = _content[ _content_position ] if can_play else null
		_content_position += 1

		return ret

	func _get_choice_chunks(name: String):
		for choice in _choices:
			if choice[StoryChunkChoiceKeys.name] == name:
				return choice[StoryChunkChoiceKeys.story_chunk_ids]
		return null

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
	func update_data( data: Array ) -> StoryChunk:
		for d in data:
			if d is StoryData:
				_next_updates.append( d )
		return self

	# register the next chunks to read at the end of the chunk
	# if at least one choice is registered with [code]register_choice()[/code], the method has no effect
	func register_next_chunks( next_chunk_ids: Array ) -> StoryChunk:
		if len(_choices) == 0:
			for id in next_chunk_ids:
				if id is String:
					_next.append( id )
		return self

	# register a choice leading to another story chunk
	# if a choice is registered, the next chunks defined with [code]register_next_chunks()[/code] are removed
	func register_choice(name: String, description: String, story_chunk_ids: Array):
		var choice = {
			StoryChunkChoiceKeys.name: name,
			StoryChunkChoiceKeys.description: description,
			StoryChunkChoiceKeys.story_chunk_ids: []
		}

		for id in story_chunk_ids:
			if id is String:
				choice[StoryChunkChoiceKeys.story_chunk_ids].append(id)

		if len(choice[StoryChunkChoiceKeys.story_chunk_ids]) > 0:
			_next.clear()
			_choices.append(choice)

		return self

	# set a delay between the call and the beginning of the chunk
	func delay( secs: float ) -> StoryChunk:
		_delay = secs
		return self

	# enable a namespace to give access to its commands
	func in_namespace( namespace: String ) -> StoryChunk:
		_namespace_changes.append({
			StoryCommandNsKeys.name: namespace,
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
			StoryCommandNsKeys.name: namespace,
			StoryCommandNsKeys.active: false })
		return self

	# disable namespaces to restrict access to their commands
	func out_namespaces( namespaces: Array ) -> StoryChunk:
		for ns in namespaces:
			if ns is String:
				out_namespace(ns)
		return self


const StoryCommandDataKeys = {
	name = "name",
	options = "options"
}
# A command that start one or two [code]StoryChunk[/code]
class StoryCommand:
	const OPTTYPE_NOVALUE = 0
	const OPTTYPE_ACCEPTVALUE = 1
	const OPTTYPE_REQUIREVALUE = 2

	var _name
	var _options = {} #no exec if empty
	var _main_chunk_id = ""
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

		var cmd_parts = command.split(' ', false)
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


	func _init(name: String, chunk_id: String="", always_return: bool=false) -> void:
		if name.empty(): return

		_name = name.split(' ', false, 1)
		if len(_name) > 0: _name = _name[0]
		if _name != name:
			printerr("/!\\ The command name must be one word ('%s' given, '%s' taken)" % [name, _name])

		if not chunk_id.empty():
			_main_chunk_id = chunk_id
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

				if set_value: _listener.set_option(_name, key, float(val))

		chunk_ids.invert()
		return chunk_ids


	# add an option to the command.
	# if the command is correctly called with this option, the corresponding [code]StoryChunk[/code] is started
	func add_option(name: String, chunk_id: String, type: int=OPTTYPE_NOVALUE, default=null) -> StoryCommand:
		_options[name] = { chunk_id = chunk_id, type = type, default = default }
		_callable = true

		return self


const StoryCommandNsKeys = {
	name = "name",
	active = "active"
}
# A namespace for commands
# it works like a box of commands to active or deactivate
class StoryCommandNamespace:
	var _name
	var _active
	var _commands = {}
	var _listener: StoryListener

	func _init(name: String, active: bool = false):
		_name = name
		_active = active

	# set the state of the namespace (enabled or disabled)
	func set_state( active: bool ):
		_active = active

	# add a [code]StoryCommand[/code] to the namespace
	func add_command( command: StoryCommand ) -> StoryCommandNamespace:
		command._listener = _listener
		_commands[command._name] = command
		return self

	# return a [code]StoryCommand[/code] (or [code]null[/code], if the namespace is disabled)
	func get_command( StoryCommand_name: String ) -> StoryCommand:
		if _active == false: return null
		return _commands.get(StoryCommand_name)


const StoryTellerDelayedKeys = {
	moment = "moment",
	chunk_id = "chunk_id"
}
# The collection and reader of story chunks
class StoryTeller:
	var _can_tell = true
	var _must_choose = false

	var _chunks = {}

	var _current: StoryChunk
	var _elapsed_time: float = 0
	var _listener: StoryListener

	var _next_ids = []
	var _delayed_ids = []
	var _stacked_ids = []

	var _current_chunk_id
	var _last_chunk_id


	func _init(listener: StoryListener):
		_listener = listener

	func _register_chunks( chunk_ids ):
		var delay
		var direct_ids = []

		for c in chunk_ids:
			if _chunks.has( c ):
				delay = _chunks[ c ]._delay
				if delay == 0: direct_ids.append( c )
				else: _delayed_ids.append({
						StoryTellerDelayedKeys.moment: _elapsed_time + delay,
						StoryTellerDelayedKeys.chunk_id: c })

		_next_ids = direct_ids + _next_ids

	func _ignore_current_chunk( undo_chunk = false ):
		if undo_chunk and _last_chunk_id:
			_current_chunk_id = _last_chunk_id
		_current = null

	func _clear_queues():
		_next_ids = []
		_stacked_ids = []
		_delayed_ids = []


	# load an array of [code]StoryChunk[/code] to be processed by the teller
	func load_story_chunks( chunks: Array ) -> StoryTeller:
		var id
		var found = {}

		for chunk in chunks:
			if chunk is StoryChunk:
				id = chunk._id
				if _chunks.has( id ):
					if found.has( id ): found[ id ] += 3
					else: found[ id ] = 2

				chunk._teller = self
				_chunks[ chunk._id ] = chunk

		if found.size() > 0:
			printerr( "[ duplicated Keysx found: {0} ]".format( [str(found)] ) )

		return self

	# set the [code]StoryChunks[/code] to start from
	func set_start_point( chunk_id: String ) -> void:
		_can_tell = true
		_register_chunks( [chunk_id] )

	# stop the teller from processing [code]StoryChunks[/code]
	func stop() -> void:
		_can_tell = false
		_clear_queues()
		_current = null

	# check if the teller can still tell
	func can_tell() -> bool: return _can_tell

	# check if the teller if idle
	func is_idle() -> bool:
		return _can_tell \
		and _next_ids.empty() \
		and _delayed_ids.empty() \
		and _stacked_ids.empty()

	# give a teller a choice or a command to execute
	# if a choice is expected, no command is executed
	func execute( choice_or_command: String ) -> bool:
		if not _can_tell: return false

		var tmp = _current
		if _current:
			_stacked_ids.push_back( _current._id )
			_current = null

		# execute a choice
		if _must_choose:
			var chunk_ids = tmp._get_choice_chunks(choice_or_command)

			if chunk_ids != null:
				_must_choose = false
				for chunk_id in chunk_ids:
					if not _chunks[ chunk_id ]._is_locked():
						_stacked_ids.push_back( chunk_id )
				return true
			else:
				_stacked_ids.pop_back()
				_current = tmp
				return false


		# execute the command
		var cmd_data = StoryCommand.parse( choice_or_command )

		var cmd = _listener.find_command( cmd_data[StoryCommandDataKeys.name] )
		if cmd:
			var chunk_ids = cmd._exec( cmd_data[StoryCommandDataKeys.options] )
			for chunk_id in chunk_ids:
				if not _chunks[ chunk_id ]._is_locked():
					_stacked_ids.push_back( chunk_id )

			if len(chunk_ids) > 0: return true

		return false

	# retrieve a text from the teller. [code]delta[/code] is useful for delayed chunks
	# if the teller is stopper or a choice is expected, [code]null[/code] is returned
	# ---
	# values are inserted in text through formats ([code]{varname}[/code]). [code]uservars[/code] are external values
	# [i]- To force internal values: [code]{v:varname}[/code][/i]
	# [i]- To force user values ([code]uservars[/code]): [code]{u:varname}[/code][/i]
	func tell( delta: float, uservars: Dictionary = {}):
		_elapsed_time += delta
		if _must_choose or not _can_tell: return

		var i = 0
		while i < _delayed_ids.size():
			if _delayed_ids[i][ StoryTellerDelayedKeys.moment] <= _elapsed_time:
				if _current: _stacked_ids.push_back( _current._id )
				_last_chunk_id = _current_chunk_id
				_current_chunk_id = _delayed_ids[i][ StoryTellerDelayedKeys.chunk_id]
				_current = _chunks[ _current_chunk_id ]
				_delayed_ids.remove( i )
				break
			i += 1

		if _current == null:
			if _stacked_ids.size() > 0:
				_last_chunk_id = _current_chunk_id
				_current_chunk_id = _stacked_ids.pop_back()
				_current = _chunks[ _current_chunk_id ]
			elif _next_ids.size() > 0:
				_last_chunk_id = _current_chunk_id
				_current_chunk_id = _next_ids.pop_front()
				_current = _chunks[ _current_chunk_id ]

			if _current:
				for nsch in _current._namespace_changes:
					_listener.set_command_namespace_state(
						nsch[ StoryCommandNsKeys.name ],
						nsch[StoryCommandNsKeys.active] )

		if _current != null:
			var text= _current._get_text()
			if text == null: return null

			var regex = RegEx.new()

			# handle vars pattern
			regex.compile("\\{(?:v:)?([\\w_.-]+)\\}")
			text = regex.sub(text, "{$1}", true).format(_listener._vals)
			# handle uservars pattern
			regex.compile("\\{(?:u:)([\\w_.-]+)\\}")
			text = regex.sub(text, "{$1}", true).format(uservars)

			return text


# The collection of locks, values
# it also handles namespaces, commands and their options
# ---
# it can be useful to extend that class
# a method having a [code]StoryChunk[/code] id as name is called before each line of the chunk
# that method receives a dictionnary as unique parameter with keys in [code]StoryChunkPayloadKeys[/code]
class StoryListener:
	var _locks = {}
	var _vals = {}

	var _commands = {}

	func _init(locks: Dictionary={}, values: Dictionary={}):
		load_locks(locks)
		load_values(values)


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

	# loads locks with a dictionary name to value
	func load_locks(locks: Dictionary):
		for k in locks: _locks[k] = locks[k]

	# loads values with a dictionary name to value
	func load_values(values: Dictionary):
		for k in values: _vals[k] = values[k]

	# sets the state of a namespace
	func set_command_namespace_state(namespace: String, active: bool):
		var ns = _commands.get( namespace )
		if ns: ns.set_state( active )

	# returns a command's option as a [code]StoryValue[/code]
	func get_option(cmdname: String, optname: String) -> StoryValue:
		var name = cmdname+"."+optname
		return StoryValue.new(name, _vals.get(name))

	# sets the value of a command's option
	func set_option(cmdname: String, optname: String, val: float):
		_vals[ cmdname+"."+optname ] = val


	# returns a lock
	func get_lock( name: String ) -> StoryLock:
		return StoryLock.new( name, _locks.get(name, false) )

	# sets a lock
	# if it exists, its data is updated
	func set_lock( lock: StoryLock ):
		_locks[ lock._name ] = lock._value

	# deletes all locks
	func clear_locks(): _locks.clear()


	# returns a value
	func get_val( name: String ) -> StoryValue:
		return StoryValue.new(name, _vals.get(name))

	# sets a value
	# if it exists, its data is updated
	func set_val( value: StoryValue ):
		_vals[ value._name ] = value._value

	# deletes all values
	func clear_vals(): _vals.clear()


# The story file interpreter
class StoryInterpreter:
	const FileExt = ".story"

	const TYPE_NAMESPACE = 0
	const TYPE_LOCK = 1
	const TYPE_VALUE = 2

	var _base_path: String = ""
	var _db: Dictionary = {}

	func _get_data(type: int, id: int):
		var target
		var tmp = {id=-1, name="", ini_val=(0 if type == TYPE_VALUE else false)}
		match(type):
			TYPE_NAMESPACE: target = _db.get('namespaces', [])
			TYPE_LOCK: target = _db.get('locks', [])
			TYPE_VALUE: target = _db.get('values', [])

		for i in range(len(target)):
			if target[i].id == id:
				tmp = target[i].duplicate()
				break

		tmp.type = type
		return tmp

	func _init(path: String=""):
		set_base_path(path)

	func _build_command(cmd_data, data) -> StoryCommand:
		var tmp = _get_related_chunks(cmd_data.node_name, data.links, data.story_chunks)
		if len(tmp) == 0: return null

		var cmd = StoryCommand.new(cmd_data.data.name, tmp.get(0, [""])[0], cmd_data.data.default_always)

		var i = 0
		var chk_id
		for opt in cmd_data.data.options:
			i += 1
			chk_id = tmp.get(i, [""])[0]
			if chk_id == "": continue
			cmd.add_option(opt.name, chk_id, opt.type,
				(opt.default if opt.type == StoryCommand.OPTTYPE_ACCEPTVALUE else null))

		return cmd

	func _build_story_chunk(chk_data, data) -> StoryChunk:
		var tmp = _get_related_chunks(chk_data.node_name, data.links, data.story_chunks)

		var chunks = [ StoryChunk.new(chk_data.data.id,
			(chk_data.data.content.split('\n') if not chk_data.data.condition_only else [""])) ]

		var conditions = []
		var condition
		for cond in chk_data.data.conditions:
			condition = []
			for c in cond:
				var target = _get_data(c.target.type, c.target.id)

				if target.type == TYPE_LOCK:
					condition.append(StoryLock.new(target.name, c.value, -(c.operator+1)))
				elif target.type == TYPE_VALUE:
					condition.append(StoryValue.new(target.name, c.value, -(c.operator+1)))

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

				if target.type == TYPE_NAMESPACE:
					if u.value: chunks[0].in_namespace(target.name)
					else: chunks[0].out_namespace(target.name)
				elif target.type == TYPE_LOCK:
					chunks[0].update_data([ StoryLock.new(target.name, u.value, (u.operator+1)) ])
				elif target.type == TYPE_VALUE:
					chunks[0].update_data([ StoryValue.new(target.name, u.value, (u.operator+1)) ])
		else:
			yes_part = StoryChunk.new(chk_data.data.id + "_yes")
			var no_part = StoryChunk.new(chk_data.data.id + "_no")

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

			if l.to == 'EndNode':
				_add_in_grouped_list(rel, l.from_port, 'end')
				continue

			for c in chunks:
				if c.node_name == l.to:
					_add_in_grouped_list(rel, l.from_port, c.data.id)
					break

		return rel


	# set the base path to load stories
	func set_base_path(path: String="") -> StoryInterpreter:
		if not path.empty() and path.is_abs_path():
			_base_path = path
		return self

	# unset the base path to load stories
	func unset_base_path(): set_base_path()

	# load a story from a path
	# can be given a custom [code]StoryListener[/code]
	# *it is possible to omit the extension*
	# returns the corresponding [code]StoryTeller[/code]
	func load_story(path: String="", listener: StoryListener = null) -> StoryTeller:
		var file = File.new()
		if listener == null:
			listener = StoryListener.new()

		if not _base_path.empty():
			path = _base_path+"/"+path

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

		_db.namespaces = data.namespaces
		_db.values = data.values
		_db.locks = data.locks

		var chunks = [
			StoryChunk.new('start').register_next_chunks( _get_related_chunks('StartNode', data.links, data.story_chunks)[0] ),
			StoryChunk.new('end').end()
		]
		for sc in data.story_chunks:
			for c in _build_story_chunk(sc, data):
				chunks.append( c )
		teller.load_story_chunks( chunks )
		teller.set_start_point('start')

		return teller



var _default_interpreter
# returns a default interpreter
func get_default_interpreter() -> StoryInterpreter:
	if _default_interpreter == null:
		_default_interpreter = StoryInterpreter.new()
	return _default_interpreter
