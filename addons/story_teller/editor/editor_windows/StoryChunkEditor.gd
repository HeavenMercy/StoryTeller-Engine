tool
extends WindowDialog


export (NodePath) var IdField
export (NodePath) var ContentField
export (NodePath) var InsertBtn
export (NodePath) var DelaySpin

export (NodePath) var AddPageBtn
export (NodePath) var DelPageBtn
export (NodePath) var ConfirmDelPage
export (NodePath) var UpdateContainer
export (NodePath) var UpdateAddBtn
export (NodePath) var ConditionContainer
export (NodePath) var OrAndToggle
export (NodePath) var ConditionAddBtn

export (NodePath) var ContentLabel
export (NodePath) var SaveBtn

export (PackedScene) var TestUpdateBase
export (Array, NodePath) var ToHideOnCondition: Array

signal data_save_request(data)

# ---------------------------------------------------------------------------

func open(data: Dictionary, for_condition: bool = false):
	idField.text = str(data.get('id', ''))
	contentField.text = str(data.get('content', ''))
	delaySpin.value = float(data.get('delay', 0))

	orAndToggle.pressed = bool(data.get('inverse_condition', false))
	inverse_condition(orAndToggle.pressed)

	if data.has('conditions') and data.conditions is Array:
		for condPage in data.conditions:
			if (condPage is Array) and (len(condPage) > 0):
				add_page(condPage)

	if conditionContainer.get_child_count() == 0:
		add_page()

	if data.has('updates') and data.updates is Array:
		for upd in data.updates:
			if upd is Dictionary: add_update(upd)

	is_open = true
	conditionContainer.current_tab = 0

	# configure for condition or not
	condition_only = for_condition
	for path in ToHideOnCondition:
		get_node(path).visible = not condition_only

	rect_size.x = 450 if condition_only else 800
	get_node(ContentLabel).text = 'Description' if condition_only else 'Content'

func close():
	is_open = false
	visible = false

	# removes all tabs
	for page in conditionContainer.get_children():
		page.queue_free()

	for update in updateContainer.get_children():
		update.queue_free()

func add_page(cond: Array = []):
	var count = conditionContainer.get_child_count()
	conditionContainer.add_child(BaseConditionContainer.duplicate())

	conditionContainer.set_tab_title(count, 'Page ' + str(count+1))
	conditionContainer.current_tab = count

	for c in cond:
		if c is Dictionary: add_condition(c)

func ask_delete_page():
	if conditionContainer.get_child_count() == 0: return
	confirmDelPage.display("delete '" + conditionContainer.get_tab_title(conditionContainer.current_tab) + "'?")

func delete_page():
	if conditionContainer.get_child_count() == 0: return
	var tab = conditionContainer.get_current_tab_control()
	conditionContainer.remove_child(tab)
	tab.queue_free()

	if conditionContainer.get_child_count() == 0: add_page()

func add_condition(cond: Dictionary = {}):
	var cc
	for node in conditionContainer.get_current_tab_control().get_children():
		if node is Container:
			cc = node
			break

	if cc == null: return

	var condition = TestUpdateBase.instance()
	cc.add_child(condition)

	condition.set_fortest(true)
	condition.set_prefix( _get_prefix(cc.get_child_count()) )

	if (cond != null) and not cond.empty():
		condition.update_data(cond)

	if mainEditor != null:
		condition.connect('data_edit_request', mainEditor, 'edit_condUpd')
	condition.connect('data_deleted', self, 'on_data_deleted')

func add_update(upd: Dictionary = {}):
	var update = TestUpdateBase.instance()
	updateContainer.add_child(update)

	update.set_fortest(false)
	update.update_lines(len(contentField.text.split('\n')))

	if (upd != null) and not upd.empty():
		update.update_data(upd)

	if mainEditor != null:
		update.connect('data_edit_request', mainEditor, 'edit_condUpd')

func on_data_deleted(index: int):
	var cc = conditionContainer.get_current_tab_control().get_child(0)
	if (index == 0) and (cc.get_child_count() > 1):
		cc.get_child(1).set_prefix( _get_prefix(0) )

func inverse_condition(active: bool):
	if active: orAndToggle.hint_tooltip = 'all pages have to pass the test!'
	else: orAndToggle.hint_tooltip = 'at least one page has to pass the test!'

	for tab in conditionContainer.get_children():
		var tmp = []
		for condition in tab.get_child(0).get_children():
			condition.set_prefix( _get_prefix(condition.get_index()) )

func on_save_request():
	if idField.text.empty() or contentField.text.empty(): return

	var data = {}

	data.id = idField.text
	data.content = contentField.text
	data.delay = delaySpin.value
	data.inverse_condition = orAndToggle.pressed
	data.condition_only = condition_only # to_remove

	data.conditions = []
	var tmp
	for tab in conditionContainer.get_children():
		tmp = []
		for condition in tab.get_child(0).get_children():
			if condition is TestUpdateItem:
				tmp.append( condition._data.duplicate(true) )
		data.conditions.append(tmp)

	data.updates = []
	for update in (updateContainer as Node).get_children():
		if update is TestUpdateItem:
			data.updates.append( update._data.duplicate(true) )

	emit_signal('data_save_request', data)
	close()

func on_data_selected(data):
	contentField.insert_text_at_cursor(
		st.StoryInterpreter.data_to_template(data) )
	contentField.grab_focus()

func insert_template():
	ste.set_selection_mode_types(false, true, true)
	dataEditor.for_template = true
	dataEditor.open(true)

# ---------------------------------------------------------------------------

var is_open = false
var condition_only = false

var idField: LineEdit
var contentField: TextEdit
var delaySpin: SpinBox
var orAndToggle: CheckButton

var mainEditor
var dataEditor

var confirmDelPage: _ConfirmView
var conditionContainer: TabContainer
var updateContainer: VBoxContainer

var BaseConditionContainer

func _ready():
	idField = (get_node(IdField) as LineEdit)
	contentField = (get_node(ContentField) as TextEdit)
	delaySpin = (get_node(DelaySpin) as SpinBox)
	orAndToggle = (get_node(OrAndToggle) as CheckButton)

	confirmDelPage = (get_node(ConfirmDelPage) as _ConfirmView)
	conditionContainer = (get_node(ConditionContainer) as TabContainer)
	updateContainer = (get_node(UpdateContainer) as VBoxContainer)

	BaseConditionContainer = updateContainer.get_parent().duplicate()

	confirmDelPage.connect('yes_chosen', self, 'delete_page')
	contentField.connect('text_changed', self, '_on_content_changed')
	orAndToggle.connect('toggled', self, 'inverse_condition')
	(get_node(AddPageBtn) as Button).connect('pressed', self, 'add_page')
	(get_node(DelPageBtn) as Button).connect('pressed', self, 'ask_delete_page')
	(get_node(ConditionAddBtn) as Button).connect('pressed', self, 'add_condition')
	(get_node(UpdateAddBtn) as Button).connect('pressed', self, 'add_update')
	(get_node(SaveBtn) as Button).connect('pressed', self, 'on_save_request')
	(get_node(InsertBtn) as Button).connect('pressed', self, 'insert_template')

	idField.connect('text_changed', self, '_update_id')
	get_close_button().connect('pressed', self, 'close')
	close()

func _physics_process(delta):
	if is_open and not visible:
		call_deferred('popup')

func _update_id(name):
	name = ste.str_to_key(name)

	var last_caret_pos = idField.caret_position
	idField.text = str(name)
	idField.caret_position = last_caret_pos

func _get_prefix(index: int):
	var inverse = orAndToggle.pressed

	var prefix = ''
	if index <= 1: prefix = 'if'
	else: prefix = ('or' if inverse else 'and')

	if inverse: prefix += ' not'
	return prefix

func _on_content_changed():
	for update in updateContainer.get_children():
		if update.has_method('update_lines'):
			update.update_lines(len(contentField.text.split('\n')))
