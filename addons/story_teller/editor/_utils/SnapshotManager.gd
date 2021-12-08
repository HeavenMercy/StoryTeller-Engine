# a manager to handle snapshot for personal UndoReod like operations
# it is then possible to save states and navigate inside saves
class_name SnapshotManager

var _snapshots = []
var _current_snap_index = -1
var _saved_snap_index = -1

func _init(data, message := "initial snapshot"):
    take_snapshot(data, message)
    _saved_snap_index = _current_snap_index

func _default_snap(): return {data=null, message=""}


# undo the changes by moving the index on the previous snapshot
func undo():
    if _current_snap_index > 0:
        print('[Snapshot Manager] Undo: ' + _snapshots[_current_snap_index].message)
        _current_snap_index -= 1
        return true


# redo the changes by moving the index on the next snapshot
func redo():
    if _current_snap_index < (len(_snapshots)-1):
        _current_snap_index += 1
        print('[Snapshot Manager] Redo: ' + _snapshots[_current_snap_index].message)
        return true


# save data as a new snapshot {data: "the data saved", message: "the message of the snapshot"}
# all snapshots below the current one will be deleted
func take_snapshot(data, message: String = ""):
    if (_current_snap_index == -1) or not is_current_saved():
        print('[Snapshot Manager] Snapshot: ' + message)
        _snapshots = _snapshots.slice(0, _current_snap_index)
        _snapshots.append({
            data = data,
            message = message
        })
        _current_snap_index += 1
    else: _snapshots[_current_snap_index] = {data=data, message=message}


# get the snapshotat the specified index (or the current one, if [code]index == -1[/code])
func get_snapshot(index := -1):
    if index == -1:
        if _current_snap_index == -1: return _default_snap()
        index = _current_snap_index

    if (index < 0) or (index >= len(_snapshots)): return
    return _snapshots[index]

# return the current snapshot
func get_current_snapshot():
    if (_current_snap_index < 0) or (_current_snap_index >= len(_snapshots)):
        return _default_snap()
    return _snapshots[_current_snap_index]

# return the saved snapshot
func get_saved_snapshot():
    if (_saved_snap_index < 0) or (_saved_snap_index >= len(_snapshots)):
        return _default_snap()
    return _snapshots[_saved_snap_index]

# return the array of snapshots
func get_snapshots(): return _snapshots


# check if there is no snapshot
func is_empty(): return (len(_snapshots) == 0)

# clear all snapshots
func clear():
    _snapshots.clear()
    _current_snap_index = -1
    _saved_snap_index = -1


# check if the current snapshot is saved (aka the saved snapshot is the current one)
func is_current_saved():
    return (_current_snap_index == _saved_snap_index)

# set current snapshot as saved (aka the saved snapshot becomes the current one)
func set_current_saved():
    _saved_snap_index = _current_snap_index


