@tool
extends EditorPlugin

var button
var last_selected_option = 0

const OPTIONS = [
	"Debug Server",
	"Debug Client",
	"Debug Server (2 clients)"
]

func launch(id):
	if id == 0:
		EditorInterface.play_main_scene()
		OS.execute(OS.get_executable_path(), ["--position", "800,100", "--client"], [])
	elif id == 1:
		OS.execute(OS.get_executable_path(), ["--position", "800,100"], [])
		OS.set_environment("USE_CLIENT", "true")
		EditorInterface.play_main_scene()
		OS.set_environment("USE_CLIENT", "false")
	elif id == 2:
		EditorInterface.play_main_scene()
		OS.execute(OS.get_executable_path(), ["--position", "600,100", "--client"], [])
		OS.execute(OS.get_executable_path(), ["--position", "800,300", "--client"], [])
	last_selected_option = id
	update_text()

func find_editor_run_button(node: Node):
	for n in node.get_children():
		if n.get_class() == 'EditorRunNative':
			return n
		else:
			var result = find_editor_run_button(n)
			if result != null:
				return result
	return null

func _input(event):
	if event is InputEventKey and event.shift and event.control and event.keycode == KEY_D and event.pressed:
		launch(last_selected_option)

func _enter_tree():
	if not Engine.is_editor_hint():
		return
	
	var base = EditorInterface.get_base_control()
	var container = find_editor_run_button(base).get_parent().get_parent()
	
	button = MenuButton.new()
	update_text()
	container.add_child(button)
	for option in OPTIONS:
		button.get_popup().add_item(option)
	
	button.get_popup().id_pressed.connect(launch)
	button.icon = base.get_icon("MainPlay")
	
	add_custom_type("Sync", "Node", preload("res://addons/multiplayer/Sync.gd"), base.get_icon("Reload"))
	add_custom_type("NetworkGame", "Node", preload("res://addons/multiplayer/NetworkGame.gd"), base.get_icon("MainPlay"))

func update_text():
	if button:
		button.text = OPTIONS[last_selected_option] + " (Ctrl+Shift+D)"

func _exit_tree():
	_disable_plugin()

func _disable_plugin():
	if button:
		button.queue_free()
