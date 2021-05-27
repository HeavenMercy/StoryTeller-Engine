tool
extends WindowDialog


export (NodePath) var MessageLbl
export (NodePath) var OkBtn
export (NodePath) var CancelBtn
export (NodePath) var DiscardBtn

signal choice_made(choice)

var messageLbl: Label
var okBtn: Button
var cancelBtn: Button
var discardBtn: Button

func _ready():
	messageLbl = (get_node(MessageLbl) as Label)
	okBtn = (get_node(OkBtn) as Button)
	cancelBtn = (get_node(CancelBtn) as Button)
	discardBtn = (get_node(DiscardBtn) as Button)

	okBtn.connect("pressed", self, "_on_choice_made", [1])
	cancelBtn.connect("pressed", self, "_on_choice_made", [2])
	discardBtn.connect("pressed", self, "_on_choice_made", [3])

func _on_choice_made(choice: int):
	emit_signal("choice_made", choice)
	visible = false


func set_buttons(okTxt: String = "", cancelTxt: String = "", discardTxt: String = ""):
	okBtn.visible = not okTxt.empty()
	cancelBtn.visible = not cancelTxt.empty()
	discardBtn.visible = not discardTxt.empty()

	if okBtn.visible: okBtn.text = okTxt
	if cancelBtn.visible: cancelBtn.text = cancelTxt
	if discardBtn.visible: discardBtn.text = discardTxt


func open(title: String, msg: String, target: Object = null, on_choice_made: String = "", binds: Array = []):
	window_title = title
	messageLbl.text = msg

	if (target != null) and not on_choice_made.empty():
		if not is_connected("choice_made", target, on_choice_made):
			connect("choice_made", target, on_choice_made, binds, CONNECT_ONESHOT)

	call_deferred("popup_centered")
