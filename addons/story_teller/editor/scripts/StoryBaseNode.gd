tool
extends GraphNode

export (int) var NodeType = 0
export (bool) var OnePerPort = false

class_name StoryBaseNode

# ---------------------------------------------------------------------------------------

var graphEdit: GraphEdit

func remove():
	unlink()
	name += " (deleted)"
	queue_free()

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

func get_connections():
	if not graphEdit: return []

	var connection_list = []
	for conn in graphEdit.get_connection_list():
		if ((conn.from == name) or (conn.to == name)):
			connection_list.append(conn)
	
	return connection_list
			
func update_from_port(old_port: int, new_port: int):
	if not graphEdit \
	or old_port == new_port: return

	for conn in graphEdit.get_connection_list():
		if (conn.from == name) \
		and (conn.from_port == old_port):
			graphEdit.disconnect_node(conn.from, old_port, conn.to, conn.to_port)
			graphEdit.connect_node(conn.from, new_port, conn.to, conn.to_port)

func update_to_port(old_port: int, new_port: int):
	if not graphEdit: return

	for conn in graphEdit.get_connection_list():
		if (conn.to == name) \
		and (conn.to_port == old_port):
			graphEdit.disconnect_node(conn.from, conn.from_port, conn.to, old_port)
			graphEdit.connect_node(conn.from, conn.from_port, conn.to, new_port)

func fix_offset():
	if not graphEdit: return
		
	if graphEdit.use_snap:
		offset = (offset/graphEdit.snap_distance).round() * graphEdit.snap_distance
