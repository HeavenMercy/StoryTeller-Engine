tool
extends EditorPlugin

const DIALOGAREA = "ST_DialogArea"
const COMMANDAREA = "ST_CommandArea"
const STORYTELLER = "st"
const EDITORDATABASE = "stedb"

var mainEditor

# ------------------------------------------------------------------------------------------------

func _enter_tree():
	add_autoload_singleton(STORYTELLER, "res://addons/story_teller/st_core.gd")
	add_autoload_singleton(EDITORDATABASE, "res://addons/story_teller/editor/scripts/steditor_db.gd")

	# add_custom_type(DIALOGAREA, "RichTextLabel", preload("custom_types/DialogArea.gd"), null)
	# add_custom_type(COMMANDAREA, "LineEdit", preload("custom_types/CommandArea.gd"), null)

	mainEditor = preload("res://addons/story_teller/editor/MainEditor.tscn").instance(PackedScene.GEN_EDIT_STATE_MAIN)
	get_editor_interface().get_editor_viewport().add_child(mainEditor)
	make_visible(false)

func _exit_tree():
	remove_autoload_singleton(EDITORDATABASE)
	remove_autoload_singleton(STORYTELLER)

	remove_custom_type(DIALOGAREA)
	remove_custom_type(COMMANDAREA)

	if mainEditor != null: mainEditor.queue_free()


func has_main_screen():
	return true

func make_visible(visible):
	if mainEditor != null: mainEditor.visible = visible

func save_external_data():
	mainEditor.save_all()

func get_plugin_name(): return "StoryTeller"

func get_plugin_icon():
	return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")
