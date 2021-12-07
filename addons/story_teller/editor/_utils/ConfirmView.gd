tool
extends HBoxContainer

class_name _ConfirmView


const YES_BUTTON = 1
const NO_BUTTON = 2

export (NodePath) var MessageLbl
export (NodePath) var YesBtn
export (NodePath) var NoBtn

signal choice_made(choice)
signal yes_chosen()
signal no_chosen()


var yesBtn: Button
var noBtn: Button

func _ready():
	yesBtn = (get_node(YesBtn) as Button)
	noBtn = (get_node(NoBtn) as Button)

	yesBtn.connect('pressed', self, '_on_choice_made', [YES_BUTTON])
	noBtn.connect('pressed', self, '_on_choice_made', [NO_BUTTON])
	visible = false


func set_buttons(yesTxt: String = '', noTxt: String = ''):
	yesBtn.visible = not yesTxt.empty()
	noBtn.visible = not noTxt.empty()

	if yesBtn.visible: yesBtn.text = yesTxt
	if noBtn.visible: noBtn.text = noTxt


func _on_choice_made(choice: int):
	emit_signal('choice_made', choice)
	if choice == YES_BUTTON: emit_signal('yes_chosen')
	elif choice == NO_BUTTON: emit_signal('no_chosen')
	visible = false


func display(message: String):
	(get_node(MessageLbl) as Label).text = message
	visible = true
