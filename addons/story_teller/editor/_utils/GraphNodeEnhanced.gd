tool
extends GraphNode

class_name _GraphNodeEnhanced

# specify that a [code]from_port[/code] leads to only one [code]to_port[/code]
export (bool) var OnePerPort = false

const DELETE_SUFFIX = ' (deleted)'

# ---------------------------------------------------------------------------------------

var graphEdit: GraphEdit

# unlink the node and delete it
func remove():
	unlink()
	name += DELETE_SUFFIX
	queue_free()

# check if the node is about to be deleted
func is_removing():
	return name.ends_with(DELETE_SUFFIX)

# check if the node is linked to a [code]port[/code]
# [code]is_to_port[/code] tells if the port is a to port
func is_linked_on_port(port: int, is_to_port := false):
	if not graphEdit: return

	for conn in graphEdit.get_connection_list():
		if is_to_port:
			if (conn.to == name) and (port == conn.to_port):
				return true
		else:
			if (conn.from == name) and (port == conn.from_port):
				return true

	return false

# removes the link on from and to ports of this node
# if [code]from_port[/code] is [code]-1[/code], all from ports are unlinked
# if [code]to_port[/code] is [code]-1[/code], all to ports are unlinked
func unlink(from_port: int = -1, to_port: int = -1):
	if not graphEdit: return

	var done = false
	for conn in graphEdit.get_connection_list():
		if ((from_port == -1) and (to_port == -1) and ((conn.from == name) or (conn.to == name))) \
		or ((from_port > -1) and (conn.from == name) and (conn.from_port == from_port)) \
		or ((to_port > -1) and (conn.to == name) and (conn.to_port == to_port)):
			graphEdit.disconnect_node(conn.from, conn.from_port, conn.to, conn.to_port)
			done = true

	return done

# returns an array of connection to this node
# if [code]from[/code] is [code]true[/code], all connections where the node is [code]from[/code] are taken
# if [code]to[/code] is [code]true[/code], all connections where the node is [code]to[/code] are taken
func get_connections(from := true, to := true):
	if not graphEdit: return []

	var connection_list = []
	for conn in graphEdit.get_connection_list():
		if (from and (conn.from == name)) \
		or (to and (conn.to == name)):
			connection_list.append(conn)

	return connection_list


# updates connections where the node is [code]from[/code] from [code]old_port[/code] to [code]new_port[/code]
func update_from_port(old_port: int, new_port: int):
	if not graphEdit \
	or old_port == new_port: return

	for conn in graphEdit.get_connection_list():
		if (conn.from == name) \
		and (conn.from_port == old_port):
			graphEdit.disconnect_node(conn.from, old_port, conn.to, conn.to_port)
			graphEdit.connect_node(conn.from, new_port, conn.to, conn.to_port)

# updates connections where the node is [code]to[/code] from [code]old_port[/code] to [code]new_port[/code]
func update_to_port(old_port: int, new_port: int):
	if not graphEdit: return

	for conn in graphEdit.get_connection_list():
		if (conn.to == name) \
		and (conn.to_port == old_port):
			graphEdit.disconnect_node(conn.from, conn.from_port, conn.to, old_port)
			graphEdit.connect_node(conn.from, conn.from_port, conn.to, new_port)

# fix offset based on snap grid
func fix_offset():
	if not graphEdit: return

	if graphEdit.use_snap:
		offset = (offset/graphEdit.snap_distance).round() * graphEdit.snap_distance

# fix size of view based of the content
func fix_view():
	set_size( Vector2(rect_size.x, 0) )
	


# ---------------------------------------------------------------------------------------

var _before_close := {}
var _after_close := {}

# sets the new action for the signal [code]close_request[/code]
func call_before_close(target: Object = null, method: String = ''):
	if (target != null) and not method.empty():
		_before_close = {target = target, method = method}
	
func call_after_close(target: Object = null, method: String = ''):
	if (target != null) and not method.empty():
		_after_close = {target = target, method = method}


func _on_close_request():
	if not _before_close.empty():
		_before_close.target.call(_before_close.method)
	remove()
	if not _after_close.empty():
		_after_close.target.call(_after_close.method)

func _ready():
	connect('close_request', self, '_on_close_request')
